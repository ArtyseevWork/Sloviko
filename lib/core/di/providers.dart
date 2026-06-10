import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/answer_log_dao.dart';
import '../../data/local/app_database.dart';
import '../../data/local/app_state_dao.dart';
import '../../data/local/words_dao.dart';
import '../../data/remote/words_remote_source.dart';
import '../../data/repositories/words_repository.dart';
import '../../domain/usecases/apply_decay.dart';
import '../../domain/usecases/get_next_question.dart';
import '../../domain/usecases/get_stats.dart';
import '../../domain/usecases/load_next_batch.dart';
import '../../domain/usecases/mark_as_known.dart';
import '../../domain/usecases/submit_answer.dart';

// ── infrastructure
final appDatabaseProvider = Provider<AppDatabase>((_) => AppDatabase());
final wordsDaoProvider = Provider<WordsDao>(
    (ref) => WordsDao(ref.watch(appDatabaseProvider)));
final appStateDaoProvider = Provider<AppStateDao>(
    (ref) => AppStateDao(ref.watch(appDatabaseProvider)));
final answerLogDaoProvider = Provider<AnswerLogDao>(
    (ref) => AnswerLogDao(ref.watch(appDatabaseProvider)));
final wordsRemoteSourceProvider =
    Provider<WordsRemoteSource>((_) => WordsRemoteSource());

// ── repository
final wordsRepositoryProvider = Provider<WordsRepository>((ref) {
  return WordsRepository(
    db: ref.watch(appDatabaseProvider),
    wordsDao: ref.watch(wordsDaoProvider),
    stateDao: ref.watch(appStateDaoProvider),
    remote: ref.watch(wordsRemoteSourceProvider),
  );
});

// ── use cases
final getNextQuestionProvider =
    Provider((ref) => GetNextQuestion(ref.watch(wordsRepositoryProvider)));
final submitAnswerProvider = Provider((ref) => SubmitAnswer(
      ref.watch(wordsRepositoryProvider),
      ref.watch(answerLogDaoProvider),
    ));
final markAsKnownProvider = Provider((ref) => MarkAsKnown(
      ref.watch(wordsRepositoryProvider),
      ref.watch(answerLogDaoProvider),
    ));
final applyDecayProvider =
    Provider((ref) => ApplyDecay(ref.watch(wordsRepositoryProvider)));
final loadNextBatchProvider =
    Provider((ref) => LoadNextBatch(ref.watch(wordsRepositoryProvider)));
final getStatsProvider = Provider((ref) => GetStats(
      ref.watch(wordsDaoProvider),
      ref.watch(answerLogDaoProvider),
    ));
