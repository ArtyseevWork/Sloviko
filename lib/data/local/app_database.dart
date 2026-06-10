import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Schema v1:
///   words (id, en, translations TEXT JSON, short_score, long_score,
///          last_long_up_at, learned_at, decay_step, batch, cefr)
///   app_state (key TEXT PRIMARY KEY, value TEXT)
///   answer_log (id INTEGER PRIMARY KEY, word_id, day TEXT YYYY-MM-DD,
///               result TEXT 'correct'|'wrong'|'skip', at INTEGER)
class AppDatabase {
  static const _dbName = 'lexio.db';
  static const _version = 1;

  Database? _db;
  Database get db {
    final d = _db;
    if (d == null) {
      throw StateError('AppDatabase not opened — call open() first');
    }
    return d;
  }

  Future<void> open() async {
    if (_db != null) return;
    final path = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(path, version: _version, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createWords(db);
    await _createAppState(db);
    await _createAnswerLog(db);
  }

  Future<void> _createWords(Database db) async {
    await db.execute('''
      CREATE TABLE words (
        id INTEGER PRIMARY KEY,
        en TEXT NOT NULL,
        translations TEXT NOT NULL DEFAULT '{}',
        short_score INTEGER NOT NULL DEFAULT 0,
        long_score INTEGER NOT NULL DEFAULT 0,
        last_long_up_at INTEGER,
        learned_at INTEGER,
        decay_step INTEGER NOT NULL DEFAULT 0,
        batch TEXT NOT NULL DEFAULT 'seed',
        cefr TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_words_learned ON words(learned_at)');
    await db.execute('CREATE INDEX idx_words_batch ON words(batch)');
  }

  Future<void> _createAppState(Database db) async {
    await db.execute('''
      CREATE TABLE app_state (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _createAnswerLog(Database db) async {
    await db.execute('''
      CREATE TABLE answer_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        day TEXT NOT NULL,
        result TEXT NOT NULL,
        at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_log_day ON answer_log(day)');
  }
}
