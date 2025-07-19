import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import '../../../../widgets/tree_view.dart';
import 'folder_tree_widget.dart';

class AsyncTreeViewDialog extends StatefulWidget {
  final Set<String>? selected;
  final List<TreeItem> items;
  final Library library;
  final String title;
  final IconData? defaultIcon;
  final String? type;

  const AsyncTreeViewDialog({
    this.selected,
    this.defaultIcon,
    this.type,
    required this.items,
    required this.library,
    required this.title,
    super.key,
  });

  @override
  State<AsyncTreeViewDialog> createState() => _AsyncTreeViewDialogState();
}

class _AsyncTreeViewDialogState extends State<AsyncTreeViewDialog> {
  late FolderTreeWidget _treeWidget;
  final GlobalKey<FolderTreeWidgetState> _treeWidgetStateKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _treeWidget = FolderTreeWidget(
      selected: widget.selected,
      items: widget.items,
      library: widget.library,
      defaultIcon: widget.defaultIcon,
      type: widget.type,
      key: _treeWidgetStateKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxWidth = mediaQuery.size.width * 0.8;
    final maxHeight = mediaQuery.size.height * 0.8;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(width: maxWidth, height: maxHeight, child: _treeWidget),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed:
              () => Navigator.pop(
                context,
                _treeWidget.getSelected(_treeWidgetStateKey.currentState!),
              ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
