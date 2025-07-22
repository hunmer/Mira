// ignore_for_file: collection_methods_unrelated_type

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/services/plugins/thumb_generator.dart';
import 'package:mira/plugins/libraries/services/server_event_manager.dart';
import 'package:mira/plugins/libraries/services/websocket_server.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:xxh3/xxh3.dart';
import 'package:sqlite3/sqlite3.dart';
import 'library_server_data_interface.dart';

class LibraryServerDataSQLite5 implements LibraryServerDataInterface {
  Database? _db;
  bool _inTransaction = false;
  final WebSocketServer server;
  late final ServerEventManager eventManager;
  final Map<String, dynamic> config;
  LibraryServerDataSQLite5(this.server, this.config);

  @override
  Future<void> initialize() async {
    eventManager = ServerEventManager(server, this);
    ThumbGenerator(server, this);

    final dbPath = path.join(await getLibraryPath(), 'library_data.db');
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
        reference TEXT,
        url TEXT,
        path TEXT,
        thumb INTEGER DEFAULT 0,
        recycled  INTEGER DEFAULT 0,
        tags TEXT,
        FOREIGN KEY(folder_id) REFERENCES folders(id)
      )
    ''');

    // 创建文件夹表
    _db?.execute('''
      CREATE TABLE IF NOT EXISTS folders(
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        parent_id INTEGER,
        color INTEGER,
        icon TEXT,
        FOREIGN KEY(parent_id) REFERENCES folders(id)
      )
    ''');

    // 创建标签表
    _db?.execute('''
      CREATE TABLE IF NOT EXISTS tags(
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        parent_id INTEGER,
        color INTEGER,
        icon INTEGER,
        FOREIGN KEY(parent_id) REFERENCES tags(id)
      )
    ''');
  }

  // 文件表操作实现
  @override
  Future<Map<String, dynamic>> createFile(Map<String, dynamic> fileData) async {
    final stmt = _db!.prepare('''
      INSERT INTO files(
        name, created_at, imported_at, size, hash, 
        custom_fields, notes, stars, folder_id,
        reference, url, path, thumb, recycled, tags
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
      fileData['reference'],
      fileData['url'],
      fileData['path'],
      fileData['thumb'] ?? 0,
      fileData['recycled'] ?? 0,
      fileData['tags'],
    ]);
    stmt.dispose();
    return {'id': _db!.lastInsertRowId, ...fileData};
  }

  @override
  Future<bool> updateFile(int id, Map<String, dynamic> fileData) async {
    final fields = <String>[];
    final params = <dynamic>[];

    void addField(String key, dynamic value) {
      if (fileData.containsKey(key)) {
        fields.add('$key = ?');
        params.add(value);
      }
    }

    addField('name', fileData['name']);
    addField('created_at', fileData['created_at']);
    addField('imported_at', fileData['imported_at']);
    addField('size', fileData['size']);
    addField('hash', fileData['hash']);
    addField('custom_fields', fileData['custom_fields']);
    addField('notes', fileData['notes']);
    addField('stars', fileData['stars'] ?? 0);
    addField('tags', fileData['tags']);
    addField('folder_id', fileData['folder_id']);
    addField('reference', fileData['reference']);
    addField('url', fileData['url']);
    addField('path', fileData['path']);
    addField('thumb', fileData['thumb'] ?? 0);
    addField('recycled', fileData['recycled'] ?? 0);

    if (fields.isEmpty) return false;

    final query = 'UPDATE files SET ${fields.join(', ')} WHERE id = ?';
    params.add(id);

    final stmt = _db!.prepare(query);
    stmt.execute(params);
    stmt.dispose();
    return _db!.updatedRows > 0;
  }

  @override
  Future<bool> deleteFile(int id, {bool moveToRecycleBin = false}) async {
    if (moveToRecycleBin) {
      final stmt = _db!.prepare('UPDATE files SET recycled = 1 WHERE id = ?');
      stmt.execute([id]);
      stmt.dispose();
    } else {
      final stmt = _db!.prepare('DELETE FROM files WHERE id = ?');
      stmt.execute([id]);
      stmt.dispose();
    }
    return _db!.updatedRows > 0;
  }

  @override
  Future<bool> recoverFile(int id) async {
    final stmt = _db!.prepare('UPDATE files SET recycled = 0 WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
    return _db!.updatedRows > 0;
  }

  @override
  Future<Map<String, dynamic>?> getFile(int id) async {
    final stmt = _db!.prepare('SELECT * FROM files WHERE id = ? LIMIT 1');
    final result = stmt.select([id]);
    stmt.dispose();
    return result.isNotEmpty ? _rowToMap(result, result.first) : null;
  }

  @override
  Future<dynamic> getFiles({
    String? select = '*',
    Map<String, dynamic>? filters,
  }) async {
    var totalCount = 0;
    var whereClauses = <String>[];
    var params = <dynamic>[];
    var folderId = int.tryParse(filters?['folder']?.toString() ?? '') ?? 0;
    var tagIds = List<String>.from(filters?['tags'] ?? []);
    var limit = filters?['limit'] as int? ?? 100;
    var offset = filters?['offset'] as int? ?? 0;

    // 处理文件过滤条件
    if (filters != null) {
      if (filters['star'] != null) {
        whereClauses.add('stars >= ?');
        params.add(filters['star']);
      }

      if (filters['name'] != null) {
        whereClauses.add('name LIKE ?');
        params.add('%${filters['name']}%');
      }

      if (filters['dateRange'] != null) {
        final dateRange = filters['dateRange'] as DateTimeRange;
        whereClauses.add('created_at BETWEEN ? AND ?');
        params.addAll([
          dateRange.start.millisecondsSinceEpoch,
          dateRange.end.millisecondsSinceEpoch,
        ]);
      }

      if (filters['minSize'] != null) {
        whereClauses.add('size >= ?');
        params.add(filters['minSize'] * 1024); // 转换为字节
      }

      if (filters['maxSize'] != null) {
        whereClauses.add('size <= ?');
        params.add(filters['maxSize'] * 1024); // 转换为字节
      }

      if (filters['minRating'] != null) {
        whereClauses.add('stars >= ?');
        params.add(filters['minRating']);
      }

      if (folderId != 0) {
        whereClauses.add('folder_id = ?');
        params.add(folderId);
      }
      if (tagIds != null && tagIds.isNotEmpty) {
        whereClauses.add('''
        (SELECT COUNT(*) FROM json_each(tags) 
         WHERE value IN (${List.filled(tagIds.length, '?').join(',')})
        ) = ${tagIds.length}
      ''');
        params.addAll(tagIds);
      }
    }

    final where =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final query = 'SELECT $select FROM files $where LIMIT ? OFFSET ?';
    params.addAll([limit, offset]);
    // 添加分页信息到返回结果
    final countQuery = 'SELECT COUNT(*) FROM files $where';
    final countStmt = _db!.prepare(countQuery);
    final countResult = countStmt.select(params.sublist(0, params.length - 2));
    totalCount = countResult.first[0] as int;
    countStmt.dispose();

    final stmt = _db!.prepare(query);
    final result = stmt.select(params);
    stmt.dispose();
    return {
      'result': result.map((row) => _rowToMap(result, row)).toList(),
      'limit': limit,
      'offset': offset,
      'total': totalCount,
    };
  }

  // 文件夹表操作实现
  @override
  Future<int> createFolder(Map<String, dynamic> folderData) async {
    final stmt = _db!.prepare('''
      INSERT INTO folders(id, title, parent_id, color, icon)
      VALUES (?, ?, ?, ?, ?)
    ''');
    stmt.execute([
      folderData['id'],
      folderData['title'],
      folderData['parent_id'],
      folderData['color'],
      folderData['icon'],
    ]);
    stmt.dispose();
    return _db!.lastInsertRowId;
  }

  @override
  Future<bool> updateFolder(int id, Map<String, dynamic> folderData) async {
    final stmt = _db!.prepare('''
      UPDATE folders SET
        title = ?, parent_id = ?, color = ?, icon = ?
      WHERE id = ?
    ''');
    stmt.execute([
      folderData['title'],
      folderData['parent_id'],
      folderData['color'],
      folderData['icon'],
      id,
    ]);
    stmt.dispose();
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
    stmt.dispose();
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
    stmt.dispose();
    return result.map((row) => _rowToMap(result, row)).toList();
  }

  // 标签表操作实现
  @override
  Future<int> createTag(Map<String, dynamic> tagData) async {
    final stmt = _db!.prepare('''
      INSERT INTO tags(id, title, parent_id, color, icon)
      VALUES (?, ?, ?, ?, ?)
    ''');
    stmt.execute([
      tagData['id'],
      tagData['title'],
      tagData['parent_id'],
      tagData['color'],
      tagData['icon'],
    ]);
    stmt.dispose();
    return _db!.lastInsertRowId;
  }

  @override
  Future<bool> updateTag(int id, Map<String, dynamic> tagData) async {
    final stmt = _db!.prepare('''
      UPDATE tags SET
        title = ?, parent_id = ?, color = ?, icon = ?
      WHERE id = ?
    ''');
    stmt.execute([
      tagData['title'],
      tagData['parent_id'],
      tagData['color'],
      tagData['icon'],
      id,
    ]);
    stmt.dispose();
    return _db!.updatedRows > 0;
  }

  @override
  Future<bool> deleteTag(int id) async {
    // 递归删除子标签
    final children = await getTags(parentId: id);
    for (final child in children) {
      await deleteTag(child['id']);
    }

    // 删除标签
    final stmt = _db!.prepare('DELETE FROM tags WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
    return _db!.updatedRows > 0;
  }

  @override
  Future<Map<String, dynamic>?> getTag(int id) async {
    final stmt = _db!.prepare('SELECT * FROM tags WHERE id = ? LIMIT 1');
    final result = stmt.select([id]);
    stmt.dispose();
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
    stmt.dispose();
    return result.map((row) => _rowToMap(result, row)).toList();
  }

  // 辅助方法：将数据库行转换为Map
  Map<String, dynamic> _rowToMap(ResultSet result, row) {
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
  Future<Map<String, dynamic>> createFileFromPath(
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
      'path': file.path,
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

  @override
  Future<List<Map<String, dynamic>>> getFileFolders(int fileId) async {
    final stmt = _db!.prepare('''
      SELECT f.* FROM folders f
      JOIN files fi ON fi.folder_id = f.id
      WHERE fi.id = ?
    ''');
    final result = stmt.select([fileId]);
    stmt.dispose();
    return result.map((row) => _rowToMap(result, row)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getFileTags(int fileId) async {
    final stmt = _db!.prepare('SELECT tags FROM files WHERE id = ?');
    final result = stmt.select([fileId]);
    stmt.dispose();
    if (result.isEmpty) return [];

    final tagsStr = result.first[0] as String?;
    if (tagsStr == null || tagsStr.isEmpty) return [];

    try {
      final tagIds =
          jsonDecode(
            tagsStr,
          ).where((id) => id.isNotEmpty).map(int.parse).toList();
      if (tagIds.isEmpty) return [];

      final tagStmt = _db!.prepare('''
        SELECT * FROM tags WHERE id IN (${List.filled(tagIds.length, '?').join(',')})
      ''');
      final tagResult = tagStmt.select(tagIds);
      return tagResult.map((row) => _rowToMap(tagResult, row)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> setFileFolders(int fileId, String folderId) async {
    if (folderId.isEmpty) return false;

    try {
      await beginTransaction();

      // 更新文件的folder_id
      final stmt = _db!.prepare('UPDATE files SET folder_id = ? WHERE id = ?');
      stmt.execute([folderId, fileId]);
      stmt.dispose();

      await commitTransaction();
      return _db!.updatedRows > 0;
    } catch (e) {
      await rollbackTransaction();
      rethrow;
    }
  }

  @override
  Future<bool> setFileTags(int fileId, List<String> tagIds) async {
    try {
      await beginTransaction();

      // 更新files表中的tags字段，使用JSON数组格式
      final stmt = _db!.prepare('UPDATE files SET tags = ? WHERE id = ?');
      stmt.execute([jsonEncode(tagIds), fileId]);
      stmt.dispose();

      await commitTransaction();
      return _db!.updatedRows > 0;
    } catch (e) {
      await rollbackTransaction();
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllTags() async {
    final stmt = _db!.prepare('SELECT * FROM tags');
    final result = stmt.select();
    stmt.dispose();
    return result.map((row) => _rowToMap(result, row)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllFolders() async {
    final stmt = _db!.prepare('SELECT * FROM folders');
    final result = stmt.select();
    stmt.dispose();
    return result.map((row) => _rowToMap(result, row)).toList();
  }

  Future<String> getLibraryPath() async {
    if (Platform.isAndroid) {
      return (await getApplicationDocumentsDirectory()).path;
    }
    return config['customFields']['path'];
  }

  @override
  String getLibraryId() {
    return config['id'];
  }

  @override
  Future<String> getItemPath(item) async {
    return path.join((await getLibraryPath()), item['hash']);
  }

  @override
  Future<String> getItemThumbPath(item) async {
    return path.join(await getItemPath(item), 'preview.png');
  }

  @override
  ServerEventManager getEventManager() {
    return eventManager;
  }
}
