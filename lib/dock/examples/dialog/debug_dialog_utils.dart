import 'package:flutter/material.dart';
import '../dock_manager.dart';

/// 调试对话框的通用功能
class DebugDialogUtils {
  /// 显示层次结构对话框
  static void showHierarchy(BuildContext context, DockManager manager) {
    final hierarchy = manager.layout.hierarchy(
      indexInfo: true,
      levelInfo: true,
      hasParentInfo: true,
      nameInfo: true,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('布局层次结构'),
            content: SizedBox(
              width: 400,
              height: 300,
              child: SingleChildScrollView(
                child: SelectableText(
                  hierarchy,
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  /// 构建信息行
  static Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label：',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示操作成功的提示
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// 重命名对话框
class RenameDialog extends StatefulWidget {
  final String initialName;
  final ValueChanged<String> onRenamed;

  const RenameDialog({
    super.key,
    required this.initialName,
    required this.onRenamed,
  });

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('重命名'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: '新名称',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        onSubmitted: (_) => _rename(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _rename, child: const Text('确定')),
      ],
    );
  }

  void _rename() {
    final newName = _controller.text.trim();
    if (newName.isNotEmpty) {
      widget.onRenamed(newName);
      Navigator.of(context).pop();
    }
  }
}
