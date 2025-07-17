import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';

class TreeItem {
  final String id;
  final String? parentId;
  final String title;
  final String? comment;
  final Color color;
  final IconData icon;
  bool isSelected;

  TreeItem({
    required this.id,
    this.parentId,
    required this.title,
    this.comment,
    this.color = Colors.blue,
    this.icon = Icons.folder,
    this.isSelected = false,
  });

  factory TreeItem.fromJson(Map<String, dynamic> json) {
    return TreeItem(
      id: json['id'] as String,
      parentId: json['parentId'] as String?,
      title: json['title'] as String,
      comment: json['comment'] as String?,
      color: Color(json['color'] as int),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'title': title,
      'comment': comment,
      'color': color.value,
      'icon': icon.codePoint,
    };
  }
}

class TreeViewDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final TreeViewMode mode;
  final List<String>? defaultSelectedIds;
  final String? title;

  const TreeViewDialog({
    Key? key,
    required this.items,
    this.mode = TreeViewMode.single,
    this.defaultSelectedIds,
    this.title,
  }) : super(key: key);

  @override
  _TreeViewDialogState createState() => _TreeViewDialogState();
}

enum TreeViewMode { single, multiple }

class _TreeViewDialogState extends State<TreeViewDialog> {
  late TreeNode<TreeItem> _tree;
  final List<String> _selectedIds = [];

  @override
  void initState() {
    super.initState();
    _loadTreeData();
  }

  Future<void> _loadTreeData() async {
    try {
      _tree = _buildTreeFromJson({'items': widget.items});

      if (widget.defaultSelectedIds != null) {
        for (var id in widget.defaultSelectedIds!) {
          final node = _findNodeById(id, _tree);
          if (node != null) {
            node.data!.isSelected = true;
            _selectedIds.add(id);
          }
        }
      }

      setState(() {});
    } catch (e) {
      _tree = TreeNode.root(
        data: TreeItem(
          id: 'root',
          title: widget.title ?? 'Root',
          color: Colors.blue,
          icon: Icons.folder,
        ),
      );
    }
  }

  TreeNode<TreeItem>? _findNodeById(String id, TreeNode<TreeItem> node) {
    if (node.data?.id == id) return node;
    for (var child in node.children.values) {
      final found = _findNodeById(id, child as TreeNode<TreeItem>);
      if (found != null) return found;
    }
    return null;
  }

  TreeNode<TreeItem> _buildTreeFromJson(Map<String, dynamic> json) {
    final itemsMap = <String, TreeNode<TreeItem>>{};
    final items = json['items'] as List<dynamic>;

    // First pass: create all nodes
    for (var itemJson in items.cast<Map<String, dynamic>>()) {
      final item = TreeItem.fromJson(itemJson);
      itemsMap[item.id] = TreeNode(data: item);
    }

    // Second pass: build hierarchy
    for (var node in itemsMap.values) {
      if (node.data?.parentId != null &&
          itemsMap.containsKey(node.data?.parentId)) {
        itemsMap[node.data!.parentId!]!.add(node);
      }
    }

    // Return first level nodes (those without parent or parent not in items)
    final topLevelNodes = TreeNode<TreeItem>.root();
    for (var node in itemsMap.values) {
      if (node.data?.parentId == null ||
          !itemsMap.containsKey(node.data?.parentId)) {
        topLevelNodes.add(node);
      }
    }

    return topLevelNodes;
  }

  void _addChildNode(TreeNode<TreeItem> parent) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter item name'),
            content: TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Item name'),
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(titleController.text);
                },
              ),
            ],
          ),
    );

    if (title == null || title.isEmpty) return;

    final newNode = TreeNode<TreeItem>(
      data: TreeItem(
        id: newId,
        parentId: parent?.data?.id,
        title: title,
        color: Colors.blue,
        icon: Icons.insert_drive_file,
      ),
    );

    setState(() {
      final newId =
          newNode.data?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      if (parent != null) {
        parent.children[newId] = newNode;
      } else {
        // 创建新的树实例确保刷新
        final newTree = TreeNode<TreeItem>.root();
        if (_tree.children.isNotEmpty) {
          newTree.children.addAll(_tree.children);
        }
        newTree.children[newId] = newNode;
        _tree = newTree;
      }
    });
  }

  void _deleteNode(TreeNode<TreeItem> node) {
    setState(() {
      // 直接操作children Map
      final parent = node.parent as TreeNode<TreeItem>?;
      if (parent != null && node.data != null) {
        parent.children.remove(node.data!.id);
        _selectedIds.remove(node.data!.id);
      }
      // 创建新的树实例确保刷新
      final newTree = TreeNode<TreeItem>.root();
      newTree.children.addAll(_tree.children);
      _tree = newTree;
    });
  }

  void _toggleSelection(TreeNode<TreeItem> node) {
    if (node.data == null) return;

    setState(() {
      node.data!.isSelected = !node.data!.isSelected;

      if (node.data!.isSelected) {
        _selectedIds.add(node.data!.id);

        if (widget.mode == TreeViewMode.single) {
          _deselectAllExcept(node.data!.id);
        }
      } else {
        _selectedIds.remove(node.data!.id);
      }
    });
  }

  void _deselectAllExcept(String id) {
    void traverse(TreeNode<TreeItem> node) {
      if (node.data != null && node.data!.id != id && node.data!.isSelected) {
        node.data!.isSelected = false;
        _selectedIds.remove(node.data!.id);
      }
      for (var child in node.children.values) {
        traverse(child as TreeNode<TreeItem>);
      }
    }

    traverse(_tree);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          widget.title != null ? Text(widget.title!) : const Text('Tree View'),
      content: SizedBox(
        width: double.maxFinite,
        child: TreeView.simple(
          tree: _tree,
          builder: (context, node) {
            final treeNode = node as TreeNode<TreeItem>;
            if (treeNode.data == null) return const SizedBox();
            return ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: treeNode.data!.isSelected,
                    onChanged: (_) => _toggleSelection(treeNode),
                  ),
                  Icon(treeNode.data!.icon, color: treeNode.data!.color),
                ],
              ),
              title: Text(treeNode.data!.title),
              subtitle:
                  treeNode.data!.comment != null
                      ? Text(treeNode.data!.comment!)
                      : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addChildNode(treeNode),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteNode(treeNode),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(_selectedIds),
        ),
      ],
    );
  }
}
