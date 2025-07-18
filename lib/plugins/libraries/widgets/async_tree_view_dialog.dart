import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import '../../../../widgets/tree_view.dart';

typedef OnAddNode = Future<void> Function(TreeItem node);
typedef OnDeleteNode = Future<void> Function(TreeItem node);

class AsyncTreeViewDialog extends StatefulWidget {
  final Set<String>? selected;
  final List<TreeItem> items;
  final String title;
  final String? type;

  const AsyncTreeViewDialog({
    this.selected,
    this.type,
    required this.items,
    required this.title,
    super.key,
  });

  @override
  State<AsyncTreeViewDialog> createState() => _AsyncTreeViewDialogState();
}

class _AsyncTreeViewDialogState extends State<AsyncTreeViewDialog> {
  late List<TreeItem> _items;
  late Set<String> _selectedItems;

  @override
  void initState() {
    super.initState();
    _items =
        widget.items.map((item) {
          final isSelected = widget.selected?.contains(item.id) ?? false;
          return TreeItem(
            id: item.id,
            parentId: item.parentId,
            title: item.title,
            isSelected: isSelected,
          );
        }).toList();
    _selectedItems = widget.selected ?? {};
  }

  Future<void> onAddNode(TreeItem node) async {
    print('添加文件夹：${node.id}');
    if (['folders', 'tags'].contains(widget.type)) {
      final plugin =
          PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
      if (widget.type == 'folders') {
        plugin.libraryController.addFolder({
          'id': node.id,
          'title': node.title,
          'parent_id': node.parentId,
          'color': node.color?.value,
          'icon': node.icon?.codePoint,
        });
      } else if (widget.type == 'tags') {
        plugin.libraryController.addTag({
          'id': node.id,
          'title': node.title,
          'parent_id': node.parentId,
          'color': node.color?.value,
          'icon': node.icon?.codePoint,
        });
      }
    }
  }

  Future<void> onDeleteNode(TreeItem node) async {
    print('删除文件夹：${node.id}');
    if (['folders', 'tags'].contains(widget.type)) {
      final plugin =
          PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
      if (widget.type == 'folders') {
        plugin.libraryController.deleteFolder(node.id);
      } else if (widget.type == 'tags') {
        plugin.libraryController.deleteTag(node.id);
      }
    }
  }

  List<String> _getSelectedIds() {
    return _items.where((item) => item.isSelected).map((e) => e.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxWidth = mediaQuery.size.width * 0.8;
    final maxHeight = mediaQuery.size.height * 0.8;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: maxWidth,
        height: maxHeight,
        child: TreeViewDialog(
          items: _items,
          title: widget.title,
          selected: _selectedItems.toList(),
          onAddNode: onAddNode,
          onDeleteNode: onDeleteNode,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _getSelectedIds()),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
