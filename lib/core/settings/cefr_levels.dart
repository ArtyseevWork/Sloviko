import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_state_dao.dart';
import '../di/providers.dart';

/// Active CEFR levels — user-selected filter for word rotation.
/// Default: A1, A2, B1, B2 (covers most learners).
class CefrLevelsNotifier extends ChangeNotifier {
  static const all = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const defaultActive = ['A1', 'A2', 'B1', 'B2'];
  static const _key = 'active_cefr_levels';

  final AppStateDao _state;
  List<String> _levels = defaultActive;
  bool _loaded = false;

  CefrLevelsNotifier(this._state) {
    _load();
  }

  List<String> get levels => List.unmodifiable(_levels);
  bool get loaded => _loaded;
  bool isActive(String level) => _levels.contains(level);

  Future<void> _load() async {
    final saved = await _state.get(_key);
    if (saved != null && saved.isNotEmpty) {
      _levels = saved
          .split(',')
          .where(all.contains)
          .toList();
      if (_levels.isEmpty) _levels = List.of(defaultActive);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String level) async {
    if (!all.contains(level)) return;
    final next = List<String>.of(_levels);
    if (next.contains(level)) {
      if (next.length == 1) return; // never empty
      next.remove(level);
    } else {
      next.add(level);
    }
    // keep canonical order
    next.sort((a, b) => all.indexOf(a).compareTo(all.indexOf(b)));
    _levels = next;
    await _state.set(_key, _levels.join(','));
    notifyListeners();
  }
}

final cefrLevelsProvider = ChangeNotifierProvider<CefrLevelsNotifier>(
  (ref) => CefrLevelsNotifier(ref.watch(appStateDaoProvider)),
);
