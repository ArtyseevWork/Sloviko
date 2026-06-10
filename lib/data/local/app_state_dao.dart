import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

class AppStateDao {
  final AppDatabase _db;
  AppStateDao(this._db);

  Future<String?> get(String key) async {
    final rows = await _db.db.query('app_state', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    await _db.db.insert(
      'app_state',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
