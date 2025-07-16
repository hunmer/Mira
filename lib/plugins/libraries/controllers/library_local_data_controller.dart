import 'package:mira/core/storage/storage_manager.dart';
import 'package:mira/plugins/libraries/models/library.dart';

class LibraryLocalDataController {
  final StorageManager _storage;

  LibraryLocalDataController(this._storage);

  /// 添加库记录
  Future<void> addLibrary(Library library) async {
    final libraries = await listLibraries();
    libraries.add(library);
    await _storage.writeJson(
      'libraries',
      libraries.map((e) => e.toJson()).toList(),
    );
  }

  /// 删除库记录
  Future<void> removeLibrary(String libraryId) async {
    final libraries = await listLibraries();
    libraries.removeWhere((lib) => lib.id == libraryId);
    await _storage.writeJson(
      'libraries',
      libraries.map((e) => e.toJson()).toList(),
    );
  }

  /// 查找库记录
  Future<Library?> findLibrary(String libraryId) async {
    final libraries = await listLibraries();
    return libraries.firstWhere((lib) => lib.id == libraryId);
  }

  /// 查找所有库记录
  Future<List<Library>> findLibraries() async {
    return listLibraries();
  }

  /// 列举所有库记录
  Future<List<Library>> listLibraries() async {
    final jsonData = await _storage.readJson('libraries');
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
}
