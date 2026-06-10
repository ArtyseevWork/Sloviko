import '../../data/repositories/words_repository.dart';

/// Forgetting-curve tick. Run on app start.
/// For each learned word, if enough days have passed since learnedAt for the
/// current decay_step, apply long_score -1 and advance the step. When long
/// drops below the learned threshold (10), clear learned_at so the word
/// returns to the active rotation.
///
/// Thresholds in days from learnedAt: 7, 14, 30, 90 (steps 0→1→2→3→4).
class ApplyDecay {
  static const _thresholds = [7, 14, 30, 90];
  final WordsRepository _repo;
  ApplyDecay(this._repo);

  Future<int> call() async {
    final learned = await _repo.learnedForDecay();
    final now = DateTime.now();
    int affected = 0;

    for (final w in learned) {
      final base = w.learnedAt;
      if (base == null) continue;
      final daysSince = now.difference(base).inDays;

      int step = w.decayStep;
      int long = w.longScore;
      bool changed = false;

      while (step < _thresholds.length && daysSince >= _thresholds[step]) {
        long -= 1;
        step += 1;
        changed = true;
      }

      if (changed) {
        final stillLearned = long >= 10;
        await _repo.updateWord(w.copyWith(
          longScore: long,
          decayStep: step,
          learnedAt: stillLearned ? w.learnedAt : null,
          clearLearnedAt: !stillLearned,
        ));
        affected++;
      }
    }
    return affected;
  }
}
