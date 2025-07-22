import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/library.dart';

class LibraryLocalDataController {
  final LibrariesPlugin plugin;
  late List<Library> libraries = [];

  LibraryLocalDataController(this.plugin);

  Future<void> init() async {
    libraries = await listLibraries();
  }

  /// 添加库记录
  Future<void> addLibrary(Library library) async {
    libraries.add(library);
    await plugin.storage.writeJson(
      'libraries',
      libraries.map((e) => e.toJson()).toList(),
    );
  }

  /// 删除库记录
  Future<void> deleteLibrary(String libraryId) async {
    libraries.removeWhere((lib) => lib.id == libraryId);
    await plugin.storage.writeJson(
      'libraries',
      libraries.map((e) => e.toJson()).toList(),
    );
  }

  /// 查找库记录
  Future<Library?> findLibrary(String libraryId) async {
    return libraries.firstWhere((lib) => lib.id == libraryId);
  }

  /// 列举所有库记录
  Future<List<Library>> listLibraries() async {
    final jsonData = await plugin.storage.readJson('libraries');
    if (jsonData == null) return [];
    if (jsonData is List) {
      return jsonData
          .map((json) => Library.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    if (jsonData is Map && jsonData.isNotEmpty) {
      return [Library.fromJson(jsonData as Map<String, dynamic>)];
    }
    return [];
  }

  /// 更新库记录
  Future<void> updateLibrary(Library library) async {
    final index = libraries.indexWhere((lib) => lib.id == library.id);
    if (index != -1) {
      libraries[index] = library;
      await plugin.storage.writeJson(
        'libraries',
        libraries.map((e) => e.toJson()).toList(),
      );
    }
  }
}
