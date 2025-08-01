// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/widgets/checkable_treeview/treeview.dart';
import '../../../../widgets/tree_view.dart';

typedef OnAddNode = Future<void> Function(TreeItem node);
typedef OnDeleteNode = Future<void> Function(TreeItem node);

class FolderTreeWidget extends StatefulWidget {
  final Set<String>? selected;
  final List<TreeItem> items;
  final Library library;
  final String? title;
  final bool? showSelectAll;
  final IconData? defaultIcon;
  final String? type;
  final OnAddNode? onAddNode;
  final OnDeleteNode? onDeleteNode;
  final TreeSelectionMode selectionMode;
  final Function(List<String>) onSelectionChanged;

  const FolderTreeWidget({
    super.key,
    this.selected,
    this.defaultIcon,
    this.type,
    this.title,
    this.showSelectAll,
    this.selectionMode = TreeSelectionMode.multiple,
    required this.items,
    required this.library,
    required this.onSelectionChanged,
    this.onAddNode,
    this.onDeleteNode,
  });

  @override
  State<FolderTreeWidget> createState() => FolderTreeWidgetState();
}

class FolderTreeWidgetState extends State<FolderTreeWidget> {
  late Set<String> _selectedItems;
  late IconData _currentIcon;
  customTreeView? _treeView;

  @override
  void initState() {
    super.initState();
    _currentIcon =
        widget.defaultIcon ??
        (widget.type == 'folders' ? Icons.folder : Icons.tag);
    _selectedItems = widget.selected ?? {};
    _buildTreeView();
  }

  @override
  void didUpdateWidget(FolderTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 更新选中项状态
    if (oldWidget.selected != widget.selected) {
      _selectedItems = widget.selected ?? {};
    }
    // 只在必要时重建树视图
    if (oldWidget.items != widget.items ||
        oldWidget.selected != widget.selected ||
        oldWidget.defaultIcon != widget.defaultIcon) {
      _buildTreeView();
    }
  }

  void _buildTreeView() {
    final mappedItems = getItems();
    _treeView = customTreeView(
      items: mappedItems,
      defaultIcon: _currentIcon,
      selectionMode: widget.selectionMode,
      title: widget.title ?? '',
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
      key: ValueKey(mappedItems.length), // 使用长度作为key，避免过度重建
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onAddNode(TreeItem node) async {
    if (['folders', 'tags'].contains(widget.type)) {
      final plugin =
          PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
      if (widget.type == 'folders') {
        plugin.libraryController.getLibraryInst(widget.library.id)!.addFolder({
          'id': node.id,
          'title': node.title,
          'parent_id': node.parentId,
          'color': node.color?.value,
          'icon': node.icon?.codePoint,
        });
      } else if (widget.type == 'tags') {
        plugin.libraryController.getLibraryInst(widget.library.id)!.addTag({
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
    if (['folders', 'tags'].contains(widget.type)) {
      final plugin =
          PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
      if (widget.type == 'folders') {
        plugin.libraryController
            .getLibraryInst(widget.library.id)!
            .deleteFolder(node.id);
      } else if (widget.type == 'tags') {
        plugin.libraryController
            .getLibraryInst(widget.library.id)!
            .deleteTag(node.id);
      }
    }
  }

  List<TreeItem> getItems() {
    return widget.items.map((item) {
      final isSelected = widget.selected?.contains(item.id) ?? false;
      return item.copyWith(isSelected: isSelected);
    }).toList();
  }

  List<Map<String, dynamic>> getSelected() {
    return getItems()
        .where((item) => item.isSelected)
        .map((item) => item.toMap())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return _treeView ?? Container();
  }
}
