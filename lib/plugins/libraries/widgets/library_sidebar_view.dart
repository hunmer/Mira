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
  final String tabId;
  final List<LibraryTag> tags;
  final List<String> tagsSelected;
  final List<LibraryFolder> folders;
  final List<String> folderSelected;

  const LibrarySidebarView({
    super.key,
    required this.plugin,
    required this.tabId,
    required this.library,
    required this.tags,
    this.tagsSelected = const [],
    required this.folders,
    this.folderSelected = const [],
  });

  @override
  State<LibrarySidebarView> createState() => _LibrarySidebarViewState();
}

class _LibrarySidebarViewState extends State<LibrarySidebarView> {
  @override
  void initState() {
    super.initState();
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
            child: FolderTreeWidget(
              items:
                  widget.tags
                      .map((tag) => TreeItem(id: tag.id, title: tag.title))
                      .toList(),
              library: widget.library,
              selected: Set<String>.from(widget.tagsSelected),
              showSelectAll: false,
              onSelectionChanged:
                  (ids) => widget.plugin.tabManager.updateFilter(widget.tabId, {
                    'tags': ids,
                  }),
              type: 'tags',
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
            child: FolderTreeWidget(
              items:
                  widget.folders
                      .map(
                        (folder) =>
                            TreeItem(id: folder.id, title: folder.title),
                      )
                      .toList(),
              selected: Set<String>.from(widget.folderSelected),
              library: widget.library,
              showSelectAll: false,
              onSelectionChanged: (ids) {
                if (ids != null && ids.isNotEmpty) {
                  widget.plugin.tabManager.updateFilter(widget.tabId, {
                    'folder': ids.first,
                  });
                } else {
                  widget.plugin.tabManager.updateFilter(widget.tabId, {
                    'folder': '',
                  });
                }
              },
              type: 'folders',
            ),
          ),
        ],
      ),
    );
  }
}
