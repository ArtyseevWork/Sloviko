import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';

class LexioApp extends ConsumerWidget {
  const LexioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 15 baseline (per design)
      minTextAdapt: true,
      builder: (context, _) {
        final themeNotifier = ref.watch(dettoThemeProvider);
        return MaterialApp.router(
          title: 'Sloviko',
          debugShowCheckedModeBanner: false,
          theme: themeNotifier.lightTheme,
          darkTheme: themeNotifier.darkTheme,
          themeMode: themeNotifier.themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
