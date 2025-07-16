import 'package:mira/core/config_manager.dart';
import 'package:mira/core/plugin_base.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'controllers/library_data_interface.dart';
import 'controllers/library_data_websocket.dart';

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
  final LibraryDataInterface dataController;
  LibrariesPlugin()
    : dataController = LibraryDataWebSocket(
        WebSocketChannel.connect(Uri.parse('ws://localhost:8080')),
      ) {
    // 初始化WebSocket连接
    // TODO: 实现实际的WebSocket连接
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();
  }

  @override
  Future<void> initialize() async {}

  @override
  void dispose() {
    dataController.close();
    // 其他清理逻辑
  }
}
