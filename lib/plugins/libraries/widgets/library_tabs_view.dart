import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/library_context_menu.dart'
    as LibraryContextMenu;
import 'package:mira/plugins/libraries/widgets/library_edit_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view.dart';
import 'package:mira/plugins/libraries/widgets/library_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager.dart';
import '../models/library.dart';

class LibraryTabsView extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final List<Library> initialLibraries;

  const LibraryTabsView({
    Key? key,
    required this.plugin,
    required this.library,
    required this.initialLibraries,
  }) : super(key: key);

  @override
  _LibraryTabsViewState createState() => _LibraryTabsViewState();
}

class _LibraryTabsViewState extends State<LibraryTabsView> {
  late final LibraryTabManager _tabManager;

  @override
  void initState() {
    super.initState();
    _tabManager = LibraryTabManager(
      libraries: List.from(widget.initialLibraries),
      initialLibraries: widget.initialLibraries,
    );
    widget.plugin.setTabManager(_tabManager);
  }

  @override
  void dispose() {
    _tabManager.dispose();
    super.dispose();
    widget.plugin.server.stop();
  }

  bool _showSidebar = false;

  @override
  Widget build(BuildContext context) {
    final tabsTab = <Widget>[];
    final tabsContents = <Widget>[];
    _tabManager.tabDatas.forEach((tabId, tabData) {
      tabsContents.add(
        LibraryGalleryView(
          plugin: widget.plugin,
          tabId: tabId,
          library: tabData['library'],
        ),
      );
      tabsTab.add(
        GestureDetector(
          onTap: () => _tabManager.setTabActive(tabId),
          onSecondaryTapDown:
              (details) => _showContextMenu(
                context,
                details.globalPosition,
                tabData['library'],
                tabId,
              ),

          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      _tabManager.getCurrentTabId() == tabId
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tabData['name'] ?? tabData['library'].name),
                const SizedBox(width: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap:
                      () => setState(() {
                        _tabManager.closeTab(tabId);
                      }),
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),
        ),
      );
    });
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => setState(() => _showSidebar = !_showSidebar),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final itemCount = widget.initialLibraries.length;
              if (itemCount == 1) {
                _tabManager.addTab(widget.initialLibraries[0]);
                setState(() {});
                return;
              }
              final selectedLibrary = await showDialog<Library>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Select Library'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () async {
                            final newLibrary = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LibraryEditView(),
                              ),
                            );
                            if (newLibrary != null) {
                              Navigator.pop(context, newLibrary);
                            }
                          },
                        ),
                      ],
                      content: SizedBox(
                        width: double.minPositive,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: itemCount,
                          itemBuilder:
                              (context, index) => ListTile(
                                title: Text(
                                  widget.initialLibraries[index].name,
                                ),
                                onTap: () {
                                  Navigator.pop(
                                    context,
                                    widget.initialLibraries[index],
                                  );
                                },
                              ),
                        ),
                      ),
                    ),
              );
              if (selectedLibrary != null) {
                _tabManager.addTab(selectedLibrary);
                setState(() {});
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed:
                () => setState(() {
                  _tabManager.closeAllTabs();
                }),
          ),
        ],
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: tabsTab),
        ),
      ),
      body: Row(
        children: [
          if (_showSidebar)
            LibrarySidebarView(
              plugin: widget.plugin,
              library: widget.library,
              onHideSidebar: () => setState(() => _showSidebar = false),
            ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: _tabManager.currentIndex,
              builder: (context, currentIndex, _) {
                return _tabManager.libraries.isEmpty
                    ? const Center(
                      child: Text(
                        'No libraries available',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                    : PageView(
                      controller: _tabManager.pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _tabManager.currentIndex.value = index;
                        });
                      },
                      children: tabsContents,
                    );
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
      initialLibraries: widget.initialLibraries,
      onCloseTab:
          () => setState(() {
            _tabManager.closeTab(tabId);
          }),
    );
  }
}
