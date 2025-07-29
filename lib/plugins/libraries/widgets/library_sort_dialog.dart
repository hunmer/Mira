import 'package:flutter/material.dart';

class LibrarySortDialog extends StatefulWidget {
  final Map<String, dynamic>? initialSortOptions;

  const LibrarySortDialog({super.key, this.initialSortOptions});

  @override
  State<LibrarySortDialog> createState() => _LibrarySortDialogState();
}

class _LibrarySortDialogState extends State<LibrarySortDialog> {
  String _sortField = 'imported_at';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    if (widget.initialSortOptions != null) {
      _sortField = widget.initialSortOptions!['sort'] ?? 'imported_at';
      _sortOrder = widget.initialSortOptions!['order'] ?? 'desc';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('排序选项'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _sortField,
            decoration: const InputDecoration(labelText: '排序字段'),
            items: const [
              DropdownMenuItem(value: 'imported_at', child: Text('导入日期')),
              DropdownMenuItem(value: 'id', child: Text('ID')),
              DropdownMenuItem(value: 'size', child: Text('文件大小')),
              DropdownMenuItem(value: 'stars', child: Text('星级')),
              DropdownMenuItem(value: 'folder_id', child: Text('文件夹ID')),
              DropdownMenuItem(value: 'tags', child: Text('标签')),
              DropdownMenuItem(value: 'name', child: Text('名称')),
              DropdownMenuItem(value: 'custom_fields', child: Text('自定义字段')),
            ],
            onChanged: (value) {
              setState(() {
                _sortField = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _sortOrder,
            decoration: const InputDecoration(labelText: '排序方向'),
            items: const [
              DropdownMenuItem(value: 'asc', child: Text('升序')),
              DropdownMenuItem(value: 'desc', child: Text('降序')),
            ],
            onChanged: (value) {
              setState(() {
                _sortOrder = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed:
              () => Navigator.pop(context, {
                'sort': _sortField,
                'order': _sortOrder,
              }),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
