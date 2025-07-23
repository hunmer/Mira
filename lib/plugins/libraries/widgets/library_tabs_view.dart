import 'package:flutter/material.dart';
import 'package:mira/core/event/event_args.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/core/event/event_throttle.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/core/utils/utils.dart' as Utils;
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/app_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/library_list_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tabs_context_menu.dart'
    // ignore: library_prefixes
    as LibraryContextMenu;
import 'package:mira/plugins/libraries/widgets/library_content_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager.dart';
import 'package:mira/views/library_tabs_empty_view.dart';
import '../models/library.dart';
import 'package:dynamic_tabbar/dynamic_tabbar.dart';

class LibraryTabsView extends StatefulWidget {
  const LibraryTabsView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LibraryTabsViewState createState() => _LibraryTabsViewState();
}

class _LibraryTabsViewState extends State<LibraryTabsView> {
  late LibrariesPlugin _plugin;
  late LibraryTabManager _tabManager;
  List<LibraryTabData> _tabDatas = [];

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
    _tabManager = _plugin.tabManager;
    _loadTabDatas();
    init();
  }

  Future<void> init() async {
    _tabManager.onTabEventStream.stream.listen((detail) async {
      final event = detail['event'];
      final tabId = detail['tabId'];
      print('tab event: $event, tabId: $tabId');
      switch (event) {
        case 'active':
          // 保证tab所属的library进行初始化连接
          _tabManager.tryUpdate(tabId);
          break;
        case 'close':
        case 'add':
          setState(() {
            _loadTabDatas();
          });
          break;
      }
    });

    final chanedStream = EventThrottle(duration: Duration(milliseconds: 1000));
    chanedStream.stream.listen((EventArgs args) {
      //  服务器广播文件更新
      if (args is MapEventArgs) {
        final libraryId = args.item['libraryId'];
        final currentTab = _tabManager.getCurrentTabId();
        for (LibraryTabData tabData in _tabManager.tabDatas) {
          final library = tabData.library;
          if (library.id == libraryId) {
            _tabManager.setValue(tabData.id, 'needUpdate', true);
            if (tabData.id == currentTab) {
              _tabManager.tryUpdate(tabData.id);
            }
          }
        }
      }
    });
    EventManager.instance.subscribe(
      'file::changed',
      (args) => chanedStream.onCall(args),
    );
    EventManager.instance.subscribe(
      'tags::updated',
      (args) => chanedStream.onCall(args),
    );
    EventManager.instance.subscribe(
      'folder::updated',
      (args) => chanedStream.onCall(args),
    );
  }

  void _loadTabDatas() {
    _tabDatas = _tabManager.tabDatas.toList();
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
    return FutureBuilder<bool>(
      future: _tabManager.isLoaded, // 等待tabManager加载完毕
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return CircularProgressIndicator();
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Text('加载数据出错: ${snapshot.error}');
            }
            final isDesktop = Utils.isDesktop();
            final tabs =
                _tabDatas.map((tabData) {
                  return TabData(
                    index: tabData.id.hashCode,
                    title: Tab(
                      child: GestureDetector(
                        onSecondaryTapDown:
                            (details) => _showContextMenu(
                              context,
                              details.globalPosition,
                              tabData.library,
                              tabData.id,
                            ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tabData.title.isNotEmpty
                                  ? tabData.title
                                  : tabData.library.name,
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _tabManager.closeTab(tabData.id),
                                child: const Icon(Icons.close, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    content: LibraryContentView(
                      plugin: _plugin,
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
                            ? LibraryTabsEmptyView(
                              onAddTab: () => _openLibrary(),
                            )
                            : DynamicTabBarWidget(
                              dynamicTabs: tabs,
                              showBackIcon: true,
                              showNextIcon: true,
                              isScrollable: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _openLibrary(),
                              ),
                              leading: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _tabManager.closeAllTabs(),
                              ),
                              // 桌面端禁止手势滑动
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
                                  _tabManager.setActive(index);
                                }
                              },
                              onTabControllerUpdated: (controller) {},
                            ),
                  ),
                ],
              ),
            );
        }
      },
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
