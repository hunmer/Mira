import 'dart:io';
import 'dart:typed_data';
import 'package:xxh3/xxh3.dart';
import 'package:sqlite3/sqlite3.dart';
import 'library_server_data_interface.dart';

class LibraryServerDataSQLite5 implements LibraryServerDataInterface {
  Database? _db;
  bool _inTransaction = false;

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    final dbPath = config['path'] as String;
    _db = sqlite3.open(dbPath);

    // 创建文件表
    _db?.execute('''
      CREATE TABLE IF NOT EXISTS files(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        imported_at INTEGER NOT NULL,
        size INTEGER NOT NULL,
        hash TEXT NOT NULL,
        custom_fields TEXT,
        notes TEXT,
        stars INTEGER DEFAULT 0,
        folder_id INTEGER,
        FOREIGN KEY(folder_id) REFERENCES folders(id)
      )
    ''');

    // 创建文件标签关联表
    _db?.execute('''
      CREATE TABLE IF NOT EXISTS file_tags(
        file_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY(file_id, tag_id),
        FOREIGN KEY(file_id) REFERENCES files(id),
        FOREIGN KEY(tag_id) REFERENCES tags(id)
      )
    ''');

    // 创建文件夹表
    _db?.execute('''
      CREATE TABLE IF NOT EXISTS folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        parent_id INTEGER,
        notes TEXT,
        color INTEGER,
        icon TEXT,
        FOREIGN KEY(parent_id) REFERENCES folders(id)
      )
    ''');

