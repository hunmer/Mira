abstract class LibraryServerDataInterface {
  /// 初始化数据库连接
  Future<void> initialize(Map<String, dynamic> config);

  // 文件表操作
  Future<int> createFile(Map<String, dynamic> fileData);
  Future<bool> updateFile(int id, Map<String, dynamic> fileData);
  Future<bool> deleteFile(int id);
  Future<Map<String, dynamic>?> getFile(int id);
  Future<List<Map<String, dynamic>>> getFiles({
    List<int>? folderIds,
    List<int>? tagIds,
    int? minStars,
    int limit = 100,
    int offset = 0,
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

  /// 开始事务
  Future<void> beginTransaction();

  /// 提交事务
  Future<void> commitTransaction();

  /// 回滚事务
  Future<void> rollbackTransaction();

  /// 关闭数据库连接
  Future<void> close();
}
