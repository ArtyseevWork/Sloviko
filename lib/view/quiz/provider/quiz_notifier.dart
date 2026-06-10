import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/locale/native_lang.dart';
import '../../../domain/models/question.dart';
import '../../../domain/usecases/get_next_question.dart';
import '../../../domain/usecases/load_next_batch.dart';
import '../../../domain/usecases/mark_as_known.dart';
import '../../../domain/usecases/submit_answer.dart';

enum AnswerButtonState { idle, correct, wrong, correctReveal }

class QuizState {
  final bool loading;
  final Question? question;
  final List<AnswerButtonState> buttonStates;
  final bool answered;
  final int? scoreFloat;
  final bool celebrating;
  final int totalCount;
  final int learnedCount;
  final bool exhausted;
  final String nativeLang;

  const QuizState({
    this.loading = true,
    this.question,
    this.buttonStates = const [],
    this.answered = false,
    this.scoreFloat,
    this.celebrating = false,
    this.totalCount = 0,
    this.learnedCount = 0,
    this.exhausted = false,
    this.nativeLang = 'uk',
  });

  QuizState copy({
    bool? loading,
    Question? question,
    List<AnswerButtonState>? buttonStates,
    bool? answered,
    int? scoreFloat,
    bool clearScoreFloat = false,
    bool? celebrating,
    int? totalCount,
    int? learnedCount,
    bool? exhausted,
    String? nativeLang,
  }) =>
      QuizState(
        loading: loading ?? this.loading,
        question: question ?? this.question,
        buttonStates: buttonStates ?? this.buttonStates,
        answered: answered ?? this.answered,
        scoreFloat: clearScoreFloat ? null : (scoreFloat ?? this.scoreFloat),
        celebrating: celebrating ?? this.celebrating,
        totalCount: totalCount ?? this.totalCount,
        learnedCount: learnedCount ?? this.learnedCount,
        exhausted: exhausted ?? this.exhausted,
        nativeLang: nativeLang ?? this.nativeLang,
      );
}

class QuizNotifier extends ChangeNotifier {
  final GetNextQuestion _getNext;
  final SubmitAnswer _submit;
  final MarkAsKnown _markKnown;
  final LoadNextBatch _loadBatch;
  final Future<int> Function() _totalCount;
  final Future<int> Function() _learnedCount;
  final String Function() _nativeLang;

  QuizState state = const QuizState();
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  QuizNotifier({
    required GetNextQuestion getNext,
    required SubmitAnswer submit,
    required MarkAsKnown markKnown,
    required LoadNextBatch loadBatch,
    required Future<int> Function() totalCount,
    required Future<int> Function() learnedCount,
    required String Function() nativeLang,
  })  : _getNext = getNext,
        _submit = submit,
        _markKnown = markKnown,
        _loadBatch = loadBatch,
        _totalCount = totalCount,
        _learnedCount = learnedCount,
        _nativeLang = nativeLang {
    _init();
  }

  Future<void> _init() async {
    state = state.copy(nativeLang: _nativeLang());
    await _refreshCounts();
    await _next();
  }

  /// External trigger (called when native lang changes).
  Future<void> reload() async {
    state = state.copy(nativeLang: _nativeLang());
    await _refreshCounts();
    await _next();
  }

  Future<void> _refreshCounts() async {
    final total = await _totalCount();
    final learned = await _learnedCount();
    state = state.copy(totalCount: total, learnedCount: learned);
    _safeNotify();
  }

  Future<void> _next() async {
    state = state.copy(
      loading: true,
      answered: false,
      celebrating: false,
      clearScoreFloat: true,
    );
    _safeNotify();

    final q = await _getNext.call(nativeLang: state.nativeLang);
    if (q == null) {
      state = state.copy(loading: false, exhausted: true);
      _safeNotify();
      return;
    }

    state = state.copy(
      loading: false,
      question: q,
      buttonStates: List<AnswerButtonState>.filled(q.options.length, AnswerButtonState.idle),
      exhausted: false,
    );
    _safeNotify();
  }

  Future<void> selectOption(int index) async {
    final q = state.question;
    if (q == null || state.answered) return;

    final correct = index == q.correctIndex;
    final outcome = await _submit.call(word: q.target, correct: correct);

    final newStates = List<AnswerButtonState>.filled(q.options.length, AnswerButtonState.idle);
    if (correct) {
      newStates[index] = AnswerButtonState.correct;
    } else {
      newStates[index] = AnswerButtonState.wrong;
      newStates[q.correctIndex] = AnswerButtonState.correctReveal;
    }

    state = state.copy(
      answered: true,
      buttonStates: newStates,
      scoreFloat: outcome.shortDelta,
      celebrating: outcome.justLearned,
    );
    _safeNotify();

    unawaited(_loadBatch.call());

    Future.delayed(const Duration(milliseconds: 1400), () {
      state = state.copy(clearScoreFloat: true);
      _safeNotify();
    });

    final pause = outcome.justLearned
        ? const Duration(milliseconds: 2500)
        : const Duration(milliseconds: 1300);
    await Future.delayed(pause);

    await _refreshCounts();
    await _next();
  }

  /// "I already know this word" — skip to next, mark as learned.
  Future<void> markCurrentAsKnown() async {
    final q = state.question;
    if (q == null || state.answered) return;
    await _markKnown.call(q.target);
    await _refreshCounts();
    await _next();
  }
}

final quizNotifierProvider = ChangeNotifierProvider<QuizNotifier>((ref) {
  final repo = ref.watch(wordsRepositoryProvider);
  final nativeLang = ref.watch(nativeLangProvider);
  return QuizNotifier(
    getNext: ref.watch(getNextQuestionProvider),
    submit: ref.watch(submitAnswerProvider),
    markKnown: ref.watch(markAsKnownProvider),
    loadBatch: ref.watch(loadNextBatchProvider),
    totalCount: repo.totalCount,
    learnedCount: repo.learnedCount,
    nativeLang: () => nativeLang.code,
  );
});

void unawaited(Future<void> _) {}
