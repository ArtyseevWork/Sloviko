import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/theme_provider.dart';
import '../provider/quiz_notifier.dart';

class AnswerButton extends ConsumerWidget {
  final String label;
  final AnswerButtonState state;
  final VoidCallback onTap;

  const AnswerButton({
    required this.label,
    required this.state,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);

    Color bg = c.surface;
    Color borderColor = c.border;
    double borderWidth = 1;
    Color textColor = c.text;
    Widget? trailing;

    switch (state) {
      case AnswerButtonState.idle:
        break;
      case AnswerButtonState.correct:
      case AnswerButtonState.correctReveal:
        bg = c.successBg;
        borderColor = c.success;
        borderWidth = 2;
        textColor = c.success;
        trailing = _StateIcon(color: c.success, icon: Icons.check_rounded);
        break;
      case AnswerButtonState.wrong:
        bg = c.errorBg;
        borderColor = c.error;
        borderWidth = 2;
        textColor = c.error;
        trailing = _StateIcon(color: c.error, icon: Icons.close_rounded);
        break;
    }

    return AnimatedScale(
      scale: state == AnswerButtonState.correct ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: state == AnswerButtonState.idle
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _StateIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _StateIcon({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14.sp, color: color),
    );
  }
}
