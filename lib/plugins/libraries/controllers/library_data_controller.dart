import 'package:mira/plugins/libraries/controllers/library_data_interface.dart';
import 'package:mira/plugins/libraries/controllers/library_data_websocket.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LibraryDataController {
  final LibrariesPlugin plugin;
  final Map<String, LibraryDataInterface> dataInterfaces = {};
  LibraryDataController({required this.plugin});

  Future<LibraryDataInterface?> loadLibrary(Library library) async {
    if (!library.isLoading) {
      // 避免反复触发
      library.isLoading = true;
      final libraryId = library.id;
      print('loading library ${library.name}...');
      await plugin.foldersTagsController.createFolderCache(library.id);
      await plugin.foldersTagsController.createTagCache(library.id);

      if (library.isLocal && !plugin.server.connecting) {
        await plugin.server.start(library.customFields['path']);
      }

      final channel = WebSocketChannel.connect(Uri.parse(library.url));
      final inst = LibraryDataWebSocket(channel, library);
      dataInterfaces[libraryId] = inst;
      await channel.ready;
      return dataInterfaces[libraryId];
    }
    return null;
  }

  LibraryDataInterface? getLibraryInst(String libraryId) {
    return dataInterfaces[libraryId];
  }

  Future<LibraryDataInterface?> loadLibraryInst(Library library) async {
    LibraryDataInterface? inst = getLibraryInst(library.id);
    inst ??= await loadLibrary(library);
    if (inst != null) {
      inst.checkConnection(); // 校验与数据库的连接
    }
    return inst;
  }

  void close() {}
}
