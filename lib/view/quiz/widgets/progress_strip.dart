import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/icons/detto_icon.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/go.dart';
import '../../../core/theme/theme_provider.dart';

class ProgressStrip extends ConsumerWidget {
  final int learned;
  final int total;

  const ProgressStrip({required this.learned, required this.total, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final ratio = total == 0 ? 0.0 : (learned / total).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();

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
                      '$learned / $total',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: c.textSub),
                    ),
                    const Spacer(),
                    Text(
                      '$pct%',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: c.accent),
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
                      child: Container(color: c.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: () => Go.push(context, Routes.stats),
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: c.border),
              ),
              child: Center(
                child: DettoIcon(
                  Icons.bar_chart_rounded,
                  size: 16.sp,
                  color: c.textSub,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
