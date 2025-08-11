import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/dock/dock_theme.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/examples/dock_insert_mode.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/app_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager_dock.dart';
import 'package:mira/core/widgets/hotkey_settings_view.dart';
import 'package:mira/core/widgets/window_controls.dart';
// Added for Docking main interface
import 'package:mira/dock/examples/dock_manager.dart';
import 'package:mira/dock/examples/docking_persistence_logic.dart';
import 'package:mira/dock/examples/widgets/dock_item_registrar.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';
import 'package:mira/multi_split_view/lib/multi_split_view.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:mira/dock/debug_layout_preset_dialog.dart';

class LibraryTabsView extends StatefulWidget {
  const LibraryTabsView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LibraryTabsViewState createState() => _LibraryTabsViewState();
}

class _LibraryTabsViewState extends State<LibraryTabsView> {
  late LibrariesPlugin _plugin;
  final List<StreamSubscription> _subscriptions = [];
  final ValueNotifier<bool> _showSidebar = ValueNotifier(false);

  // Docking related state
  late DockManager _dockManager;
  late DockingPersistenceLogic _dockLogic;
  bool _loadingDock = true;

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
    _initDocking();
  }

  Future<void> _initDocking() async {
    _dockManager = DockManager(id: 'libraries_main_layout', autoSave: true);
    _dockLogic = DockingPersistenceLogic(
      manager: _dockManager,
      context: context,
    );
    LibraryTabManager.setGlobalDockManager(_dockManager);
    DockItemRegistrar.registerAllComponents(_dockManager);
    final restored = await _dockManager.restoreFromFile();
    if (!restored) {
      _dockLogic.createDefaultLayout();
    }

    if (mounted) {
      setState(() => _loadingDock = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _showSidebar.dispose();
    _plugin.server?.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
            isDesktop() && Platform.isMacOS
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
        leadingWidth: isDesktop() && Platform.isMacOS ? 140 : null,
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
          IconButton(
            icon: const Icon(Icons.library_add),
            tooltip: '打开素材库',
            onPressed: () {
              _plugin.libraryUIController.openLibrary(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            tooltip: '选择位置打开素材库',
            onPressed: () {
              _plugin.libraryUIController.openLibrary(
                context,
                insertMode: DockInsertMode.choose,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            tooltip: '布局存储管理器',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => DebugLayoutPresetDialog(manager: _dockManager),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: '添加组件',
            onPressed: () => _dockLogic.showAddComponentTab(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '重置',
            onPressed: () {
              _dockLogic.clearLayout();
              _dockLogic.createDefaultLayout();
              // _dockLogic.createTest();
            },
          ),
          // Windows/Linux 的窗口控制按钮在右侧
          if (isDesktop() && (Platform.isWindows || Platform.isLinux))
            const WindowControls(),
        ],
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body:
          _loadingDock
              ? const Center(child: CircularProgressIndicator())
              : Row(
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
                    child: TabbedViewTheme(
                      data: DockTheme.createCustomThemeData(context),
                      child: Container(
                        child: MultiSplitViewTheme(
                          data: MultiSplitViewThemeData(
                            dividerPainter: DividerPainters.grooved1(
                              color: Colors.indigo[100]!,
                              highlightedColor: Colors.indigo[900]!,
                            ),
                          ),
                          child: Docking(
                            layout: _dockManager.layout,
                            draggable: true,
                            autoBreakpoints: true,
                            breakpoints: const ScreenBreakpoints(
                              desktop: 800,
                              tablet: 600,
                              watch: 200,
                            ),
                            defaultLayout: () {
                              return DockingLayout(
                                root: _dockLogic.getDefaultLayout(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
