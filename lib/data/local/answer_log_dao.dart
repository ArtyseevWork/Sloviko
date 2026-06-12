import 'app_database.dart';

enum AnswerResultKind { correct, wrong, skip }

class DailyTotals {
  final String day; // YYYY-MM-DD
  final int correct;
  final int wrong;
  final int skip;

  const DailyTotals({
    required this.day,
    required this.correct,
    required this.wrong,
    required this.skip,
  });

  int get total => correct + wrong + skip;
}

class AnswerLogDao {
  final AppDatabase _db;
  AnswerLogDao(this._db);

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> log({
    required int wordId,
    required AnswerResultKind result,
    DateTime? at,
  }) async {
    final ts = at ?? DateTime.now();
    await _db.db.insert('answer_log', {
      'word_id': wordId,
      'day': _ymd(ts),
      'result': result.name,
      'at': ts.millisecondsSinceEpoch,
    });
  }

  /// Totals for the last [days] days, ascending. Days with no activity are
  /// included with zeros so the chart has a contiguous axis.
  Future<List<DailyTotals>> recent({int days = 30}) async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final firstYmd = _ymd(firstDay);

    final rows = await _db.db.rawQuery(
      "SELECT day, result, COUNT(*) AS c FROM answer_log "
      'WHERE day >= ? GROUP BY day, result',
      [firstYmd],
    );

    final map = <String, Map<String, int>>{};
    for (final r in rows) {
      final d = r['day'] as String;
      final res = r['result'] as String;
      final c = (r['c'] as int?) ?? 0;
      map.putIfAbsent(d, () => {})[res] = c;
    }

    final out = <DailyTotals>[];
    for (var i = 0; i < days; i++) {
      final day = firstDay.add(Duration(days: i));
      final key = _ymd(day);
      final m = map[key] ?? const {};
      out.add(DailyTotals(
        day: key,
        correct: m['correct'] ?? 0,
        wrong: m['wrong'] ?? 0,
        skip: m['skip'] ?? 0,
      ));
    }
    return out;
  }

  /// Net daily points: +1 per correct, -3 per wrong.
  /// Mirrors the per-word short_score delta in submit_answer.
  /// "Skip" (I-know-this) is not counted — it's a user assertion, not earned.
  Future<int> todayPoints() async {
    final today = _ymd(DateTime.now());
    final r = await _db.db.rawQuery(
      "SELECT result, COUNT(*) AS c FROM answer_log "
      "WHERE day = ? AND result IN ('correct','wrong') GROUP BY result",
      [today],
    );
    int correct = 0, wrong = 0;
    for (final row in r) {
      final c = (row['c'] as int?) ?? 0;
      if (row['result'] == 'correct') correct = c;
      if (row['result'] == 'wrong') wrong = c;
    }
    return correct - wrong * 3;
  }

  /// Distinct days with at least one event, descending.
  Future<List<String>> activeDays({int lookbackDays = 365}) async {
    final firstDay = DateTime.now().subtract(Duration(days: lookbackDays));
    final rows = await _db.db.rawQuery(
      'SELECT DISTINCT day FROM answer_log WHERE day >= ? ORDER BY day DESC',
      [_ymd(firstDay)],
    );
    return rows.map((r) => r['day'] as String).toList();
  }

  /// Consecutive-day streak ending today (or 0 if today wasn't active).
  Future<int> currentStreak() async {
    final days = (await activeDays()).toSet();
    if (days.isEmpty) return 0;
    var d = DateTime.now();
    final today = DateTime(d.year, d.month, d.day);
    if (!days.contains(_ymd(today))) return 0;
    var streak = 0;
    var cursor = today;
    while (days.contains(_ymd(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Overall accuracy (correct / (correct + wrong)). Returns null if no data.
  Future<double?> overallAccuracy() async {
    final r = await _db.db.rawQuery(
      "SELECT result, COUNT(*) AS c FROM answer_log "
      "WHERE result IN ('correct', 'wrong') GROUP BY result",
    );
    int correct = 0, wrong = 0;
    for (final row in r) {
      final c = (row['c'] as int?) ?? 0;
      if (row['result'] == 'correct') correct = c;
      if (row['result'] == 'wrong') wrong = c;
    }
    final total = correct + wrong;
    if (total == 0) return null;
    return correct / total;
  }
}
