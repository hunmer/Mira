// ignore_for_file: deprecated_member_use

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mira/widgets/checkable_treeview/treeview.dart';
import 'circle_icon_picker.dart';

class TreeItem {
  TreeItem({
    required this.id,
    required this.title,
    this.parentId,
    this.color,
    this.icon,
    this.isSelected = false,
  });

  final Color? color;
  final IconData? icon;
  final String id;
  final String title;
  final String? parentId;
  bool isSelected;

  // copyWith
  TreeItem copyWith({
    Color? color,
    IconData? icon,
    String? id,
    String? title,
    String? parentId,
    bool? isSelected,
  }) => TreeItem(
    id: id ?? this.id,
    title: title ?? this.title,
    parentId: parentId ?? this.parentId,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    isSelected: isSelected ?? this.isSelected,
  );

  // fromMap
  factory TreeItem.fromMap(Map<String, dynamic> map) => TreeItem(
    id: map['id']?.toString() ?? '',
    title: map['title'] as String? ?? '',
    parentId: map['parent_id'] as String?,
    color:
        map['color'] != null
            ? Color(int.tryParse(map['color'].toString()) ?? 0)
            : null,
    icon:
        map['icon'] != null
            ? IconData(
              int.tryParse(map['icon'].toString()) ?? 0,
              fontFamily: 'MaterialIcons',
            )
            : null,
    isSelected: map['isSelected'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'parent_id': parentId,
    'color': color?.value,
    'icon': icon?.codePoint,
    'isSelected': isSelected,
  };
}

// ignore: camel_case_types
class customTreeView extends StatefulWidget {
  const customTreeView({
    super.key,
    required this.items,
    this.showSelectAll = false,
    this.title = 'Tree View',
    required this.defaultIcon,
    required this.onSelectionChanged,
    this.selected = const [],
    this.selectionMode = TreeSelectionMode.multiple,
    this.onAddNode,
    this.onDeleteNode,
  });

  final List<TreeItem> items;
  final String title;
  final bool showSelectAll;
  final IconData defaultIcon;
  final List<String> selected;
  final TreeSelectionMode selectionMode;
  final void Function(TreeItem item)? onAddNode;
  final Function(List<String>) onSelectionChanged;
  final void Function(TreeItem item)? onDeleteNode;

  @override
  State<customTreeView> createState() => _customTreeViewState();
}

// ignore: camel_case_types
class _customTreeViewState extends State<customTreeView> {
  List<TreeNode<String>> _treeNodes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // Initialize selected items
    for (final id in widget.selected) {
      final item = widget.items.firstWhereOrNull((item) => item.id == id);
      if (item != null) {
        item.isSelected = true;
      }
    }
    _buildTree();
  }

  void _buildTree() {
    final rootItems =
        widget.items.where((item) => item.parentId == null).toList();
    final newTreeNodes = rootItems.map(_createTreeNode).toList();

    if (!listEquals(_treeNodes, newTreeNodes)) {
      setState(() {
        _treeNodes = newTreeNodes;
      });
    }
  }

