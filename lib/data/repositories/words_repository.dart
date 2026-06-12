import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/word.dart';
import '../local/app_database.dart';
import '../local/app_state_dao.dart';
import '../local/words_dao.dart';

/// Single source of truth for word data. The full dictionary ships bundled
/// in the APK as `assets/seed/words.json` and is inserted into the local DB
/// on first launch — no network fetch needed for vocabulary content (audio
/// pronunciation still streams from Oxford on demand).
class WordsRepository {
  final AppDatabase _db;
  final WordsDao _wordsDao;
  final AppStateDao _stateDao;

  WordsRepository({
    required AppDatabase db,
    required WordsDao wordsDao,
    required AppStateDao stateDao,
  })  : _db = db,
        _wordsDao = wordsDao,
        _stateDao = stateDao;

  static const _kSeedLoaded = 'seed_loaded';
  static const _kSeedVersion = 'seed_version';
  static const _seedAsset = 'assets/seed/words.json';

  /// Open DB and load the bundled seed on first launch (or when the seed
  /// version bumps in a newer APK).
  Future<void> bootstrap() async {
    await _db.open();
    final raw = await rootBundle.loadString(_seedAsset);
    final j = jsonDecode(raw) as Map<String, Object?>;
    final version = (j['version'] as int?) ?? 1;
    final cachedVersion = int.tryParse(await _stateDao.get(_kSeedVersion) ?? '');
    if (await _stateDao.get(_kSeedLoaded) == 'true' && cachedVersion == version) {
      return;
    }
    final list = (j['words'] as List? ?? []).cast<Map<String, Object?>>();
    if (list.isNotEmpty) {
      final words = list.map((m) => Word.fromSeedJson(m, batch: 'seed')).toList();
      await _wordsDao.upsertAll(words);
    }
    await _stateDao.set(_kSeedLoaded, 'true');
    await _stateDao.set(_kSeedVersion, version.toString());
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
}
