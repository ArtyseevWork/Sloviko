import '../../data/local/answer_log_dao.dart';
import '../../data/local/words_dao.dart';

class StatsSnapshot {
  final int total;
  final int learned;
  final int inProgress;
  final int newWords;
  final int streakDays;
  final double? accuracy;
  final List<DailyTotals> last30Days;

  const StatsSnapshot({
    required this.total,
    required this.learned,
    required this.inProgress,
    required this.newWords,
    required this.streakDays,
    required this.accuracy,
    required this.last30Days,
  });

  double get learnedRatio => total == 0 ? 0 : learned / total;

  static const empty = StatsSnapshot(
    total: 0,
    learned: 0,
    inProgress: 0,
    newWords: 0,
    streakDays: 0,
    accuracy: null,
    last30Days: [],
  );
}

class GetStats {
  final WordsDao _words;
  final AnswerLogDao _log;
  GetStats(this._words, this._log);

  Future<StatsSnapshot> call() async {
    final res = await Future.wait([
      _words.count(),
      _words.learnedCount(),
      _words.inProgressCount(),
      _words.newCount(),
      _log.currentStreak(),
      _log.overallAccuracy(),
      _log.recent(days: 30),
    ]);
    return StatsSnapshot(
      total: res[0] as int,
      learned: res[1] as int,
      inProgress: res[2] as int,
      newWords: res[3] as int,
      streakDays: res[4] as int,
      accuracy: res[5] as double?,
      last30Days: res[6] as List<DailyTotals>,
    );
  }
}
