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

  @override
  void initState() {
    super.initState();
    _libraries.addAll(widget.initialLibraries);
  }

  void _addTab(Library library) {
    setState(() {
      _libraries.add(library);
      _currentIndex = _libraries.length - 1;
    });
  }

  void _closeTab(int index) {
    setState(() {
      _libraries.removeAt(index);
      if (_currentIndex >= _libraries.length) {
        _currentIndex = _libraries.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _libraries.length + 1, // +1 for add button
      initialIndex: _currentIndex,
      child: Scaffold(
        appBar: AppBar(
          title: TabBar(
            isScrollable: true,
            tabs: [
              ..._libraries.map((library) => Tab(text: library.name)),
              const Tab(icon: Icon(Icons.add)),
            ],
            onTap: (index) async {
              if (index == _libraries.length) {
                // Show libraries dialog with new button
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
              } else {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
          ),
        ),
        body: TabBarView(
          children: [
            ..._libraries.map(
              (library) =>
                  LibraryGalleryView(plugin: widget.plugin, library: library),
            ),
            const Center(child: Icon(Icons.add)),
          ],
        ),
      ),
    );
  }

  // 销毁
  @override
  void dispose() {
    super.dispose();
    widget.plugin.server.stop();
  }
}
