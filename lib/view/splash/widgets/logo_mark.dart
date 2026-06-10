import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Sloviko logo mark — 80×80 rounded square with white "S" and a small dot
/// below it. Mirrors the app launcher icon (`assets/icon/app_icon.svg`):
///   - bg #1E4FCC + radial glow (handled via Container + DecorationImage-free)
///   - "S" fontWeight 800, near-white
///   - dot ~22% of viewBox under the letter
class LogoMark extends StatelessWidget {
  final Color background;
  final double size;

  const LogoMark({
    required this.background,
    this.size = 80,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final s = size.w;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.42, -0.46),
          radius: 0.9,
          colors: [
            const Color(0xFF78AAFF).withValues(alpha: 0.30),
            background,
          ],
        ),
        color: background,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: background.withValues(alpha: 0.32),
            blurRadius: 44,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: s * 0.14),
            child: Text(
              'S',
              style: TextStyle(
                fontSize: s * 0.72,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
                color: Colors.white.withValues(alpha: 0.96),
                height: 1.0,
              ),
            ),
          ),
          Positioned(
            bottom: s * 0.10,
            child: Container(
              width: s * 0.052,
              height: s * 0.052,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.38),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
