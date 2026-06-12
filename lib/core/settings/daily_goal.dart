import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_state_dao.dart';
import '../di/providers.dart';

/// User-defined daily points target. 1 correct answer = 1 point.
class DailyGoalNotifier extends ChangeNotifier {
  static const _key = 'daily_goal';
  static const defaultGoal = 100;
  static const step = 10;
  static const min = 10;
  static const max = 500;

  final AppStateDao _state;
  int _goal = defaultGoal;
  bool _loaded = false;

  DailyGoalNotifier(this._state) {
    _load();
  }

  int get goal => _goal;
  bool get loaded => _loaded;

  Future<void> _load() async {
    final saved = await _state.get(_key);
    final parsed = saved == null ? null : int.tryParse(saved);
    if (parsed != null && parsed >= min && parsed <= max) {
      _goal = parsed;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> set(int next) async {
    final clamped = next.clamp(min, max);
    if (clamped == _goal) return;
    _goal = clamped;
    await _state.set(_key, _goal.toString());
    notifyListeners();
  }

  Future<void> increment() => set(_goal + step);
  Future<void> decrement() => set(_goal - step);
}

final dailyGoalProvider = ChangeNotifierProvider<DailyGoalNotifier>(
  (ref) => DailyGoalNotifier(ref.watch(appStateDaoProvider)),
);
