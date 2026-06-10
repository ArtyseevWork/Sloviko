import 'package:flutter/material.dart';

/// Design tokens for LEXIO. OKLCH values from design spec converted to HEX.
/// Source: README.md "Color Palette (OKLCH)"
class DettoColors {
  final Color bg;
  final Color surface;
  final Color surfacePrs;
  final Color text;
  final Color textSub;
  final Color border;
  final Color accent;
  final Color accentBg;
  final Color accentTxt;
  final Color success;
  final Color successBg;
  final Color error;
  final Color errorBg;
  final Color track;

  const DettoColors({
    required this.bg,
    required this.surface,
    required this.surfacePrs,
    required this.text,
    required this.textSub,
    required this.border,
    required this.accent,
    required this.accentBg,
    required this.accentTxt,
    required this.success,
    required this.successBg,
    required this.error,
    required this.errorBg,
    required this.track,
  });

  // Light palette (OKLCH → HEX approximation, hue 243 = blue accent)
  static const light = DettoColors(
    bg:         Color(0xFFF4F6F9),
    surface:    Color(0xFFFFFFFF),
    surfacePrs: Color(0xFFE5E9EF),
    text:       Color(0xFF1B1F26),
    textSub:    Color(0xFF717784),
    border:     Color(0xFFDBDFE5),
    accent:     Color(0xFF2F7DE0),
    accentBg:   Color(0xFFD8E6FB),
    accentTxt:  Color(0xFF1A4FA5),
    success:    Color(0xFF1A8742),
    successBg:  Color(0xFFCDEED9),
    error:      Color(0xFFD63D2E),
    errorBg:    Color(0xFFFBD9D2),
    track:      Color(0xFFDEE2E8),
  );

  static const dark = DettoColors(
    bg:         Color(0xFF0F1318),
    surface:    Color(0xFF1A1F26),
    surfacePrs: Color(0xFF272D36),
    text:       Color(0xFFE5E8ED),
    textSub:    Color(0xFF8E96A4),
    border:     Color(0xFF353C46),
    accent:     Color(0xFF5C9EEC),
    accentBg:   Color(0xFF1A2C4D),
    accentTxt:  Color(0xFF5C9EEC),
    success:    Color(0xFF5DBC7A),
    successBg:  Color(0xFF143324),
    error:      Color(0xFFDA5C50),
    errorBg:    Color(0xFF33150F),
    track:      Color(0xFF2A3038),
  );
}
