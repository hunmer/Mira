import 'package:sqlite3/sqlite3.dart';
import 'library_server_data_interface.dart';

class LibraryServerDataSQLite5 implements LibraryServerDataInterface {
  Database? _db;
  bool _inTransaction = false;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    final dbPath = config['path'] as String;
    _db = sqlite3.open(dbPath);
    _db?.execute('''
      CREATE TABLE IF NOT EXISTS library_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        data TEXT
      )
    ''');
  }

  @override
  Future<int> createRecord(Map<String, dynamic> data) async {
    final stmt = _db!.prepare(
      'INSERT OR REPLACE INTO library_records(data) VALUES(?)',
    );
    stmt.execute([data.toString()]);
    return _db!.lastInsertRowId;
  }

  @override
  Future<bool> deleteRecord(int id) async {
    final stmt = _db!.prepare('DELETE FROM library_records WHERE id = ?');
    stmt.execute([id]);
    return true; // todo check if row was deleted
  }

  @override
  Future<Map<String, dynamic>?> getRecord(int id) async {
    final stmt = _db!.prepare(
      'SELECT * FROM library_records WHERE id = ? LIMIT 1',
    );
    final result = stmt.select([id]);
    return result.isNotEmpty
        ? {'id': result[0][0], 'data': result[0][1]}
        : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecords({
    int limit = 100,
    int offset = 0,
  }) async {
    final stmt = _db!.prepare('SELECT * FROM library_records LIMIT ? OFFSET ?');
    final result = stmt.select([limit, offset]);
    return result.map((row) => {'id': row[0], 'data': row[1]}).toList();
  }

  @override
  Future<bool> updateRecord(int id, Map<String, dynamic> data) async {
    final stmt = _db!.prepare(
      'UPDATE library_records SET data = ? WHERE id = ?',
    );
    stmt.execute([data.toString(), id]);
    return true; // todo check if row was updated
  }

  @override
  Future<void> beginTransaction() async {
    if (!_inTransaction) {
      _db!.execute('BEGIN TRANSACTION');
      _inTransaction = true;
    }
  }

  @override
  Future<void> commitTransaction() async {
    if (_inTransaction) {
      _db!.execute('COMMIT');
      _inTransaction = false;
    }
  }

  @override
  Future<void> rollbackTransaction() async {
    if (_inTransaction) {
      _db!.execute('ROLLBACK');
      _inTransaction = false;
    }
  }

  @override
  Future<void> close() async {
    _db!.dispose();
  }
}
