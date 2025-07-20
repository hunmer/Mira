import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import '../../../../widgets/tree_view.dart';

typedef OnAddNode = Future<void> Function(TreeItem node);
typedef OnDeleteNode = Future<void> Function(TreeItem node);

class FolderTreeWidget extends StatefulWidget {
  final Set<String>? selected;
  final List<TreeItem> items;
  final Library library;
  final bool? showSelectAll;
  final IconData? defaultIcon;
  final String? type;
  final OnAddNode? onAddNode;
  final OnDeleteNode? onDeleteNode;
  final Function(List<String>) onSelectionChanged;

  const FolderTreeWidget({
    this.selected,
    this.defaultIcon,
    this.type,
    this.showSelectAll,
    required this.items,
    required this.library,
    required this.onSelectionChanged,
    this.onAddNode,
    this.onDeleteNode,
    super.key,
  });

  List<Map<String, dynamic>> getSelected(State<FolderTreeWidget> state) {
    return (state as FolderTreeWidgetState)._items
        .where((item) => item.isSelected)
        .map((item) => item.toMap())
        .toList();
  }

  @override
  State<FolderTreeWidget> createState() => FolderTreeWidgetState();
}

class FolderTreeWidgetState extends State<FolderTreeWidget> {
  late List<TreeItem> _items;
  late Set<String> _selectedItems;
  late IconData _currentIcon;

  @override
  void initState() {
    super.initState();
    _currentIcon =
        widget.defaultIcon ??
        (widget.type == 'folders' ? Icons.folder : Icons.tag);
    _items =
        widget.items.map((item) {
          final isSelected = widget.selected?.contains(item.id) ?? false;
          return item.copyWith(isSelected: isSelected);
        }).toList();
    _selectedItems = widget.selected ?? {};
  }

  Future<void> _onAddNode(TreeItem node) async {
    print('添加文件夹：${node.id}');
    if (['folders', 'tags'].contains(widget.type)) {
      final plugin =
          PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
      if (widget.type == 'folders') {
        plugin.libraryController.getLibraryInst(widget.library)!.addFolder({
          'id': node.id,
          'title': node.title,
          'parent_id': node.parentId,
          'color': node.color?.value,
          'icon': node.icon?.codePoint,
        });
      } else if (widget.type == 'tags') {
        plugin.libraryController.getLibraryInst(widget.library)!.addTag({
          'id': node.id,
          'title': node.title,
          'parent_id': node.parentId,
          'color': node.color?.value,
          'icon': node.icon?.codePoint,
        });
      }
    }
  }

  Future<void> _onDeleteNode(TreeItem node) async {
    print('删除文件夹：${node.id}');
    if (['folders', 'tags'].contains(widget.type)) {
      final plugin =
          PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
      if (widget.type == 'folders') {
        plugin.libraryController
            .getLibraryInst(widget.library)!
            .deleteFolder(node.id);
      } else if (widget.type == 'tags') {
        plugin.libraryController
            .getLibraryInst(widget.library)!
            .deleteTag(node.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return customTreeView(
      items: _items,
      defaultIcon: _currentIcon,
      title: '',
      showSelectAll: widget.showSelectAll ?? true,
      selected: _selectedItems.toList(),
      onSelectionChanged: widget.onSelectionChanged,
      onAddNode: (TreeItem node) async {
        await _onAddNode(node);
        if (widget.onAddNode != null) {
          widget.onAddNode!(node);
        }
      },
      onDeleteNode: (TreeItem node) async {
        await _onDeleteNode(node);
        if (widget.onDeleteNode != null) {
          widget.onDeleteNode!(node);
        }
      },
    );
  }
}
