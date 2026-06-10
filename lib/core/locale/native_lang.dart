import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_state_dao.dart';
import '../di/providers.dart';

/// User's native language for word translations.
/// Independent of UI locale (AppLocale) — that's translations OF the app;
/// this is what language the user is *learning from*.
class NativeLangNotifier extends ChangeNotifier {
  static const supported = ['uk', 'ru'];
  static const _key = 'native_lang';

  final AppStateDao _state;
  String _code = 'uk';
  bool _loaded = false;

  NativeLangNotifier(this._state) {
    _load();
  }

  String get code => _code;
  bool get loaded => _loaded;

  Future<void> _load() async {
    final saved = await _state.get(_key);
    if (saved != null && supported.contains(saved)) {
      _code = saved;
    } else {
      _code = _detectFromSystem();
    }
    _loaded = true;
    notifyListeners();
  }

  String _detectFromSystem() {
    final tag = PlatformDispatcher.instance.locale.languageCode;
    if (supported.contains(tag)) return tag;
    return 'uk';
  }

  Future<void> set(String code) async {
    if (!supported.contains(code) || code == _code) return;
    _code = code;
    await _state.set(_key, code);
    notifyListeners();
  }
}

final nativeLangProvider = ChangeNotifierProvider<NativeLangNotifier>(
  (ref) => NativeLangNotifier(ref.watch(appStateDaoProvider)),
);
