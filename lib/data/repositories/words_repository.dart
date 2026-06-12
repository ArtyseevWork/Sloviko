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
  static const _kCachedManifest = 'cached_batch_manifest';
  static const _kManifestSeparator = ',';
  static const _seedAsset = 'assets/seed/words.json';

  /// Compiled-in fallback order — used when no remote manifest has been
  /// cached yet (first launch, offline, or repo manifest unreachable). The
  /// runtime always prefers a freshly-fetched remote manifest so installed
  /// app builds can pick up new batches without an APK update.
  static const batchOrder = [
    'a1_batch_1',
    'a2_batch_2',
    'b1_batch_1',
    'b2_batch_1',
    'c1_batch_1',
    'a1_batch_2',
    'a2_batch_3',
    'b1_batch_2',
    'b2_batch_2',
    'c1_batch_2',
    'a1_batch_3',
    'a2_batch_4',
    'b1_batch_3',
    'b2_batch_3',
    'c1_batch_3',
    'a1_batch_4',
    'a2_batch_5',
    'b1_batch_4',
    'b2_batch_4',
    'c1_batch_4',
    'a1_batch_5',
    'a2_batch_6',
    'b1_batch_5',
    'b2_batch_5',
    'c1_batch_5',
    'a1_batch_6',
    'a2_batch_7',
    'b1_batch_6',
    'a1_batch_7',
    'a2_batch_8',
    'b1_batch_7',
    'a1_batch_8',
    'a2_batch_9',
    'b1_batch_8',
    'b2_batch_6',
    'b2_batch_7',
    'b2_batch_8',
    'b2_batch_9',
    'b2_batch_10',
    'a1_batch_9',
    'a2_batch_10',
    'b1_batch_9',
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
  Future<Word?> findById(int id) => _wordsDao.findById(id);

  // ── remote batch loading

  /// Pulls the remote batch-order manifest and caches it in app_state. Called
  /// from splash so new app sessions pick up any batches appended to the repo
  /// since the APK was built. Silent no-op when offline.
  Future<void> refreshManifest() async {
    final remote = await _remote.fetchManifest();
    if (remote == null || remote.isEmpty) return;
    await _stateDao.set(_kCachedManifest, remote.join(_kManifestSeparator));
  }

  /// Cached remote manifest if available, otherwise the compiled fallback.
  Future<List<String>> currentBatchOrder() async {
    final cached = await _stateDao.get(_kCachedManifest);
    if (cached != null && cached.isNotEmpty) {
      return cached.split(_kManifestSeparator);
    }
    return batchOrder;
  }

  Future<String?> nextBatchId() async {
    final order = await currentBatchOrder();
    final last = await _stateDao.get(_kLastLoadedBatch);
    if (last == null) return order.first;
    final idx = order.indexOf(last);
    if (idx < 0 || idx >= order.length - 1) return null;
    return order[idx + 1];
  }

  /// First batch in the current order whose CEFR level is in [activeLevels]
  /// AND that hasn't been inserted into the DB yet. Allows skipping levels
  /// the user doesn't want or back-filling earlier levels they enabled later.
  Future<String?> nextBatchForLevels(List<String> activeLevels) async {
    if (activeLevels.isEmpty) return null;
    final order = await currentBatchOrder();
    final loaded = await _wordsDao.distinctBatches();
    for (final id in order) {
      if (loaded.contains(id)) continue;
      final level = id.substring(0, 2).toUpperCase();
      if (activeLevels.contains(level)) return id;
    }
    return null;
  }

  Future<bool> loadBatch(String batchId) async {
    final words = await _remote.fetchBatch(batchId);
    if (words == null || words.isEmpty) return false;
    await _wordsDao.upsertAll(words);
    await _stateDao.set(_kLastLoadedBatch, batchId);
    return true;
  }
}
