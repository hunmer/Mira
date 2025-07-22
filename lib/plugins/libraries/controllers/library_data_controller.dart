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

  openLibrary(
    Library library,
    BuildContext context, {
    bool newTabView = true,
  }) async {
    final libraryId = library.id;
    print('Opening library ${library.name}...');
    await plugin.foldersTagsController.createFolderCache(library.id);
    await plugin.foldersTagsController.createTagCache(library.id);
    final path = library.customFields['path'];
    final url = path.startsWith('ws://') ? path : 'ws://localhost:8080';

    if (plugin.server.connecting) {
      await plugin.server.stop();
    }
    await plugin.server.start(path);
    final channel = WebSocketChannel.connect(Uri.parse(url));
    await channel.ready;
    dataInterfaces[libraryId] = LibraryDataWebSocket(channel, library);
    if (newTabView) {
      // 打开一个新的tabs页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LibraryTabsView(library: library),
        ),
      );
    }
  }

  LibraryDataInterface? getLibraryInst(libraryId) {
    if (libraryId is Library) {
      libraryId = libraryId.id;
    }
    return dataInterfaces[libraryId];
  }

  void close() {}
}
