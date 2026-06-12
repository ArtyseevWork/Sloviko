import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/di/providers.dart';
import '../../../core/locale/app_locale.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/go.dart';
import '../../../core/settings/cefr_levels.dart';
import '../../../core/theme/theme_provider.dart';
import '../widgets/logo_mark.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Seed words on first launch + apply forgetting-curve decay.
    final repo = ref.read(wordsRepositoryProvider);
    await repo.bootstrap();
    await ref.read(applyDecayProvider).call();
    // Refresh the remote batch manifest so installed builds learn about new
    // batches added to the repo. Then fire-and-forget the remote top-up.
    final levels = ref.read(cefrLevelsProvider).levels;
    unawaited(
      repo.refreshManifest().then(
            (_) => ref.read(loadNextBatchProvider).call(levels),
          ),
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Go.to(context, Routes.quiz);
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          // Decorative blobs (per design spec)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18 - 165.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 330.w,
                height: 330.w,
                decoration: BoxDecoration(
                  color: c.accentBg,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.74,
            left: MediaQuery.of(context).size.width * 0.62 - 65.w,
            child: Opacity(
              opacity: 0.55,
              child: Container(
                width: 130.w,
                height: 130.w,
                decoration: BoxDecoration(
                  color: c.accentBg,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LogoMark(background: c.accent),
                SizedBox(height: 28.h),
                Text(
                  'Sloviko',
                  style: TextStyle(
                    fontSize: 44.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: c.text,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  AppLocale.text('splash_tagline'),
                  style: TextStyle(fontSize: 15.sp, color: c.textSub),
                ),
              ],
            ),
          ),
          // by Mordansoft
          Positioned(
            left: 0,
            right: 0,
            bottom: 24.h,
            child: Center(
              child: Text(
                AppLocale.text('splash_by_mordansoft'),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: c.textSub.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Tiny stub so we don't pull dart:async just for unawaited.
void unawaited(Future<void> _) {}
