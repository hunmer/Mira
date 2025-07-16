abstract class LibraryServerDataInterface {
  /// 初始化数据库连接
  Future<void> initialize(Map<String, dynamic> config);

  /// 新增记录
  Future<int> createRecord(Map<String, dynamic> data);

  /// 删除记录
  Future<bool> deleteRecord(int id);

  /// 更新记录
  Future<bool> updateRecord(int id, Map<String, dynamic> data);

  /// 查询记录
  Future<Map<String, dynamic>?> getRecord(int id);

  /// 批量查询记录
  Future<List<Map<String, dynamic>>> getRecords({
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
