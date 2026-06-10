import 'word.dart';

enum QuestionDirection { enToRu, ruToEn }

/// A single quiz question — one target word + 6 answer options.
class Question {
  final Word target;
  final QuestionDirection direction;
  final List<String> options; // 6 options
  final int correctIndex;

  const Question({
    required this.target,
    required this.direction,
    required this.options,
    required this.correctIndex,
  });

  /// English prompt is identifier-only — UI resolves native-language prompt
  /// via WordArea + Word.tr(nativeLang) directly.
  String get promptEn => target.en;
}

/// Outcome of submitting an answer — used by the UI to render +1/-3 etc.
class AnswerOutcome {
  final bool correct;
  final int shortDelta;
  final int longDelta;
  final bool justLearned;
  final Word updated;

  const AnswerOutcome({
    required this.correct,
    required this.shortDelta,
    required this.longDelta,
    required this.justLearned,
    required this.updated,
  });
}
