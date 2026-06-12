import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight wrapper around AudioPlayer. Single shared instance — new
/// plays cancel the previous one. URLs are streamed from network; fails
/// silently when offline (audio is auxiliary, not critical to the lesson).
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  /// On-demand playback — user is waiting, so cap at 3s.
  static const _playTimeout = Duration(seconds: 3);

  /// Background prefetch — no user blocking, give the network 5s to fill the
  /// buffer before giving up.
  static const _prepareTimeout = Duration(seconds: 5);

  int _playToken = 0;

  /// Tracks an in-flight playUrl from the moment it's invoked until the
  /// underlying playback finishes (completed event) or is cancelled.
  /// prepare() honours this flag to avoid swapping the player's source
  /// while a previous word's audio is still loading or playing.
  bool _playInFlight = false;
  late final StreamSubscription<PlayerState> _stateSub;

  AudioService() {
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (s == PlayerState.completed || s == PlayerState.stopped) {
        _playInFlight = false;
      }
    });
  }

  Future<void> playUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final myToken = ++_playToken;
    _playInFlight = true;
    try {
      await _player.stop();
      await _player.play(UrlSource(url)).timeout(_playTimeout);
      if (myToken != _playToken) {
        await _player.stop().catchError((_) {});
      }
    } catch (_) {
      _playInFlight = false;
      await _player.stop().catchError((_) {});
    }
  }

  /// Pre-fetch the URL into the player's buffer without playing. Skipped if
  /// the previous word's audio is still loading or playing — overwriting the
  /// source there would cause the late-resolving play() to play THIS URL.
  Future<void> prepare(String? url) async {
    if (url == null || url.isEmpty) return;
    if (_playInFlight) return;
    try {
      await _player.setSource(UrlSource(url)).timeout(_prepareTimeout);
    } catch (_) {
      // Silent — playUrl will retry the fetch if needed.
    }
  }

  Future<void> stop() async {
    _playToken++;
    _playInFlight = false;
    await _player.stop().catchError((_) {});
  }

  Future<void> dispose() async {
    await _stateSub.cancel();
    await _player.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final svc = AudioService();
  ref.onDispose(svc.dispose);
  return svc;
});
