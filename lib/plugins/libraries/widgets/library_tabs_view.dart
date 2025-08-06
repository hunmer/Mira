import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mira/core/event/event_args.dart';
import 'package:mira/core/event/event_debounce.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/dock/dock_controller.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/app_sidebar_view.dart';
import 'package:mira/core/widgets/hotkey_settings_view.dart';
import 'package:mira/core/widgets/window_controls.dart';

class LibraryTabsView extends StatefulWidget {
  const LibraryTabsView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LibraryTabsViewState createState() => _LibraryTabsViewState();
}

class _LibraryTabsViewState extends State<LibraryTabsView> {
  late LibrariesPlugin _plugin;
  late DockController _dockController;
  final List<StreamSubscription> _subscriptions = [];
  final ValueNotifier<bool> _showSidebar = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;

    // 初始化dock controller
    _dockController = DockController(dockTabsId: 'main');
    _dockController.addListener(_onDockControllerChanged);

    // 异步初始化dock系统
    _initializeDock();

    init();
  }

  Future<void> _initializeDock() async {
    await _dockController.initializeStorage(_plugin.storage);
    await _dockController.initializeDockSystem(savedLayoutId: 'main_layout');
    // 初始化完成后刷新UI
    if (mounted) {
      setState(() {});
    }
  }

  void _onDockControllerChanged() {
    setState(() {
      // dock控制器状态变化时更新UI
    });
  }

  Future<void> init() async {
    final changedStream = EventDebouncer(
      duration: Duration(seconds: 1),
    ); // 广播更新节流

    _subscriptions.addAll([
      changedStream.stream.listen((EventArgs args) {
        //  服务器广播文件更新
        if (args is MapEventArgs) {
          final libraryId = args.item['libraryId'];
          // TODO: 更新对应的dock item
          print('Library updated: $libraryId');
        }
      }),
    ]);

    EventManager.instance.subscribe(
      'file::changed',
      (args) => changedStream.onCall(args),
    );
    EventManager.instance.subscribe(
      'tags::updated',
      (args) => changedStream.onCall(args),
    );
    EventManager.instance.subscribe(
      'folder::updated',
      (args) => changedStream.onCall(args),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _dockController.removeListener(_onDockControllerChanged);
    _dockController.dispose();
    _plugin.server?.stop();
  }

  // 检查是否为桌面端
  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
            Platform.isMacOS && _isDesktop
                ? Row(
                  children: [
                    const WindowControls(),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => _showSidebar.value = !_showSidebar.value,
                    ),
                  ],
                )
                : IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _showSidebar.value = !_showSidebar.value,
                ),
        leadingWidth: Platform.isMacOS && _isDesktop ? 140 : null,
        title:
            _isDesktop
                ? DragToMoveArea(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.drag_indicator,
                        size: 16,
                        color: Theme.of(
                          context,
                          // ignore: deprecated_member_use
                        ).textTheme.titleMedium?.color?.withOpacity(0.6),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(message: '拖拽此区域移动窗口', child: const Text('素材管理器')),
                    ],
                  ),
                )
                : const Text('素材管理器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Shortcut Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HotKeySettingsView(),
                ),
              );
            },
          ),
          // Windows/Linux 的窗口控制按钮在右侧
          if ((Platform.isWindows || Platform.isLinux) && _isDesktop)
            const WindowControls(),
        ],
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Row(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _showSidebar,
            builder: (context, showSidebar, child) {
              return showSidebar
                  ? Row(
                    children: [
                      AppSidebarView(),
                      const VerticalDivider(width: 1),
                    ],
                  )
                  : const SizedBox.shrink();
            },
          ),
          Expanded(
            child:
                _dockController.dockTabs?.buildDockingWidget(context) ??
                const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
