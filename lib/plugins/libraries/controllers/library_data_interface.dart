import 'package:mira/plugins/libraries/models/file.dart';

abstract class LibraryDataInterface {
  Future<void> addLibrary(Map<String, dynamic> library);
  Future<void> deleteLibrary(String id);
  Future<List<Map<String, dynamic>>> findLibraries({
    Map<String, dynamic>? query,
  });
  Future<void> updateLibrary(String id, Map<String, dynamic> updates);
  Future<void> addFile(Map<String, dynamic> file);
  Future<void> addFileFromPath(String filePath);
  Future<void> deleteFile(int id, {bool moveToRecycleBin = false});
  Future<void> recoverFile(int id);
  Future<dynamic> findFiles({Map<String, dynamic>? query});
  Future<List<LibraryFile>> getFiles();

  Future<void> addFolder(Map<String, dynamic> folder);
  Future<void> deleteFolder(String id);
  Future<List<Map<String, dynamic>>> findFolders({Map<String, dynamic>? query});
  Future<List<Map<String, dynamic>>> getFolders();
  Future<List<Map<String, dynamic>>> getAllFolders();
  Future<List<Map<String, dynamic>>> getAllTags();
  Future<void> updateFolder({required String id, bool? deleted, String? name});

  Future<void> addTag(Map<String, dynamic> tag);
  Future<void> deleteTag(String id);
  Future<List<Map<String, dynamic>>> findTags({Map<String, dynamic>? query});
  Future<List<Map<String, dynamic>>> getTags();

  Future<LibraryFile> getFile(int id);
  Future<void> updateFile(int id, Map<String, dynamic> updates);
  Future<List<Map<String, dynamic>>> getFileFolders(int fileId);
  Future<List<Map<String, dynamic>>> getFileTags(int fileId);
  Future<void> setFileFolders(int fileId, String folderId);
  Future<void> setFileTags(int fileId, List<String> tagIds);
  Future<String> getFolderTitle(String folderId);
  Future<String> getTagTitle(String tagId);

  void close();
}
