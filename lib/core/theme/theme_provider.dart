import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'detto_colors.dart';

class DettoThemeNotifier extends ChangeNotifier {
  static const _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  /// Active palette (assumes single context — UI reads platformBrightness).
  DettoColors theme = DettoColors.light;

  DettoThemeNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'light') _themeMode = ThemeMode.light;
    if (saved == 'dark') _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey,
        mode == ThemeMode.dark ? 'dark' : (mode == ThemeMode.light ? 'light' : 'system'));
    notifyListeners();
  }

  Future<void> toggle(Brightness currentBrightness) async {
    final next = currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  /// Resolve palette by context brightness (call in widget builds).
  DettoColors palette(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? DettoColors.dark : DettoColors.light;
  }

  ThemeData get lightTheme => _build(DettoColors.light, Brightness.light);
  ThemeData get darkTheme => _build(DettoColors.dark, Brightness.dark);

  ThemeData _build(DettoColors c, Brightness b) {
    final base = b == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: c.accent,
        surface: c.surface,
        error: c.error,
        brightness: b,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: c.text,
        displayColor: c.text,
      ),
    );
  }
}

final dettoThemeProvider =
    ChangeNotifierProvider<DettoThemeNotifier>((ref) => DettoThemeNotifier());
