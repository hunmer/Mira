import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mira/core/event/event_args.dart';
import 'package:mira/core/event/event_debounce.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/dock/dock_controller.dart';
import 'package:mira/dock/dock_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/app_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/library_list_view.dart';
import 'package:mira/plugins/libraries/widgets/library_dock_item.dart';
import '../models/library.dart';
import 'package:mira/core/widgets/hotkey_settings_view.dart';

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
    _dockController.initializeDockSystem(savedLayoutId: 'main_layout');

    init();
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

  Future<void> _openLibrary() async {
    final libraries = _plugin.dataController.libraries;
    final itemCount = libraries.length;
    if (itemCount == 1) {
      LibraryDockItem.addTab(libraries.first);
      return;
    }
    final selectedLibrary = await showDialog<Library>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Library'),
            content: SizedBox(
              width: double.maxFinite,
              child: LibraryListView(
                onSelected: (library) {
                  Navigator.pop(context, library);
                },
              ),
            ),
          ),
    );
    if (selectedLibrary != null) {
      LibraryDockItem.addTab(selectedLibrary);
    }
  }

  void _closeAllTabs() {
    DockManager.closeAllLibraryTabs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showSidebar.value = !_showSidebar.value,
        ),
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Library Tab',
            onPressed: () => _openLibrary(),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close All Tabs',
            onPressed: () => _closeAllTabs(),
          ),
        ],
        title: const Text('素材管理器'),
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
          Expanded(child: _dockController.dockTabs.buildDockingWidget(context)),
        ],
      ),
    );
  }
}
