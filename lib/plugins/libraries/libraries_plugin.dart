import 'package:mira/core/config_manager.dart';
import 'package:mira/core/plugin_base.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/controllers/folders_controller.dart';
import 'package:mira/plugins/libraries/controllers/libraray_controller.dart';
import 'package:mira/plugins/libraries/controllers/libraray_controller.dart';
import 'package:mira/plugins/libraries/controllers/library_data_controller.dart';
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
  late final LibraryDataController libraryController;
  late final LibraryLocalDataController dataController;
  late final WebSocketServer server;
  late final FoldersController foldersController;

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
    dataController = LibraryLocalDataController(this);
    foldersController = FoldersController();
    await foldersController.init();
    libraryController = LibraryDataController(plugin: this);
    server = WebSocketServer(8080);
  }

  @override
  void dispose() {
    libraryController?.close();
    server?.stop();
  }
}
