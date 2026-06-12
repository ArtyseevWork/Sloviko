import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/models/word.dart';
import 'app_database.dart';

class WordsDao {
  final AppDatabase _db;
  WordsDao(this._db);

  Database get _d => _db.db;

  Future<int> count({List<String>? levels}) async {
    final (where, args) = _levelFilter(levels);
    final r = await _d.rawQuery('SELECT COUNT(*) AS c FROM words$where', args);
    return (r.first['c'] as int?) ?? 0;
  }

  Future<int> learnedCount({List<String>? levels}) async {
    final (lvlWhere, args) = _levelFilter(levels, prefixWith: 'AND');
    final r = await _d.rawQuery(
      'SELECT COUNT(*) AS c FROM words WHERE learned_at IS NOT NULL $lvlWhere',
      args,
    );
    return (r.first['c'] as int?) ?? 0;
  }

  /// Helper. Returns (' WHERE cefr IN (?,?)' or '', [args]).
  /// When [prefixWith] is given (e.g. 'AND'), starts with that connector
  /// instead of 'WHERE'.
  (String, List<Object?>) _levelFilter(List<String>? levels, {String prefixWith = 'WHERE'}) {
    if (levels == null || levels.isEmpty) return ('', const []);
    final placeholders = List.filled(levels.length, '?').join(',');
    return (' $prefixWith cefr IN ($placeholders)', List<Object?>.of(levels));
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

  Future<Word?> findById(int id) async {
    final rows = await _d.query('words', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Word.fromMap(rows.first);
  }

  Future<List<Word>> all() async {
    final rows = await _d.query('words', orderBy: 'id ASC');
    return rows.map(Word.fromMap).toList();
  }

  /// Active (not yet learned), optionally filtered by CEFR levels.
  /// Empty/null [levels] = no filter.
  Future<List<Word>> active({
    int limit = 200,
    List<String>? levels,
  }) async {
    var where = 'learned_at IS NULL';
    final args = <Object?>[];
    if (levels != null && levels.isNotEmpty) {
      final placeholders = List.filled(levels.length, '?').join(',');
      where += ' AND cefr IN ($placeholders)';
      args.addAll(levels);
    }
    final rows = await _d.query(
      'words',
      where: where,
      whereArgs: args,
      orderBy: 'short_score ASC, long_score ASC, id ASC',
      limit: limit,
    );
    return rows.map(Word.fromMap).toList();
  }

  Future<List<String>> randomDistractors({
    required int excludeId,
    required bool needsNativeAnswer,
    required String nativeLang,
    required int count,
    List<String>? levels,
  }) async {
    var sql = 'SELECT en, translations FROM words WHERE id != ?';
    final args = <Object?>[excludeId];
    if (levels != null && levels.isNotEmpty) {
      final placeholders = List.filled(levels.length, '?').join(',');
      sql += ' AND cefr IN ($placeholders)';
      args.addAll(levels);
    }
    sql += ' ORDER BY RANDOM() LIMIT ?';
    args.add(count * 2);
    final rows = await _d.rawQuery(sql, args);
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

  Future<Set<String>> distinctBatches() async {
    final rows = await _d.rawQuery('SELECT DISTINCT batch FROM words');
    return rows.map((r) => r['batch'] as String).toSet();
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