    // 创建标签表
    _db?.execute('''
      CREATE TABLE IF NOT EXISTS tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        parent_id INTEGER,
        notes TEXT,
        color INTEGER,
        icon TEXT,
        FOREIGN KEY(parent_id) REFERENCES tags(id)
      )
    ''');
  }

  // 文件表操作实现
  @override
  Future<int> createFile(Map<String, dynamic> fileData) async {
    final stmt = _db!.prepare('''
      INSERT INTO files(
        name, created_at, imported_at, size, hash, 
        custom_fields, notes, stars, folder_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');
    stmt.execute([
      fileData['name'],
      fileData['created_at'],
      fileData['imported_at'],
      fileData['size'],
      fileData['hash'],
      fileData['custom_fields'],
      fileData['notes'],
      fileData['stars'] ?? 0,
      fileData['folder_id'],
    ]);
    return _db!.lastInsertRowId;
  }

  @override
  Future<bool> updateFile(int id, Map<String, dynamic> fileData) async {
    final stmt = _db!.prepare('''
      UPDATE files SET
        name = ?, created_at = ?, imported_at = ?, size = ?, hash = ?,
        custom_fields = ?, notes = ?, stars = ?, folder_id = ?
      WHERE id = ?
    ''');
    stmt.execute([
      fileData['name'],
      fileData['created_at'],
      fileData['imported_at'],
      fileData['size'],
      fileData['hash'],
      fileData['custom_fields'],
      fileData['notes'],
      fileData['stars'] ?? 0,
      fileData['folder_id'],
      id,
    ]);
    return _db!.updatedRows > 0;
  }

  @override
  Future<bool> deleteFile(int id) async {
    // 先删除关联的标签关系
    _db!.execute('DELETE FROM file_tags WHERE file_id = ?', [id]);
    // 再删除文件记录
    final stmt = _db!.prepare('DELETE FROM files WHERE id = ?');
    stmt.execute([id]);
    return _db!.updatedRows > 0;
  }

  @override
  Future<Map<String, dynamic>?> getFile(int id) async {
    final stmt = _db!.prepare('SELECT * FROM files WHERE id = ? LIMIT 1');
    final result = stmt.select([id]);
    return result.isNotEmpty ? _rowToMap(result, result.first) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getFiles({
    List<int>? folderIds,
    List<int>? tagIds,
    int? minStars,
    int limit = 100,
    int offset = 0,
  }) async {
    var whereClauses = <String>[];
    var params = <dynamic>[];

    if (folderIds != null && folderIds.isNotEmpty) {
      whereClauses.add(
        'folder_id IN (${List.filled(folderIds.length, '?').join(',')})',
      );
      params.addAll(folderIds);
    }

    if (tagIds != null && tagIds.isNotEmpty) {
      whereClauses.add('''
        id IN (
          SELECT file_id FROM file_tags 
          WHERE tag_id IN (${List.filled(tagIds.length, '?').join(',')})
        )
      ''');
      params.addAll(tagIds);
    }

    if (minStars != null) {
      whereClauses.add('stars >= ?');
      params.add(minStars);
    }

    final where =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final query = 'SELECT * FROM files $where LIMIT ? OFFSET ?';
    params.addAll([limit, offset]);

    final stmt = _db!.prepare(query);
    final result = stmt.select(params);
    return result.map((row) => _rowToMap(result, row)).toList();
  }

  // 文件夹表操作实现
  @override
  Future<int> createFolder(Map<String, dynamic> folderData) async {
    final stmt = _db!.prepare('''
      INSERT INTO folders(title, parent_id, notes, color, icon)
      VALUES (?, ?, ?, ?, ?)
    ''');
    stmt.execute([
      folderData['title'],
      folderData['parent_id'],
      folderData['notes'],
      folderData['color'],
      folderData['icon'],
    ]);
    return _db!.lastInsertRowId;
  }

  @override
  Future<bool> updateFolder(int id, Map<String, dynamic> folderData) async {
    final stmt = _db!.prepare('''
      UPDATE folders SET
        title = ?, parent_id = ?, notes = ?, color = ?, icon = ?
      WHERE id = ?
    ''');
    stmt.execute([
      folderData['title'],
      folderData['parent_id'],
      folderData['notes'],
      folderData['color'],
      folderData['icon'],
      id,
    ]);
    return _db!.updatedRows > 0;
  }

  @override
  Future<bool> deleteFolder(int id) async {
    // 递归删除子文件夹
    final children = await getFolders(parentId: id);
    for (final child in children) {
      await deleteFolder(child['id']);
    }

    // 更新文件的folder_id为null
    _db!.execute('UPDATE files SET folder_id = NULL WHERE folder_id = ?', [id]);

    // 删除文件夹
    final stmt = _db!.prepare('DELETE FROM folders WHERE id = ?');
    stmt.execute([id]);
    return _db!.updatedRows > 0;
  }

  @override
  Future<Map<String, dynamic>?> getFolder(int id) async {
    final stmt = _db!.prepare('SELECT * FROM folders WHERE id = ? LIMIT 1');
    final result = stmt.select([id]);
    return result.isNotEmpty ? _rowToMap(result, result.first) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getFolders({
    int? parentId,
    int limit = 100,
    int offset = 0,
  }) async {
    final where =
        parentId != null ? 'WHERE parent_id = ?' : 'WHERE parent_id IS NULL';
    final query = 'SELECT * FROM folders $where LIMIT ? OFFSET ?';
    final params =
        parentId != null ? [parentId, limit, offset] : [limit, offset];

    final stmt = _db!.prepare(query);
    final result = stmt.select(params);
    return result.map((row) => _rowToMap(result, row)).toList();
  }

  // 标签表操作实现
  @override
  Future<int> createTag(Map<String, dynamic> tagData) async {
    final stmt = _db!.prepare('''
      INSERT INTO tags(title, parent_id, notes, color, icon)
      VALUES (?, ?, ?, ?, ?)
    ''');
    stmt.execute([
      tagData['title'],
      tagData['parent_id'],
      tagData['notes'],
      tagData['color'],
      tagData['icon'],
    ]);
    return _db!.lastInsertRowId;
  }

  @override
  Future<bool> updateTag(int id, Map<String, dynamic> tagData) async {
    final stmt = _db!.prepare('''
      UPDATE tags SET
        title = ?, parent_id = ?, notes = ?, color = ?, icon = ?
      WHERE id = ?
    ''');
    stmt.execute([
      tagData['title'],
      tagData['parent_id'],
      tagData['notes'],
      tagData['color'],
      tagData['icon'],
      id,
    ]);
    return _db!.updatedRows > 0;
  }

  @override
  Future<bool> deleteTag(int id) async {
    // 递归删除子标签
    final children = await getTags(parentId: id);
    for (final child in children) {
      await deleteTag(child['id']);
    }

    // 删除文件标签关联
    _db!.execute('DELETE FROM file_tags WHERE tag_id = ?', [id]);

    // 删除标签
    final stmt = _db!.prepare('DELETE FROM tags WHERE id = ?');
    stmt.execute([id]);
    return _db!.updatedRows > 0;
  }

  @override
  Future<Map<String, dynamic>?> getTag(int id) async {
    final stmt = _db!.prepare('SELECT * FROM tags WHERE id = ? LIMIT 1');
    final result = stmt.select([id]);
    return result.isNotEmpty ? _rowToMap(result, result.first) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getTags({
    int? parentId,
    int limit = 100,
    int offset = 0,
  }) async {
    final where =
        parentId != null ? 'WHERE parent_id = ?' : 'WHERE parent_id IS NULL';
    final query = 'SELECT * FROM tags $where LIMIT ? OFFSET ?';
    final params =
        parentId != null ? [parentId, limit, offset] : [limit, offset];

    final stmt = _db!.prepare(query);
    final result = stmt.select(params);
    return result.map((row) => _rowToMap(result, row)).toList();
  }

  // 辅助方法：将数据库行转换为Map
  Map<String, dynamic> _rowToMap(ResultSet result, Row row) {
    final map = <String, dynamic>{};
    for (var i = 0; i < result.columnNames.length; i++) {
      map[result.columnNames[i]] = row[i];
    }
    return map;
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

  @override
  Future<int> createFileFromPath(
    String filePath,
    Map<String, dynamic> fileMeta,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }

    // 获取文件基础信息
    final stat = await file.stat();
    final hash = await _calculateFileHash(file);

    // 构建文件数据
    final fileData = {
      'name': file.path.split(Platform.pathSeparator).last,
      'created_at': stat.modified.millisecondsSinceEpoch,
      'imported_at': DateTime.now().millisecondsSinceEpoch,
      'size': stat.size,
      'hash': hash,
      ...fileMeta, // 合并传入的元数据
    };

    // 使用现有的createFile方法插入记录
    return createFile(fileData);
  }

  // 计算文件哈希值 (使用XXH3算法)
  Future<String> _calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final hash = xxh3(Uint8List.fromList(bytes));
    return hash.toRadixString(16); // 返回16进制字符串
  }
}
