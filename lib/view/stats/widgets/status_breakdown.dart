import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/locale/app_locale.dart';
import '../../../core/theme/theme_provider.dart';

class StatusBreakdown extends ConsumerWidget {
  final int newWords;
  final int inProgress;
  final int learned;

  const StatusBreakdown({
    required this.newWords,
    required this.inProgress,
    required this.learned,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final total = newWords + inProgress + learned;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocale.text('stats_breakdown'),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: c.textSub,
            ),
          ),
          SizedBox(height: 12.h),
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: SizedBox(
                height: 8.h,
                child: Row(
                  children: [
                    Expanded(flex: newWords, child: Container(color: c.textSub.withValues(alpha: 0.4))),
                    Expanded(flex: inProgress, child: Container(color: c.accent)),
                    Expanded(flex: learned, child: Container(color: c.success)),
                  ],
                ),
              ),
            ),
          SizedBox(height: 14.h),
          _row(c.textSub.withValues(alpha: 0.4), AppLocale.text('stats_new'), newWords, c),
          SizedBox(height: 8.h),
          _row(c.accent, AppLocale.text('stats_in_progress'), inProgress, c),
          SizedBox(height: 8.h),
          _row(c.success, AppLocale.text('stats_learned'), learned, c),
        ],
      ),
    );
  }

  Widget _row(Color dot, String label, int value, dynamic c) => Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 14.sp, color: c.text)),
          ),
          Text('$value',
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: c.text)),
        ],
      );
}
