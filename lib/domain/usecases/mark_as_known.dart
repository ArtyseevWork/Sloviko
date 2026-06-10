import '../../data/local/answer_log_dao.dart';
import '../../data/repositories/words_repository.dart';
import '../models/word.dart';

/// "I already know this word" — instantly mark as learned (long_score = 10,
/// learned_at = now, decay_step = 0). Word will be subject to forgetting
/// curve decay just like organically-learned words.
class MarkAsKnown {
  final WordsRepository _repo;
  final AnswerLogDao _log;
  MarkAsKnown(this._repo, this._log);

  Future<Word> call(Word word) async {
    final now = DateTime.now();
    final updated = word.copyWith(
      shortScore: 0,
      longScore: 10,
      learnedAt: now,
      decayStep: 0,
      clearLastLongUpAt: false,
    );
    await _repo.updateWord(updated);
    await _log.log(wordId: word.id, result: AnswerResultKind.skip, at: now);
    return updated;
  }
}
