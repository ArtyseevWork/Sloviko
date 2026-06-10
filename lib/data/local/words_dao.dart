import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/models/word.dart';
import 'app_database.dart';

class WordsDao {
  final AppDatabase _db;
  WordsDao(this._db);

  Database get _d => _db.db;

  Future<int> count() async {
    final r = await _d.rawQuery('SELECT COUNT(*) AS c FROM words');
    return (r.first['c'] as int?) ?? 0;
  }

  Future<int> learnedCount() async {
    final r = await _d.rawQuery('SELECT COUNT(*) AS c FROM words WHERE learned_at IS NOT NULL');
    return (r.first['c'] as int?) ?? 0;
  }

  Future<int> inProgressCount() async {
    final r = await _d.rawQuery(
      'SELECT COUNT(*) AS c FROM words WHERE learned_at IS NULL AND (short_score > 0 OR long_score > 0)',
    );
    return (r.first['c'] as int?) ?? 0;
  }

  Future<int> newCount() async {
    final r = await _d.rawQuery(
      'SELECT COUNT(*) AS c FROM words WHERE learned_at IS NULL AND short_score = 0 AND long_score = 0',
    );
    return (r.first['c'] as int?) ?? 0;
  }

  Future<List<Word>> all() async {
    final rows = await _d.query('words', orderBy: 'id ASC');
    return rows.map(Word.fromMap).toList();
  }

  Future<List<Word>> active({int limit = 200}) async {
    final rows = await _d.query(
      'words',
      where: 'learned_at IS NULL',
      orderBy: 'short_score ASC, long_score ASC, id ASC',
      limit: limit,
    );
    return rows.map(Word.fromMap).toList();
  }

  /// Random distractor strings in [nativeLang] for EN→native questions,
  /// or English distractors for native→EN questions.
  Future<List<String>> randomDistractors({
    required int excludeId,
    required bool needsNativeAnswer,
    required String nativeLang,
    required int count,
  }) async {
    final rows = await _d.rawQuery(
      'SELECT en, translations FROM words WHERE id != ? ORDER BY RANDOM() LIMIT ?',
      [excludeId, count * 2], // pull extras since translations may be missing
    );
    final out = <String>{};
    for (final r in rows) {
      if (needsNativeAnswer) {
        final tr = (jsonDecode(r['translations'] as String) as Map).cast<String, String>();
        final v = tr[nativeLang];
        if (v != null && v.isNotEmpty) out.add(v);
      } else {
        out.add(r['en'] as String);
      }
      if (out.length >= count) break;
    }
    return out.toList();
  }

  Future<List<Word>> learnedForDecay() async {
    final rows = await _d.query(
      'words',
      where: 'learned_at IS NOT NULL AND decay_step < 4',
    );
    return rows.map(Word.fromMap).toList();
  }

  Future<void> upsertAll(List<Word> ws) async {
    final batch = _d.batch();
    for (final w in ws) {
      batch.insert('words', w.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(Word w) async {
    await _d.update('words', w.toMap(), where: 'id = ?', whereArgs: [w.id]);
  }
}
