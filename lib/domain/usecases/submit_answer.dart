import '../../data/local/answer_log_dao.dart';
import '../../data/repositories/words_repository.dart';
import '../models/question.dart';
import '../models/word.dart';

class SubmitAnswer {
  final WordsRepository _repo;
  final AnswerLogDao _log;
  SubmitAnswer(this._repo, this._log);

  Future<AnswerOutcome> call({
    required Word word,
    required bool correct,
  }) async {
    int short = word.shortScore;
    int long = word.longScore;
    DateTime? lastLongUpAt = word.lastLongUpAt;
    DateTime? learnedAt = word.learnedAt;
    int decayStep = word.decayStep;

    final now = DateTime.now();
    final wasLearned = learnedAt != null;

    if (correct) {
      short += 1;
    } else {
      short -= 3;
      if (wasLearned) {
        long -= 1;
        learnedAt = null;
        decayStep = 0;
      }
    }

    final dayPassed = lastLongUpAt == null ||
        now.difference(lastLongUpAt).inDays >= 1;
    if (short >= 10 && dayPassed) {
      long += 1;
      short = 0;
      lastLongUpAt = now;
    }

    final justLearned = !wasLearned && long >= 10;
    if (justLearned) {
      learnedAt = now;
      decayStep = 0;
    }

    final updated = word.copyWith(
      shortScore: short,
      longScore: long,
      lastLongUpAt: lastLongUpAt,
      clearLastLongUpAt: lastLongUpAt == null,
      learnedAt: learnedAt,
      clearLearnedAt: learnedAt == null,
      decayStep: decayStep,
    );

    await _repo.updateWord(updated);
    await _log.log(
      wordId: word.id,
      result: correct ? AnswerResultKind.correct : AnswerResultKind.wrong,
      at: now,
    );

    return AnswerOutcome(
      correct: correct,
      shortDelta: updated.shortScore - word.shortScore,
      longDelta: updated.longScore - word.longScore,
      justLearned: justLearned,
      updated: updated,
    );
  }
}
