import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/word.dart';
import '../local/app_database.dart';
import '../local/app_state_dao.dart';
import '../local/words_dao.dart';
import '../remote/words_remote_source.dart';

/// Single source of truth for word data. View layer never touches DAOs or
/// remote source directly — only via use-cases that depend on this repo.
class WordsRepository {
  final AppDatabase _db;
  final WordsDao _wordsDao;
  final AppStateDao _stateDao;
  final WordsRemoteSource _remote;

  WordsRepository({
    required AppDatabase db,
    required WordsDao wordsDao,
    required AppStateDao stateDao,
    required WordsRemoteSource remote,
  })  : _db = db,
        _wordsDao = wordsDao,
        _stateDao = stateDao,
        _remote = remote;

  static const _kSeedLoaded = 'seed_loaded';
  static const _kLastLoadedBatch = 'last_loaded_batch';
  static const _seedAsset = 'assets/seed/words.json';

  /// Defined batch progression. After seed, load batches in this order.
  static const batchOrder = [
    'a2_batch_2',
    'b2_batch_1',
  ];

  /// Ensures DB is open and seed words are loaded on first launch.
  Future<void> bootstrap() async {
    await _db.open();
    if (await _stateDao.get(_kSeedLoaded) == 'true') return;
    final raw = await rootBundle.loadString(_seedAsset);
    final j = jsonDecode(raw) as Map<String, Object?>;
    final list = (j['words'] as List? ?? []).cast<Map<String, Object?>>();
    if (list.isNotEmpty) {
      final words = list.map((m) => Word.fromSeedJson(m, batch: 'seed')).toList();
      await _wordsDao.upsertAll(words);
    }
    await _stateDao.set(_kSeedLoaded, 'true');
  }

  // ── read

  Future<int> totalCount({List<String>? levels}) => _wordsDao.count(levels: levels);
  Future<int> learnedCount({List<String>? levels}) => _wordsDao.learnedCount(levels: levels);
  Future<List<Word>> active({int limit = 200, List<String>? levels}) =>
      _wordsDao.active(limit: limit, levels: levels);
  Future<List<Word>> learnedForDecay() => _wordsDao.learnedForDecay();

  Future<List<String>> randomDistractors({
    required int excludeId,
    required bool needsNativeAnswer,
    required String nativeLang,
    required int count,
    List<String>? levels,
  }) =>
      _wordsDao.randomDistractors(
        excludeId: excludeId,
        needsNativeAnswer: needsNativeAnswer,
        nativeLang: nativeLang,
        count: count,
        levels: levels,
      );

  // ── write

  Future<void> updateWord(Word w) => _wordsDao.update(w);

  // ── remote batch loading

  Future<String?> nextBatchId() async {
    final last = await _stateDao.get(_kLastLoadedBatch);
    if (last == null) return batchOrder.first;
    final idx = batchOrder.indexOf(last);
    if (idx < 0 || idx >= batchOrder.length - 1) return null;
    return batchOrder[idx + 1];
  }

  Future<bool> loadBatch(String batchId) async {
    final words = await _remote.fetchBatch(batchId);
    if (words == null || words.isEmpty) return false;
    await _wordsDao.upsertAll(words);
    await _stateDao.set(_kLastLoadedBatch, batchId);
    return true;
  }
}
