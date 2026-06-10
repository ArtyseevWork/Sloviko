import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/locale/app_locale.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/local/answer_log_dao.dart';

class ActivityChart extends ConsumerWidget {
  final List<DailyTotals> data;
  const ActivityChart({required this.data, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final maxV = data.fold<int>(0, (m, d) => d.total > m ? d.total : m);

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
            AppLocale.text('stats_activity_30d'),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: c.textSub,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 84.h,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarsPainter(
                data: data,
                max: maxV == 0 ? 1 : maxV,
                accent: c.accent,
                track: c.track,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30 ${AppLocale.text("stats_days_ago")}',
                  style: TextStyle(fontSize: 11.sp, color: c.textSub)),
              Text(AppLocale.text('stats_today'),
                  style: TextStyle(fontSize: 11.sp, color: c.textSub)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<DailyTotals> data;
  final int max;
  final Color accent;
  final Color track;

  _BarsPainter({
    required this.data,
    required this.max,
    required this.accent,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final gap = 2.0;
    final n = data.length;
    final barW = (size.width - gap * (n - 1)) / n;
    final accentPaint = Paint()..color = accent;
    final trackPaint = Paint()..color = track;

    for (var i = 0; i < n; i++) {
      final x = i * (barW + gap);
      final rectTrack = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barW, size.height),
        const Radius.circular(2),
      );
      canvas.drawRRect(rectTrack, trackPaint);

      final total = data[i].total;
      if (total == 0) continue;
      final h = size.height * (total / max);
      final rectBar = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barW, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rectBar, accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.data != data || old.max != max || old.accent != accent;
}
