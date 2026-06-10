import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/locale/app_locale.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../domain/models/question.dart';

class WordArea extends ConsumerWidget {
  final Question question;
  final int? scoreFloat;
  final bool celebrating;
  final String nativeLang;

  const WordArea({
    required this.question,
    required this.scoreFloat,
    required this.celebrating,
    required this.nativeLang,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final isEn = question.direction == QuestionDirection.enToRu;
    final prompt = isEn ? question.target.en : question.target.tr(nativeLang);
    final langLabelKey = isEn ? 'quiz_lang_en' : 'quiz_lang_native_$nativeLang';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (celebrating) ...[
            _LearnedBadge(),
            SizedBox(height: 16.h),
          ],
          if (scoreFloat != null)
            _ScoreFloat(value: scoreFloat!, isPositive: scoreFloat! > 0),
          Text(
            prompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 46.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -2.5,
              color: c.text,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            AppLocale.text(langLabelKey),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: c.textSub,
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            AppLocale.text('quiz_hint'),
            style: TextStyle(fontSize: 14.sp, color: c.textSub),
          ),
        ],
      ),
    );
  }
}

class _ScoreFloat extends ConsumerStatefulWidget {
  final int value;
  final bool isPositive;
  const _ScoreFloat({required this.value, required this.isPositive});

  @override
  ConsumerState<_ScoreFloat> createState() => _ScoreFloatState();
}

class _ScoreFloatState extends ConsumerState<_ScoreFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    duration: const Duration(milliseconds: 1400),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final color = widget.isPositive ? c.success : c.error;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Opacity(
          opacity: 1 - _ctrl.value,
          child: Transform.translate(
            offset: Offset(0, -40 * _ctrl.value),
            child: Text(
              widget.value > 0 ? '+${widget.value}' : '${widget.value}',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        );
      },
    );
  }
}

class _LearnedBadge extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LearnedBadge> createState() => _LearnedBadgeState();
}

class _LearnedBadgeState extends ConsumerState<_LearnedBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    duration: const Duration(milliseconds: 450),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final scale = Tween<double>(begin: 0.6, end: 1.0)
        .chain(CurveTween(curve: const Cubic(0.34, 1.56, 0.64, 1)))
        .animate(_ctrl);
    return ScaleTransition(
      scale: scale,
      child: FadeTransition(
        opacity: _ctrl,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: c.accentBg,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: c.accent, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: c.accentTxt, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                AppLocale.text('quiz_word_learned'),
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
    );
  }
}
