import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/library_edit_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view.dart';
import 'package:mira/plugins/libraries/widgets/library_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/library_context_menu.dart';
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
  final Map<int, GlobalKey> _tabKeys = {};

  @override
  void initState() {
    super.initState();
    _tabManager = LibraryTabManager(
      libraries: List.from(widget.initialLibraries),
      initialLibraries: widget.initialLibraries,
    );
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => setState(() => _showSidebar = !_showSidebar),
        ),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._tabManager.libraries.asMap().entries.map(
                (entry) => GestureDetector(
                  onTap:
                      () => _tabManager.pageController.animateToPage(
                        entry.key,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      ),
                  onLongPress:
                      () => _showContextMenu(context, entry.value, entry.key),
                  onSecondaryTap:
                      () => _showContextMenu(context, entry.value, entry.key),
                  child: Container(
                    key: _tabKeys[entry.key] ??= GlobalKey(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              _tabManager.currentIndex.value == entry.key
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.value.name),
                        const SizedBox(width: 4),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _tabManager.closeTab(entry.key),
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
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
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: widget.initialLibraries.length,
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
                  }
                },
              ),
            ],
          ),
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
                return PageView(
                  controller: _tabManager.pageController,
                  onPageChanged: (index) {
                    if (index == _tabManager.libraries.length) {
                      _tabManager.pageController.jumpToPage(currentIndex);
                    }
                  },
                  children: [
                    ..._tabManager.libraries.map(
                      (library) => LibraryGalleryView(
                        plugin: widget.plugin,
                        library: library,
                      ),
                    ),
                    const Center(child: Icon(Icons.add)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Library library, int tabIndex) {
    final key = _tabKeys[tabIndex];
    if (key == null || key.currentContext == null) return;

    LibraryContextMenu.show(
      context: context,
      tabKey: key,
      library: library,
      initialLibraries: widget.initialLibraries,
      onCloseTab: () => _tabManager.closeTab(tabIndex),
    );
  }
}
