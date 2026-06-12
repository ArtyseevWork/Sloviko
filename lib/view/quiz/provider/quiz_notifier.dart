import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/di/providers.dart';
import '../../../core/locale/native_lang.dart';
import '../../../core/settings/cefr_levels.dart';
import '../../../core/settings/daily_goal.dart';
import '../../../domain/models/question.dart';
import '../../../domain/usecases/get_next_question.dart';
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
  final int todayPoints;
  final int dailyGoal;
  final bool exhausted;
  final String nativeLang;
  final List<String> activeLevels;

  const QuizState({
    this.loading = true,
    this.question,
    this.buttonStates = const [],
    this.answered = false,
    this.scoreFloat,
    this.celebrating = false,
    this.totalCount = 0,
    this.learnedCount = 0,
    this.todayPoints = 0,
    this.dailyGoal = 100,
    this.exhausted = false,
    this.nativeLang = 'uk',
    this.activeLevels = const ['A1', 'A2', 'B1', 'B2'],
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
    int? todayPoints,
    int? dailyGoal,
    bool? exhausted,
    String? nativeLang,
    List<String>? activeLevels,
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
        todayPoints: todayPoints ?? this.todayPoints,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        exhausted: exhausted ?? this.exhausted,
        nativeLang: nativeLang ?? this.nativeLang,
        activeLevels: activeLevels ?? this.activeLevels,
      );
}

class QuizNotifier extends ChangeNotifier {
  final GetNextQuestion _getNext;
  final SubmitAnswer _submit;
  final MarkAsKnown _markKnown;
  final AudioService _audio;
  final Future<int> Function(List<String>) _totalCount;
  final Future<int> Function(List<String>) _learnedCount;
  final Future<int> Function() _todayPoints;
  final int Function() _dailyGoal;
  final String Function() _nativeLang;
  final List<String> Function() _activeLevels;

  QuizState state = const QuizState();
  bool _disposed = false;

  QuizNotifier({
    required GetNextQuestion getNext,
    required SubmitAnswer submit,
    required MarkAsKnown markKnown,
    required AudioService audio,
    required Future<int> Function(List<String>) totalCount,
    required Future<int> Function(List<String>) learnedCount,
    required Future<int> Function() todayPoints,
    required int Function() dailyGoal,
    required String Function() nativeLang,
    required List<String> Function() activeLevels,
  })  : _getNext = getNext,
        _submit = submit,
        _markKnown = markKnown,
        _audio = audio,
        _totalCount = totalCount,
        _learnedCount = learnedCount,
        _todayPoints = todayPoints,
        _dailyGoal = dailyGoal,
        _nativeLang = nativeLang,
        _activeLevels = activeLevels {
    _init();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> _init() async {
    state = state.copy(nativeLang: _nativeLang(), activeLevels: _activeLevels());
    await _refreshCounts();
    await _next();
  }

  Future<void> reload() async {
    state = state.copy(nativeLang: _nativeLang(), activeLevels: _activeLevels());
    await _refreshCounts();
    await _next();
  }

  Future<void> _refreshCounts() async {
    final total = await _totalCount(state.activeLevels);
    final learned = await _learnedCount(state.activeLevels);
    final today = await _todayPoints();
    state = state.copy(
      totalCount: total,
      learnedCount: learned,
      todayPoints: today,
      dailyGoal: _dailyGoal(),
    );
    _safeNotify();
  }

  Future<void> _next() async {
    // Audio from the previous word is intentionally left to finish — the
    // user wanted the pronunciation to be audible in full. A new playUrl
    // call (next wrong answer) will preempt it via _player.stop() inside
    // AudioService.
    state = state.copy(
      loading: true,
      answered: false,
      celebrating: false,
      clearScoreFloat: true,
    );
    _safeNotify();

    final q = await _getNext.call(
      nativeLang: state.nativeLang,
      activeLevels: state.activeLevels,
    );
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

    // Pre-warm the pronunciation buffer so a wrong-answer playback starts
    // near-instantly instead of paying for HTTPS handshake + codec init on
    // tap. URL preference matches playUrl (UK first, US fallback).
    final preloadUrl = q.target.audioUk ?? q.target.audioUs;
    if (preloadUrl != null && preloadUrl.isNotEmpty) {
      unawaited(_audio.prepare(preloadUrl));
    }
  }

  Future<void> selectOption(int index) async {
    final q = state.question;
    if (q == null || state.answered) return;

    // Lock immediately so a rapid double/triple-tap during the async submit
    // can't enqueue extra wrong answers (each one used to write -3 to the
    // daily total).
    state = state.copy(answered: true);
    _safeNotify();

    final correct = index == q.correctIndex;
    final outcome = await _submit.call(word: q.target, correct: correct);

    // On wrong answer — play the correct word's pronunciation so the user
    // hears how it actually sounds. Prefer UK audio, fall back to US.
    if (!correct) {
      final url = q.target.audioUk ?? q.target.audioUs;
      unawaited(_audio.playUrl(url));
    }

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

  Future<void> markCurrentAsKnown() async {
    final q = state.question;
    if (q == null || state.answered) return;
    state = state.copy(answered: true);
    _safeNotify();
    await _markKnown.call(q.target);
    await _refreshCounts();
    await _next();
  }
}

final quizNotifierProvider = ChangeNotifierProvider<QuizNotifier>((ref) {
  final repo = ref.watch(wordsRepositoryProvider);
  final nativeLang = ref.watch(nativeLangProvider);
  final levels = ref.watch(cefrLevelsProvider);
  final goal = ref.watch(dailyGoalProvider);
  final log = ref.watch(answerLogDaoProvider);
  return QuizNotifier(
    getNext: ref.watch(getNextQuestionProvider),
    submit: ref.watch(submitAnswerProvider),
    markKnown: ref.watch(markAsKnownProvider),
    audio: ref.watch(audioServiceProvider),
    totalCount: (lvls) => repo.totalCount(levels: lvls),
    learnedCount: (lvls) => repo.learnedCount(levels: lvls),
    todayPoints: log.todayPoints,
    dailyGoal: () => goal.goal,
    nativeLang: () => nativeLang.code,
    activeLevels: () => levels.levels,
  );
});

void unawaited(Future<void> _) {}
