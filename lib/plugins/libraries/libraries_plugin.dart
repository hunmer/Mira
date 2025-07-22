import 'package:mira/core/config_manager.dart';
import 'package:mira/core/plugin_base.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/controllers/folders_tags_cache.dart';
import 'package:mira/plugins/libraries/controllers/libraray_local_controller.dart';
import 'package:mira/plugins/libraries/controllers/library_data_controller.dart';
import 'package:mira/plugins/libraries/controllers/library_ui_controller.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager.dart';
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

  setTabManager(LibraryTabManager tabManager) {
    this.tabManager = tabManager;
  }

  @override
  String get id => 'libraries';
  late final LibraryUIController libraryUIController; // 弹出组件
  late final LibraryDataController libraryController; // 数据库
  late final LibraryLocalDataController dataController; // 本地数据
  late final WebSocketServer server; // 后端服务器
  late final LibraryTabManager tabManager; // 标签视图管理器
  late final FoldersTagsCache foldersTagsController; // 文件夹标签缓存

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
    await dataController.init();
    foldersTagsController = FoldersTagsCache();
    await foldersTagsController.init();
    libraryController = LibraryDataController(plugin: this);
    server = WebSocketServer(8080);
  }

  void dispose() {
    libraryController.close();
    server.stop();
  }
}
