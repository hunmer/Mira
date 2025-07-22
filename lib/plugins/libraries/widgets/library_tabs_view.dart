import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/core/utils/utils.dart' as Utils;
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/app_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/library_list_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tabs_context_menu.dart'
    // ignore: library_prefixes
    as LibraryContextMenu;
import 'package:mira/plugins/libraries/widgets/library_content_view.dart';
import 'package:mira/plugins/libraries/widgets/library_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager.dart';
import 'package:mira/views/library_tabs_empty_view.dart';
import '../models/library.dart';
import 'package:dynamic_tabbar/dynamic_tabbar.dart';

class LibraryTabsView extends StatefulWidget {
  final Library? library;

  const LibraryTabsView({super.key, this.library});

  @override
  // ignore: library_private_types_in_public_api
  _LibraryTabsViewState createState() => _LibraryTabsViewState();
}

class _LibraryTabsViewState extends State<LibraryTabsView> {
  late final LibraryTabManager _tabManager;
  late LibrariesPlugin _plugin;
  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
    _tabManager = LibraryTabManager(ValueNotifier(-1));
    _tabManager.onTabChangeStream.stream.listen((detail) {
      // final event = detail['event'];
      // final index = detail['index'];
      setState(() {});
    });

    _plugin.setTabManager(_tabManager);
  }

  @override
  void dispose() {
    super.dispose();
    _tabManager.dispose();
    _plugin.server.stop();
  }

  bool _showSidebar = false;

  Future<void> _openLibrary() async {
    final libraries = _plugin.dataController.libraries;
    final itemCount = libraries.length;
    if (itemCount == 1) {
      _tabManager.addTab(libraries.first);
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
      _tabManager.addTab(selectedLibrary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Utils.isDesktop();
    final tabs =
        _tabManager.tabDatas.entries.map((entry) {
          final tabId = entry.key;
          final tabData = entry.value;
          return TabData(
            index: tabId.hashCode,

            title: Tab(
              child: GestureDetector(
                onSecondaryTapDown:
                    (details) => _showContextMenu(
                      context,
                      details.globalPosition,
                      tabData['library'],
                      tabId,
                    ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tabData['name'] ?? tabData['library'].name,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _tabManager.closeTab(tabId),
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            content: LibraryContentView(
              plugin: _plugin,
              tabId: tabId,
              tabData: tabData,
            ),
          );
        }).toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => setState(() => _showSidebar = !_showSidebar),
        ),
        actions: [
          // settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
        title: const Text('素材管理器'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Row(
        children: [
          if (_showSidebar) ...[
            AppSidebarView(),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child:
                tabs.isEmpty
                    ? LibraryTabsEmptyView(onAddTab: () => _openLibrary())
                    : DynamicTabBarWidget(
                      dynamicTabs: tabs,
                      showBackIcon: true,
                      showNextIcon: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _openLibrary(),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _tabManager.closeAllTabs(),
                      ),
                      physics:
                          isDesktop
                              ? const NeverScrollableScrollPhysics()
                              : null,
                      physicsTabBarView:
                          isDesktop
                              ? const NeverScrollableScrollPhysics()
                              : null,
                      onTabChanged: (index) {
                        if (index != null) {
                          final tabId = _tabManager.tabDatas.keys.elementAt(
                            index,
                          );
                          _tabManager.setTabActive(tabId);
                        }
                      },
                      onTabControllerUpdated: (controller) {
                        controller.addListener(() {
                          final index = controller.index;
                          final tabId = _tabManager.tabDatas.keys.elementAt(
                            index,
                          );
                          _tabManager.setTabActive(tabId);
                        });
                      },
                    ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    Library library,
    String tabId,
  ) {
    LibraryContextMenu.show(
      context: context,
      library: library,
      position: position,
      isPinned: false,
      togglePin: (pin) {},
      onCloseTab: () => _tabManager.closeTab(tabId),
    );
  }
}
