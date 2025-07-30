import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/widgets/checkable_treeview/treeview.dart';
import '../../../../widgets/tree_view.dart';
import 'folder_tree_widget.dart';

class AsyncTreeViewDialog extends StatefulWidget {
  final Set<String>? selected;
  final List<TreeItem> items;
  final Library library;
  final String title;
  final IconData? defaultIcon;
  final String? type;
  final TreeSelectionMode selectionMode;
  final Function(List<String>)? onSelectionChanged;

  const AsyncTreeViewDialog({
    this.selected,
    this.defaultIcon,
    this.type,
    required this.items,
    this.selectionMode = TreeSelectionMode.single,
    this.onSelectionChanged,
    required this.library,
    required this.title,
    super.key,
  });

  @override
  State<AsyncTreeViewDialog> createState() => _AsyncTreeViewDialogState();
}

class _AsyncTreeViewDialogState extends State<AsyncTreeViewDialog> {
  late List<String> _selected = [];
  @override
  void initState() {
    super.initState();
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
        child: FolderTreeWidget(
          selected: widget.selected,
          items: widget.items,
          selectionMode: widget.selectionMode,
          library: widget.library,
          defaultIcon: widget.defaultIcon,
          type: widget.type,
          onSelectionChanged: (List<String> vals) {
            _selected = vals;
            widget.onSelectionChanged?.call(vals);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed:
              () => Navigator.pop(
                context,
                _selected.map((id) {
                  final item = widget.items.firstWhere(
                    (element) => element.id == id,
                  );
                  return item;
                }).toList(),
              ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
