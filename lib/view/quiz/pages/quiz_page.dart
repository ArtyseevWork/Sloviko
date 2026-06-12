import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/icons/detto_icon.dart';
import '../../../core/locale/app_locale.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/go.dart';
import '../../../core/theme/theme_provider.dart';
import '../provider/quiz_notifier.dart';
import '../widgets/answer_button.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/progress_strip.dart';
import '../widgets/word_area.dart';

class QuizPage extends ConsumerWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final notifier = ref.watch(quizNotifierProvider);
    final s = notifier.state;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Progress strip is always present so user can reach
                // settings/stats even on exhausted / loading state.
                ProgressStrip(todayPoints: s.todayPoints, dailyGoal: s.dailyGoal),
                Expanded(child: _Body(notifier: notifier)),
              ],
            ),
            ConfettiOverlay(active: s.celebrating),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final QuizNotifier notifier;
  const _Body({required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final s = notifier.state;

    if (s.loading && s.question == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (s.exhausted) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocale.text('quiz_exhausted'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.sp, color: c.textSub),
              ),
              SizedBox(height: 24.h),
              GestureDetector(
                onTap: () => Go.push(context, Routes.settings),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: c.accentBg,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: c.accent, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DettoIcon(Icons.settings_outlined,
                          size: 16.sp, color: c.accentTxt),
                      SizedBox(width: 8.w),
                      Text(
                        AppLocale.text('quiz_open_settings'),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: c.accentTxt,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: WordArea(
            question: s.question!,
            scoreFloat: s.scoreFloat,
            celebrating: s.celebrating,
            nativeLang: s.nativeLang,
          ),
        ),
        _KnowItButton(
          disabled: s.answered,
          onTap: notifier.markCurrentAsKnown,
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 16.h),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                mainAxisExtent: 64.h,
              ),
              itemCount: s.question!.options.length,
              itemBuilder: (_, i) => AnswerButton(
                label: s.question!.options[i],
                state: s.buttonStates[i],
                onTap: () => _onTap(notifier, i),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onTap(QuizNotifier n, int i) {
    if (n.state.answered) return;
    final correct = i == n.state.question!.correctIndex;
    if (correct) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    n.selectOption(i);
  }
}

class _KnowItButton extends ConsumerWidget {
  final bool disabled;
  final VoidCallback onTap;
  const _KnowItButton({required this.disabled, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: GestureDetector(
          onTap: disabled
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
          child: Container(
            height: 40.h,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DettoIcon(Icons.check_circle_outline_rounded,
                    size: 16.sp, color: c.textSub),
                SizedBox(width: 8.w),
                Text(
                  AppLocale.text('quiz_know_it'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: c.textSub,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
