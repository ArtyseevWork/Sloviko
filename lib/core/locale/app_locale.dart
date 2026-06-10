import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

/// Minimal localization façade. Loads JSON dictionaries from assets/locales/.
/// Convention: only en_GB and uk_UA are filled by Dev; other locales blank
/// (filled later by Ия).
class AppLocale {
  static const _basePath = 'assets/locales';
  static const supported = ['en_GB', 'uk_UA'];

  static final Map<String, Map<String, String>> _data = {};
  static String _current = 'en_GB';

  static Future<void> init() async {
    for (final code in supported) {
      try {
        final raw = await rootBundle.loadString('$_basePath/$code.json');
        _data[code] = (jsonDecode(raw) as Map).cast<String, String>();
      } catch (_) {
        _data[code] = {};
      }
    }
    final platform = PlatformDispatcher.instance.locale.toLanguageTag();
    if (platform.startsWith('uk')) _current = 'uk_UA';
  }

  static void setLocale(String code) {
    if (supported.contains(code)) _current = code;
  }

  static String text(String key) {
    return _data[_current]?[key] ?? _data['en_GB']?[key] ?? key;
  }
}
