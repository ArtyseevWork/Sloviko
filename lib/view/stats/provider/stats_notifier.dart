import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/usecases/get_stats.dart';

class StatsNotifier extends ChangeNotifier {
  final GetStats _getStats;

  StatsSnapshot snapshot = StatsSnapshot.empty;
  bool loading = true;

  StatsNotifier(this._getStats) {
    load();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();
    snapshot = await _getStats.call();
    loading = false;
    notifyListeners();
  }
}

final statsNotifierProvider = ChangeNotifierProvider<StatsNotifier>(
  (ref) => StatsNotifier(ref.watch(getStatsProvider)),
);
