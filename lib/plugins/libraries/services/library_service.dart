import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';

class LibraryService {
  final LibraryServerDataInterface dbService;

  LibraryService(this.dbService);

  // Connection related
  Future<Map<String, dynamic>> connectLibrary(
    Map<String, dynamic> config,
  ) async {
    final tags = await dbService.getAllTags();
    final folders = await dbService.getAllFolders();

    return {
      'libraryId': dbService.getLibraryId(),
      'tags': tags,
      'folders': folders,
    };
  }

  // File operations
  Future<Map<String, dynamic>> getFiles({
    String select = '*',
    Map<String, dynamic>? filters,
  }) async {
    final result = await dbService.getFiles(select: select, filters: filters);
    for (var record in result['result']) {
      record['thumb'] = await dbService.getItemThumbPath(record);
    }
    return result;
  }

  Future<Map<String, dynamic>?> getFile(int id) async {
    final record = await dbService.getFile(id);
    if (record != null) {
      record['thumb'] = await dbService.getItemThumbPath(record);
    }
    return record;
  }

  Future<int> createFile(Map<String, dynamic> data) async {
    if (data.containsKey('path')) {
      final fileMeta = {
        'reference': data['reference'],
        'path': data['path'],
        ...data,
      };
      final item = await dbService.createFileFromPath(data['path'], fileMeta);
      return item['id'];
    }
    throw UnimplementedError('Binary upload not yet implemented');
  }

  // Folder operations
  Future<List<dynamic>> getFolders({int limit = 100, int offset = 0}) async {
    return await dbService.getFolders(limit: limit, offset: offset);
  }

  Future<int> createFolder(Map<String, dynamic> data) async {
    return await dbService.createFolder(data);
  }

  // Tag operations
  Future<List<dynamic>> getTags({int limit = 100, int offset = 0}) async {
    return await dbService.getTags(limit: limit, offset: offset);
  }

  Future<int> createTag(Map<String, dynamic> data) async {
    return await dbService.createTag(data);
  }

  // Other shared operations...
}
