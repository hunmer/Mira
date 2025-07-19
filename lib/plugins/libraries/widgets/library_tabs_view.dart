import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/library_edit_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view.dart';
import '../models/library.dart';

class LibraryTabsView extends StatefulWidget {
  final LibrariesPlugin plugin;
  final List<Library> initialLibraries;

  const LibraryTabsView({
    Key? key,
    required this.plugin,
    required this.initialLibraries,
  }) : super(key: key);

  @override
  _LibraryTabsViewState createState() => _LibraryTabsViewState();
}

class _LibraryTabsViewState extends State<LibraryTabsView> {
  final List<Library> _libraries = [];
  int _currentIndex = 0;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _libraries.addAll(widget.initialLibraries);
    _pageController.addListener(() {
      setState(() {
        _currentIndex = _pageController.page?.round() ?? 0;
      });
    });
  }

  void _addTab(Library library) {
    setState(() {
      _libraries.add(library);
      _currentIndex = _libraries.length - 1;
      _pageController.jumpToPage(_currentIndex);
    });
  }

  void _closeTab(int index) {
    setState(() {
      _libraries.removeAt(index);
      if (_currentIndex >= _libraries.length) {
        _currentIndex = _libraries.length - 1;
      }
      _pageController.jumpToPage(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
    widget.plugin.server.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._libraries.asMap().entries.map(
                (entry) => GestureDetector(
                  onTap:
                      () => _pageController.animateToPage(
                        entry.key,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease,
                      ),
                  onLongPress: () => _showContextMenu(context, entry.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              _currentIndex == entry.key
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
                          onTap: () => _closeTab(entry.key),
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
                    _addTab(selectedLibrary);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (index == _libraries.length) {
            _pageController.jumpToPage(_currentIndex);
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        children: [
          ..._libraries.map(
            (library) =>
                LibraryGalleryView(plugin: widget.plugin, library: library),
          ),
          const Center(child: Icon(Icons.add)),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Library library) {
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    final isPinned =
        _libraries.indexOf(library) < widget.initialLibraries.length;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      items: [
        PopupMenuItem(
          child: Text(isPinned ? '取消固定' : '固定'),
          onTap: () {
            setState(() {
              if (isPinned) {
                // 从固定列表中移除
                widget.initialLibraries.remove(library);
              } else {
                // 添加到固定列表
                widget.initialLibraries.add(library);
              }
            });
          },
        ),
        PopupMenuItem(
          child: const Text('关闭'),
          onTap: () => _closeTab(_libraries.indexOf(library)),
        ),
      ],
    );
  }
}
