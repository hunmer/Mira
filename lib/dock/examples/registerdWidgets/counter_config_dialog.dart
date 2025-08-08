import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 计数器组件配置对话框
class CounterConfigDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onConfirm;

  const CounterConfigDialog({Key? key, required this.onConfirm})
    : super(key: key);

  @override
  State<CounterConfigDialog> createState() => _CounterConfigDialogState();
}

class _CounterConfigDialogState extends State<CounterConfigDialog> {
  final _nameController = TextEditingController();
  final _initialValueController = TextEditingController();
  int _initialValue = 0;
  String _name = '计数器';

  @override
  void initState() {
    super.initState();
    _nameController.text = _name;
    _initialValueController.text = _initialValue.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialValueController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final values = {
      'count': _initialValue,
      'name': _name.isEmpty ? '计数器' : _name,
    };
    widget.onConfirm(values);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text('添加计数器组件', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),

            // 组件名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '组件名称',
                hintText: '请输入组件显示名称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              onChanged: (value) {
                setState(() {
                  _name = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // 初始值
            TextField(
              controller: _initialValueController,
              decoration: const InputDecoration(
                labelText: '初始值',
                hintText: '请输入计数器的初始值',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
              ],
              onChanged: (value) {
                setState(() {
                  _initialValue = int.tryParse(value) ?? 0;
                });
              },
            ),
            const SizedBox(height: 16),

            // 预览
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '预览',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _name.isEmpty ? '计数器' : _name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        '初始值: $_initialValue',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onConfirm,
                  child: const Text('确认添加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
