import 'package:flutter/foundation.dart';
import 'package:mira/core/config_manager.dart';
import 'package:mira/core/plugin_base.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/controllers/folders_tags_cache.dart';
import 'package:mira/plugins/libraries/controllers/libraray_local_controller.dart';
import 'package:mira/plugins/libraries/controllers/library_data_controller.dart';
import 'package:mira/plugins/libraries/controllers/library_ui_controller.dart';
import 'package:mira/plugins/libraries/widgets/library_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager_dock_adapter.dart';
import 'package:background_downloader/background_downloader.dart';
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
  late final LibraryUIController libraryUIController; // 弹出组件
  late final LibraryDataController libraryController; // 数据库
  late final LibraryLocalDataController dataController; // 本地数据
  WebSocketServer? server; // 后端服务器 (Web平台不启用)
  late final FoldersTagsCache foldersTagsController; // 文件夹标签缓存
  late final LibrarySidebarView sidebarController;
  late final FileDownloader fileDownloader;
  late final LibraryTabManagerDockAdapter tabManager; // dock适配器

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
    tabManager = LibraryTabManagerDockAdapter(); // 初始化适配器
    libraryController = LibraryDataController(plugin: this);
    // 仅在非Web平台启用WebSocketServer
    if (!kIsWeb) {
      server = WebSocketServer(8080);
    }
    fileDownloader = FileDownloader();
    await fileDownloader.trackTasks();
    fileDownloader.configureNotification(
      running: TaskNotification('Downloading', 'file: {filename}'),
      progressBar: true,
    );
  }

  void dispose() {
    libraryController.close();
    server?.stop(); // 仅在server存在时停止
  }
}
