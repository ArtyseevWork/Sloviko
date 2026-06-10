import 'dart:math';

import '../../data/repositories/words_repository.dart';
import '../models/question.dart';
import '../models/word.dart';

class GetNextQuestion {
  final WordsRepository _repo;
  final Random _rng;

  GetNextQuestion(this._repo, {Random? rng}) : _rng = rng ?? Random();

  Future<Question?> call({required String nativeLang}) async {
    final pool = await _repo.active(limit: 60);
    if (pool.isEmpty) return null;

    final pickFromTop = _rng.nextBool();
    final candidates = pickFromTop && pool.length > 30 ? pool.take(30).toList() : pool;
    final Word target = candidates[_rng.nextInt(candidates.length)];

    final direction = _rng.nextBool() ? QuestionDirection.enToRu : QuestionDirection.ruToEn;
    final needsNativeAnswer = direction == QuestionDirection.enToRu;
    final correct = needsNativeAnswer ? target.tr(nativeLang) : target.en;

    final distractors = await _repo.randomDistractors(
      excludeId: target.id,
      needsNativeAnswer: needsNativeAnswer,
      nativeLang: nativeLang,
      count: 5,
    );
    final unique = <String>{...distractors}..remove(correct);
    while (unique.length < 5) {
      unique.add('—');
    }

    final options = [correct, ...unique.take(5)]..shuffle(_rng);
    final correctIndex = options.indexOf(correct);

    return Question(
      target: target,
      direction: direction,
      options: options,
      correctIndex: correctIndex,
    );
  }
}
