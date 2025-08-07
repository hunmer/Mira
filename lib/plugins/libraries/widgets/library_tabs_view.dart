import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/dock/dock_controller.dart';
import 'package:mira/dock/dock_events.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/app_sidebar_view.dart';
import 'package:mira/core/widgets/hotkey_settings_view.dart';
import 'package:mira/core/widgets/window_controls.dart';
import 'package:rxdart/rxdart.dart';

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
  final ValueNotifier<int> _dockUpdateNotifier = ValueNotifier<int>(0);
  late BehaviorSubject<void> _dockChangeSubject;

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;

    // 初始化防抖 Subject
    _dockChangeSubject = BehaviorSubject<void>();

    // 设置防抖监听
    _subscriptions.add(
      _dockChangeSubject.debounceTime(Duration(milliseconds: 500)).listen((
        event,
      ) {
        _dockUpdateNotifier.value = _dockUpdateNotifier.value + 1;
      }),
    );

    // 初始化dock controller
    _dockController = DockController(dockTabsId: 'main');
    // 监听 dock controller 的事件流
    _subscriptions.add(
      _dockController.eventStream.listen(_onDockControllerChanged),
    );

    // 异步初始化dock系统
    _initializeDock();
  }

  Future<void> _initializeDock() async {
    await _dockController.initializeStorage(_plugin.storage);
    await _dockController.initializeDockSystem();
  }

  void _onDockControllerChanged(DockEvent event) {
    print('tabs_view changed: ${event.type}');
    switch (event.type) {
      case DockEventType.tabClosed:
      case DockEventType.tabCreated:
      case DockEventType.layoutLoaded:
        _dockChangeSubject.add(null);
        break;

      default:
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _dockController.dispose();
    _dockChangeSubject.close();
    _showSidebar.dispose();
    _dockUpdateNotifier.dispose();
    _plugin.server?.stop();
  }

  @override
  Widget build(BuildContext context) {
    print('libray_tabs_view build');
    return Scaffold(
      appBar: AppBar(
        leading:
            Platform.isMacOS && isDesktop()
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
        leadingWidth: Platform.isMacOS && isDesktop() ? 140 : null,
        title:
            isDesktop()
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
          if (isDesktop() && (Platform.isWindows || Platform.isLinux))
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
            child: ValueListenableBuilder<int>(
              valueListenable: _dockUpdateNotifier,
              builder: (context, value, child) {
                return _dockController.dockTabs?.buildDockingWidget(context) ??
                    const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
