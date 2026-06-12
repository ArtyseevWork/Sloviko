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
    // Defense against concurrent calls on the same Word: read the freshly
    // persisted scores so we never apply -3 to a stale 0 while another call
    // has already written -3.
    final fresh = await _repo.findById(word.id) ?? word;
    int short = fresh.shortScore;
    int long = fresh.longScore;
    DateTime? lastLongUpAt = fresh.lastLongUpAt;
    DateTime? learnedAt = fresh.learnedAt;
    int decayStep = fresh.decayStep;

    final now = DateTime.now();
    final wasLearned = learnedAt != null;
    final fromShort = fresh.shortScore;
    final fromLong = fresh.longScore;

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

    final updated = fresh.copyWith(
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
      shortDelta: updated.shortScore - fromShort,
      longDelta: updated.longScore - fromLong,
      justLearned: justLearned,
      updated: updated,
    );
  }
}
