import 'package:mira/core/config_manager.dart';
import 'package:mira/core/plugin_base.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/controllers/localdata_controller.dart';
import 'package:mira/plugins/libraries/controllers/library_ui_controller.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'controllers/library_data_interface.dart';
import 'controllers/library_data_websocket.dart';
import 'services/websocket_server.dart';

class LibrariesPlugin extends PluginBase {
  static LibrariesPlugin? _instance;
  static LibrariesPlugin get instance {
    if (_instance == null) {
      _instance =
          PluginManager.instance.getPlugin('libraries') as LibrariesPlugin?;
      if (_instance == null) {
        throw StateError('LibrariesPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  String get id => 'libraries';
  late final LibraryUIController libraryUIController;
  late final LibraryDataInterface libraryController;
  late final LibraryLocalDataController dataController;

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();
  }

  @override
  Future<void> initialize() async {
    libraryUIController = LibraryUIController(this);
    dataController = LibraryLocalDataController(storage);
  }

  Future<void> setlibraryController(String connectionAddress) async {
    if (connectionAddress.startsWith('ws://')) {
      libraryController = LibraryDataWebSocket(
        WebSocketChannel.connect(Uri.parse(connectionAddress)),
      );
    } else {
      final server = WebSocketServer(8080);
      await server.start(connectionAddress);
      final channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8080'),
      );
      await channel.ready;
      libraryController = LibraryDataWebSocket(channel);
    }
  }

  @override
  void dispose() {
    libraryController?.close();
    // 其他清理逻辑
  }
}
