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
  Future<void> deleteFile(int id);
  Future<List<Map<String, dynamic>>> findFiles({Map<String, dynamic>? query});
  Future<List<LibraryFile>> getFiles();

  Future<void> addFolder(Map<String, dynamic> folder);
  Future<void> deleteFolder(String id);
  Future<List<Map<String, dynamic>>> findFolders({Map<String, dynamic>? query});

  Future<void> addTag(Map<String, dynamic> tag);
  Future<void> deleteTag(String id);
  Future<List<Map<String, dynamic>>> findTags({Map<String, dynamic>? query});

  void close();
}
