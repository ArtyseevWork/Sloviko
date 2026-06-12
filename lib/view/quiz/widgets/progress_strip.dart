import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/icons/detto_icon.dart';
import '../../../core/locale/app_locale.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/go.dart';
import '../../../core/theme/theme_provider.dart';

class ProgressStrip extends ConsumerWidget {
  final int todayPoints;
  final int dailyGoal;

  const ProgressStrip({
    required this.todayPoints,
    required this.dailyGoal,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final ratio = dailyGoal == 0 ? 0.0 : (todayPoints / dailyGoal).clamp(0.0, 1.0);
    final reached = todayPoints >= dailyGoal;
    final barColor = reached ? c.success : c.accent;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      '$todayPoints / $dailyGoal',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: reached ? c.success : c.text,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      AppLocale.text('progress_today'),
                      style: TextStyle(fontSize: 11.sp, color: c.textSub),
                    ),
                    const Spacer(),
                    if (reached)
                      Text(
                        '🎯',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: Container(
                    height: 3.h,
                    color: c.track,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio,
                      child: Container(color: barColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          _IconBtn(
            icon: Icons.bar_chart_rounded,
            onTap: () => Go.push(context, Routes.stats),
          ),
          SizedBox(width: 8.w),
          _IconBtn(
            icon: Icons.settings_outlined,
            onTap: () => Go.push(context, Routes.settings),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends ConsumerWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: c.border),
        ),
        child: Center(
          child: DettoIcon(icon, size: 16.sp, color: c.textSub),
        ),
      ),
    );
  }
}
