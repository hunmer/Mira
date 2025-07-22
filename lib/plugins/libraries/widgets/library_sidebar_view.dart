import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/widgets/folder_tree_widget.dart';
import 'package:mira/widgets/tree_view.dart';
import '../libraries_plugin.dart';
import '../models/library.dart';

class LibrarySidebarView extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Library library;

  const LibrarySidebarView({
    super.key,
    required this.plugin,
    required this.library,
  });

  @override
  State<LibrarySidebarView> createState() => _LibrarySidebarViewState();
}

class _LibrarySidebarViewState extends State<LibrarySidebarView> {
  late Library? _library;

  @override
  void initState() {
    super.initState();
    _library = widget.plugin.tabManager.getCurrentLibrary();
  }

  void setCurrentLibraray(Library library) {
    setState(() {
      _library = library;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('标签目录', style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: FutureBuilder<List<LibraryTag?>>(
              future:
                  widget.plugin.foldersTagsController
                      .getTagCache(_library!.id)
                      .getAll(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FolderTreeWidget(
                    items:
                        snapshot.data!
                            .map(
                              (tag) => TreeItem(id: tag!.id, title: tag.title),
                            )
                            .toList(),
                    library: _library!,
                    showSelectAll: false,
                    onSelectionChanged:
                        (ids) => widget.plugin.tabManager.updateCurrentFitler({
                          'tags': ids,
                        }),
                    type: 'tags',
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '文件夹目录',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LibraryFolder?>>(
              future:
                  widget.plugin.foldersTagsController
                      .getFolderCache(_library!.id)
                      .getAll(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FolderTreeWidget(
                    items:
                        snapshot.data!
                            .map(
                              (folder) =>
                                  TreeItem(id: folder!.id, title: folder.title),
                            )
                            .toList(),
                    library: _library!,
                    showSelectAll: false,
                    onSelectionChanged: (ids) {
                      if (ids != null && ids.isNotEmpty) {
                        widget.plugin.tabManager.updateCurrentFitler({
                          'folder': ids.first,
                        });
                      } else {
                        widget.plugin.tabManager.updateCurrentFitler({
                          'folder': '',
                        });
                      }
                    },
                    type: 'folders',
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
