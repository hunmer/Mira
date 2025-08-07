import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/widgets/folder_tree_widget.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager_dock.dart';
import 'package:mira/widgets/checkable_treeview/treeview.dart';
import 'package:mira/widgets/tree_view.dart';
import '../libraries_plugin.dart';
import '../models/library.dart';

class LibrarySidebarView extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final String tabId;
  final String itemId;
  final List<LibraryTag> tags;
  final List<String> tagsSelected;
  final List<LibraryFolder> folders;
  final List<String> folderSelected;

  const LibrarySidebarView({
    super.key,
    required this.plugin,
    required this.tabId,
    required this.itemId,
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
    return Column(
      children: [
        Expanded(
          child: FolderTreeWidget(
            title: '文件夹',
            selectionMode: TreeSelectionMode.single,
            items:
                widget.folders
                    .map((folder) => TreeItem.fromMap(folder.toMap()))
                    .toList(),
            selected: Set<String>.from(widget.folderSelected),
            library: widget.library,
            showSelectAll: false,
            onSelectionChanged: (ids) {
              LibraryTabManager.updateFilter(widget.tabId, widget.itemId, {
                'folder': ids != null && ids.isNotEmpty ? ids.first : '',
              }, overwrite: false);
            },
            type: 'folders',
          ),
        ),
        const Divider(),
        Expanded(
          child: FolderTreeWidget(
            title: '标签',
            selectionMode: TreeSelectionMode.single,
            items:
                widget.tags
                    .map((tag) => TreeItem.fromMap(tag.toMap()))
                    .toList(),
            library: widget.library,
            selected: Set<String>.from(widget.tagsSelected),
            showSelectAll: false,
            onSelectionChanged:
                (ids) => LibraryTabManager.updateFilter(
                  widget.tabId,
                  widget.itemId,
                  {'tags': ids},
                  overwrite: false,
                ),
            type: 'tags',
          ),
        ),
      ],
    );
  }
}
