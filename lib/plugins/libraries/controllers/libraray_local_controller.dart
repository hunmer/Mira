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
    if (jsonData is List) {
      return jsonData
          .map((json) => Library.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    if (jsonData is Map && jsonData.isNotEmpty) {
      return [Library.fromJson(jsonData as Map<String, dynamic>)];
    }
    return [
      Library(
        id: "1753984872018",
        name: "人物素材",
        icon: "default",
        type: "network",
        socketServer: "ws://192.168.31.3:8081/",
        httpServer: "http://192.168.31.3:3000/",
        customFields: {
          'relativePath': "/library/",
          'smbPath': "//192.168.31.3/文件共享/",
        },
        createdAt: DateTime.now(),
      ),
      Library(
        id: "1753984872019",
        name: "影视素材",
        icon: "default",
        type: "network",
        socketServer: "ws://192.168.31.3:8081/",
        httpServer: "http://192.168.31.3:3000/",
        customFields: {
          'relativePath': "/library/",
          'smbPath': "//192.168.31.3/文件共享/",
        },
        createdAt: DateTime.now(),
      ),
      Library(
        id: "1753778329874",
        name: "本地人物素材",
        icon: "default",
        type: "network",
        socketServer: "ws://127.0.0.1:8081/",
        httpServer: "http://127.0.0.1:3000/",
        customFields: {},
        createdAt: DateTime.parse("2025-07-29T16:38:49.874467"),
      ),
    ];
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
