import 'package:mira/plugins/libraries/services/server_event_manager.dart';

abstract class LibraryServerDataInterface {
  /// 获取事件管理器

  ServerEventManager getEventManager();

  /// 获取库ID
  String getLibraryId();

  /// 获取项目路径
  Future<String> getItemPath(item);

  /// 获取项目缩略图路径
  Future<String> getItemThumbPath(item, {bool checkExists = false});

  /// 初始化数据库连接
  Future<void> initialize();

  // 文件表操作
  Future<Map<String, dynamic>> createFile(Map<String, dynamic> fileData);
  Future<Map<String, dynamic>> createFileFromPath(
    String filePath,
    Map<String, dynamic> fileMeta,
  );
  Future<bool> updateFile(int id, Map<String, dynamic> fileData);
  Future<bool> deleteFile(int id, {bool moveToRecycleBin = false});
  Future<bool> recoverFile(int id);
  Future<Map<String, dynamic>?> getFile(int id);
  Future<dynamic> getFiles({
    String? select = '*',
    Map<String, dynamic>? filters,
  });

  // 文件夹表操作
  Future<int> createFolder(Map<String, dynamic> folderData);
  Future<bool> updateFolder(int id, Map<String, dynamic> folderData);
  Future<bool> deleteFolder(int id);
  Future<Map<String, dynamic>?> getFolder(int id);
  Future<List<Map<String, dynamic>>> getFolders({
    int? parentId,
    int limit = 100,
    int offset = 0,
  });

  // 标签表操作
  Future<int> createTag(Map<String, dynamic> tagData);
  Future<bool> updateTag(int id, Map<String, dynamic> tagData);
  Future<bool> deleteTag(int id);
  Future<Map<String, dynamic>?> getTag(int id);
  Future<List<Map<String, dynamic>>> getTags({
    int? parentId,
    int limit = 100,
    int offset = 0,
  });

  // 文件-文件夹关系操作
  Future<List<Map<String, dynamic>>> getFileFolders(int fileId);
  Future<bool> setFileFolders(int fileId, String folderId);

  // 文件-标签关系操作
  Future<List<Map<String, dynamic>>> getFileTags(int fileId);
  Future<bool> setFileTags(int fileId, List<String> tagIds);

  /// 开始事务
  Future<void> beginTransaction();

  /// 提交事务
  Future<void> commitTransaction();

  /// 回滚事务
  Future<void> rollbackTransaction();

  /// 关闭数据库连接
  Future<void> close();

  Future<List<Map<String, dynamic>>> getAllTags();

  Future<List<Map<String, dynamic>>> getAllFolders();
}
