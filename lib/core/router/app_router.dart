import 'package:go_router/go_router.dart';

import '../../view/quiz/pages/quiz_page.dart';
import '../../view/settings/pages/settings_page.dart';
import '../../view/splash/pages/splash_page.dart';
import '../../view/stats/pages/stats_page.dart';

class Routes {
  static const splash = '/';
  static const quiz = '/quiz';
  static const stats = '/stats';
  static const settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
    GoRoute(path: Routes.quiz, builder: (_, _) => const QuizPage()),
    GoRoute(path: Routes.stats, builder: (_, _) => const StatsPage()),
    GoRoute(path: Routes.settings, builder: (_, _) => const SettingsPage()),
  ],
);