  TreeNode<String> _createTreeNode(TreeItem item) {
    final children =
        widget.items
            .where((child) => child.parentId == item.id)
            .map(_createTreeNode)
            .toList();

    return TreeNode(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(item.title)],
      ),
      trailing: (context, node) {
        return IconButton(
          icon: const Icon(Icons.more_vert, size: 16),
          onPressed: () => _showNodeMenu(item),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      },
      value: item.id,
      icon: Icon(
        item.icon ?? widget.defaultIcon,
        color: item.color ?? Colors.black,
      ),
      children: children,
      isSelected: item.isSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(widget.title),
            ),
            const Spacer(),
            if (_showSearch) ...[
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (value) => setState(() => _filterTree(value)),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                    _searchController.clear();
                    _buildTree();
                  });
                },
              ),
            ],
            if (!_showSearch) ...[
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _showSearch = true),
              ),
              IconButton(icon: const Icon(Icons.add), onPressed: _addRootNode),
            ],
          ],
        ),
        Expanded(
          child:
              _treeNodes.isEmpty
                  ? const Center(child: Text('没有任何数据'))
                  : LayoutBuilder(
                    builder: (context, constraints) {
                      return TreeView<String>(
                        nodes: _treeNodes,
                        initialExpandedLevels:
                            99, // Ensure all nodes are expanded
                        showExpandCollapseButton: true,
                        selectionMode: widget.selectionMode,
                        showSelectAll: widget.showSelectAll,
                        onSelectionChanged: (ids) {
                          widget.onSelectionChanged(List<String>.from(ids));
                          for (final id in ids) {
                            widget
                                .items
                                .firstWhere((item) => item.id == id)
                                .isSelected = true;
                          }
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }

  void _showNodeMenu(TreeItem item) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Child Node'),
                onTap: () => Navigator.pop(context, 'add'),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Node'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Node'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
    );

    if (selected == 'add') {
      await _addChildNode(item);
      if (widget.onAddNode != null) {
        widget.onAddNode!(item);
      }
    } else if (selected == 'edit') {
      await _editNode(item);
    } else if (selected == 'delete') {
      _deleteNode(item);
    }
  }

  Future<TreeItem?> _showEditDialog({
    required TreeItem item,
    TreeItem? parent,
  }) async {
    final titleController = TextEditingController(text: item.title);
    String? selectedParentId = parent?.id;
    IconData? selectedIcon = item.icon;
    Color? selectedColor = item.color;

    return await showDialog<TreeItem>(
      context: context,
      builder: (context) {
        // 使用StatefulBuilder来管理对话框内部的状态
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Node'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: CircleIconPicker(
                        currentIcon: selectedIcon ?? widget.defaultIcon,
                        backgroundColor: selectedColor ?? Colors.blue,
                        onIconSelected: (icon) {
                          setStateDialog(() {
                            selectedIcon = icon;
                          });
                        },
                        onColorSelected: (color) {
                          setStateDialog(() {
                            selectedColor = color;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final newItem = TreeItem(
                      id: item.id,
                      title: titleController.text,
                      parentId: selectedParentId,
                      icon: selectedIcon,
                      color: selectedColor,
                      isSelected: item.isSelected,
                    );
                    Navigator.pop(context, newItem);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fix: Correctly add new root node and update tree
  void _addRootNode() async {
    final newItem = TreeItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      icon: widget.defaultIcon,
      title: 'New Node',
    );

    final result = await _showEditDialog(item: newItem);
    if (result != null) {
      setState(() {
        widget.items.add(result);
        _buildTree();
      });
      if (widget.onAddNode != null) {
        widget.onAddNode!(result);
      }
    }
  }

  Future<void> _addChildNode(TreeItem parent) async {
    final newItem = TreeItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Child',
      icon: widget.defaultIcon,
      parentId: parent.id,
    );

    final result = await _showEditDialog(item: newItem, parent: parent);
    if (result != null) {
      setState(() {
        widget.items.add(result);
        _buildTree();
      });
    }
  }

  Future<void> _editNode(TreeItem item) async {
    final result = await _showEditDialog(item: item);
    if (result != null) {
      setState(() {
        final index = widget.items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          widget.items[index] = result;
          _buildTree();
        }
      });
    }
  }

  void _deleteNode(TreeItem node) {
    void removeRecursively(String id) {
      final children =
          widget.items.where((item) => item.parentId == id).toList();
      final item = widget.items.firstWhere(
        (item) => item.id == id,
        orElse: () => TreeItem(id: '', title: ''),
      );
      if (item.id.isNotEmpty) {
        widget.items.removeWhere((item) => item.id == id);
        if (widget.onDeleteNode != null) {
          widget.onDeleteNode!(item);
        }
      }
      for (final child in children) {
        removeRecursively(child.id);
      }
    }

    setState(() {
      removeRecursively(node.id);
      _buildTree();
    });
  }

  void _filterTree(String searchText) {
    if (searchText.isEmpty) {
      setState(() {
        _buildTree();
      });
      return;
    }

    final filtered =
        widget.items
            .where(
              (item) =>
                  item.title.toLowerCase().contains(searchText.toLowerCase()),
            )
            .toList();

    final Set<TreeItem> itemsToShow = {};

    // 1. Add matched items and their ancestors
    for (final item in filtered) {
      itemsToShow.add(item);
      _collectAncestors(item, itemsToShow);
    }

    // 2. Add all children of matched items
    for (final item in List.from(itemsToShow)) {
      _collectChildren(item, itemsToShow);
    }

    // 3. Build tree with filtered items while preserving original styling
    final rootItems =
        itemsToShow.where((item) => item.parentId == null).toList();
    final newTreeNodes =
        rootItems.map((item) => _createTreeNode(item)).toList();

    if (!listEquals(_treeNodes, newTreeNodes)) {
      setState(() {
        _treeNodes = newTreeNodes;
      });
    }
  }

  void _collectAncestors(TreeItem item, Set<TreeItem> result) {
    if (item.parentId != null) {
      final parent = widget.items.firstWhere(
        (it) => it.id == item.parentId,
        orElse: () => TreeItem(id: '', title: ''),
      );
      if (parent.id.isNotEmpty && !result.contains(parent)) {
        result.add(parent);
        _collectAncestors(parent, result);
      }
    }
  }

  void _collectChildren(TreeItem item, Set<TreeItem> result) {
    final children = widget.items.where((child) => child.parentId == item.id);
    for (final child in children) {
      if (!result.contains(child)) {
        result.add(child);
        _collectChildren(child, result);
      }
    }
  }
}
