import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/controllers/library_data_interface.dart';
import 'package:mira/plugins/libraries/controllers/library_data_websocket.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/library_tabs_view.dart';
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

      final path = library.customFields['path'];
      if (library.isLocal && !plugin.server.connecting) {
        await plugin.server.start(path);
      }

      final channel = WebSocketChannel.connect(Uri.parse(library.url));
      dataInterfaces[libraryId] = LibraryDataWebSocket(channel, library);
      await channel.ready;
      return dataInterfaces[libraryId];
    }
    return null;
  }

  LibraryDataInterface? getLibraryInst(String libraryId) {
    return dataInterfaces[libraryId];
  }

  Future<LibraryDataInterface?> loadLibraryInst(Library library) async {
    if (getLibraryInst(library.id) == null) {
      return await loadLibrary(library);
    }
    return null;
  }

  void close() {}
}
