import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/icons/detto_icon.dart';
import '../../../core/locale/app_locale.dart';
import '../../../core/locale/native_lang.dart';
import '../../../core/router/go.dart';
import '../../../core/theme/theme_provider.dart';
import '../provider/stats_notifier.dart';
import '../widgets/activity_chart.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_breakdown.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final notifier = ref.watch(statsNotifierProvider);
    final s = notifier.snapshot;
    final theme = ref.watch(dettoThemeProvider);
    final nativeLang = ref.watch(nativeLangProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back + title + theme toggle
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 6.h, 12.w, 6.h),
              child: Row(
                children: [
                  _IconBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Go.back(context),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      AppLocale.text('stats_title'),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ),
                  // Native language toggle
                  _LangToggle(nativeLang: nativeLang),
                  SizedBox(width: 8.w),
                  _IconBtn(
                    icon: Theme.of(context).brightness == Brightness.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    onTap: () => theme.toggle(Theme.of(context).brightness),
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifier.loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 24.h),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: AppLocale.text('stats_learned').toUpperCase(),
                                value: '${s.learned} / ${s.total}',
                                subtitle: '${(s.learnedRatio * 100).round()}%',
                                valueColor: c.accent,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: StatCard(
                                title: AppLocale.text('stats_streak').toUpperCase(),
                                value: '${s.streakDays}',
                                subtitle: AppLocale.text('stats_days'),
                                valueColor: s.streakDays > 0 ? c.success : c.text,
                              ),
                            ),
                          ],
                        ),
                        if (s.accuracy != null) ...[
                          SizedBox(height: 10.h),
                          StatCard(
                            title: AppLocale.text('stats_accuracy').toUpperCase(),
                            value: '${(s.accuracy! * 100).round()}%',
                          ),
                        ],
                        SizedBox(height: 10.h),
                        ActivityChart(data: s.last30Days),
                        SizedBox(height: 10.h),
                        StatusBreakdown(
                          newWords: s.newWords,
                          inProgress: s.inProgress,
                          learned: s.learned,
                        ),
                      ],
                    ),
            ),
          ],
        ),
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
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: c.border),
        ),
        child: Center(child: DettoIcon(icon, size: 18.sp, color: c.textSub)),
      ),
    );
  }
}

class _LangToggle extends ConsumerWidget {
  final NativeLangNotifier nativeLang;
  const _LangToggle({required this.nativeLang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    return GestureDetector(
      onTap: () {
        final next = nativeLang.code == 'uk' ? 'ru' : 'uk';
        nativeLang.set(next);
      },
      child: Container(
        height: 36.w,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: c.border),
        ),
        child: Center(
          child: Text(
            nativeLang.code.toUpperCase(),
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: c.textSub,
            ),
          ),
        ),
      ),
    );
  }
}
