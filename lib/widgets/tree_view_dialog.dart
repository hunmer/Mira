import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:checkable_treeview/checkable_treeview.dart';

class TreeItem {
  TreeItem({
    required this.id,
    required this.title,
    this.parentId,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final String? parentId;
  bool isSelected;
}

class TreeViewDialog extends StatefulWidget {
  const TreeViewDialog({
    super.key,
    required this.items,
    this.title = 'Tree View',
    this.isMultiSelect = true,
    this.selected = const [],
    this.onAddNode,
    this.onDeleteNode,
  });

  final List<TreeItem> items;
  final String title;
  final bool isMultiSelect;
  final List<String> selected;
  final void Function(TreeItem item)? onAddNode;
  final void Function(TreeItem item)? onDeleteNode;

  @override
  State<TreeViewDialog> createState() => _TreeViewDialogState();
}

class _TreeViewDialogState extends State<TreeViewDialog> {
  List<TreeNode<String>> _treeNodes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    // Initialize selected items
    for (final id in widget.selected) {
      final item = widget.items.firstWhere(
        (item) => item.id == id,
        orElse: () => TreeItem(id: '', title: ''),
      );
      if (item.id.isNotEmpty) {
        item.isSelected = true;
      }
    }
    _buildTree();
  }

  void _buildTree() {
    final rootItems =
        widget.items.where((item) => item.parentId == null).toList();
    debugPrint('Building tree with ${rootItems.length} root items');
    debugPrint('Total items count: ${widget.items.length}');

    final newTreeNodes = rootItems.map(_createTreeNode).toList();
    debugPrint('Tree nodes: ${newTreeNodes.length}');

    if (!listEquals(_treeNodes, newTreeNodes)) {
      setState(() {
        _treeNodes = newTreeNodes;
        debugPrint('Tree nodes updated');
      });
    } else {
      debugPrint('Tree nodes unchanged');
    }
  }

  TreeNode<String> _createTreeNode(TreeItem item) {
    final children =
        widget.items
            .where((child) => child.parentId == item.id)
            .map(_createTreeNode)
            .toList();

    return TreeNode(
      label: Text(item.title),
      trailing: (context, node) {
        return IconButton(
          icon: const Icon(Icons.more_vert, size: 16),
          onPressed: () => _showNodeMenu(item),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      },
      value: item.id,
      icon:
          children.isEmpty
              ? const Icon(Icons.insert_drive_file)
              : const Icon(Icons.folder),
      children: children,
      isSelected: item.isSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.title),
              const Spacer(),
              if (_showSearch) ...[
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: double.infinity,
                    ),
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
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addRootNode,
                ),
              ],
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child:
            _treeNodes.isEmpty
                ? const Center(child: Text('No items to display'))
                : LayoutBuilder(
                  builder: (context, constraints) {
                    debugPrint('TreeView constraints: $constraints');
                    return TreeView<String>(
                      key: ValueKey(
                        _treeNodes,
                      ), // Force rebuild when nodes change
                      nodes: _treeNodes,
                      initialExpandedLevels:
                          99, // Ensure all nodes are expanded
                      showExpandCollapseButton: true,
                      showSelectAll: widget.isMultiSelect,
                      onSelectionChanged: (selectedValues) {
                        // 单选模式：只保留最后一个选中项
                        if (!widget.isMultiSelect) {
                          for (final item in widget.items) {
                            item.isSelected = false;
                          }
                          if (selectedValues.isNotEmpty) {
                            final lastSelectedId = selectedValues.last;
                            final item = widget.items.firstWhere(
                              (item) => item.id == lastSelectedId,
                              orElse: () => TreeItem(id: '', title: ''),
                            );
                            if (item.id.isNotEmpty) {
                              item.isSelected = true;
                              _buildTree();
                            }
                          }
                        }
                      },
                    );
                  },
                ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final selectedItems =
                widget.items.where((item) => item.isSelected).toList();
            Navigator.pop(context, selectedItems);
          },
          child: const Text('OK'),
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

    return await showDialog<TreeItem>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Node'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                // This part can be improved, but not critical for bug fix
              ],
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
                    isSelected: item.isSelected,
                  );
                  Navigator.pop(context, newItem);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  // Fix: Correctly add new root node and update tree
  void _addRootNode() async {
    final newItem = TreeItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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

  // Fix: Filter tree and preserve hierarchy for matching items
  void _filterTree(String searchText) {
    if (searchText.isEmpty) {
      setState(() {
        _buildTree();
      });
      return;
    }

    // Find all items that match
    final filtered =
        widget.items
            .where(
              (item) =>
                  item.title.toLowerCase().contains(searchText.toLowerCase()),
            )
            .toList();

    // To show their parents in the tree, collect all ancestors
    final Set<TreeItem> resultItems = Set.from(filtered);
    void collectAncestors(TreeItem item) {
      if (item.parentId != null) {
        final parent = widget.items.firstWhere(
          (it) => it.id == item.parentId,
          orElse: () => TreeItem(id: '', title: ''),
        );
        if (parent.id.isNotEmpty && !resultItems.contains(parent)) {
          resultItems.add(parent);
          collectAncestors(parent);
        }
      }
    }

    for (final item in filtered) {
      collectAncestors(item);
    }

    // Also include all children of matched items
    final Set<TreeItem> itemsToShow = Set.from(resultItems);
    void collectChildren(TreeItem item) {
      final children = widget.items.where((child) => child.parentId == item.id);
      for (final child in children) {
        itemsToShow.add(child);
        collectChildren(child);
      }
    }

    for (final item in filtered) {
      collectChildren(item);
    }

    final rootItems =
        itemsToShow.where((item) => item.parentId == null).toList();
    final newTreeNodes =
        rootItems.map((item) {
          return _createFilteredTreeNode(item, itemsToShow);
        }).toList();

    if (!listEquals(_treeNodes, newTreeNodes)) {
      setState(() {
        _treeNodes = newTreeNodes;
        debugPrint('Filtered tree nodes updated');
      });
    } else {
      debugPrint('Filtered tree nodes unchanged');
    }
  }

  // Helper: Only build tree nodes for filtered items
  TreeNode<String> _createFilteredTreeNode(
    TreeItem item,
    Set<TreeItem> allowedItems,
  ) {
    final children =
        widget.items
            .where(
              (child) =>
                  child.parentId == item.id && allowedItems.contains(child),
            )
            .map((child) => _createFilteredTreeNode(child, allowedItems))
            .toList();
    return TreeNode(
      label: Row(
        children: [
          Expanded(child: Text(item.title)),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 16),
            onPressed: () => _showNodeMenu(item),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      value: item.id,
      icon:
          children.isEmpty
              ? const Icon(Icons.insert_drive_file)
              : const Icon(Icons.folder),
      children: children,
    );
  }
}
