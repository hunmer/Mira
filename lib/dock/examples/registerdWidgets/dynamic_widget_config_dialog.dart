import 'dart:convert';
import 'package:flutter/material.dart';
import 'dynamic_widget.dart';

/// Dynamic Widget 配置对话框
class DynamicWidgetConfigDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onConfirm;

  const DynamicWidgetConfigDialog({super.key, required this.onConfirm});

  @override
  State<DynamicWidgetConfigDialog> createState() =>
      _DynamicWidgetConfigDialogState();
}

class _DynamicWidgetConfigDialogState extends State<DynamicWidgetConfigDialog> {
  final _nameController = TextEditingController();
  final _jsonController = TextEditingController();
  String _name = 'Dynamic Widget';
  String _selectedPreset = 'simpleText';

  final Map<String, String> _presets = {
    'simpleText': '简单文本',
    'welcomeCard': '欢迎卡片',
  };

  @override
  void initState() {
    super.initState();
    _nameController.text = _name;
    _updateJsonFromPreset();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  void _updateJsonFromPreset() {
    final jsonData = _getPresetData();
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    _jsonController.text = encoder.convert(jsonData);
  }

  Map<String, dynamic> _getPresetData() {
    switch (_selectedPreset) {
      case 'simpleText':
        return DynamicWidgetPresets.simpleText;
      case 'welcomeCard':
        return DynamicWidgetPresets.welcomeCard;
      default:
        return DynamicWidgetPresets.simpleText;
    }
  }

  void _onConfirm() {
    try {
      // 尝试解析 JSON
      final jsonData = jsonDecode(_jsonController.text) as Map<String, dynamic>;
      final values = {
        'jsonData': jsonData,
        'name': _name.isEmpty ? 'Dynamic Widget' : _name,
      };
      widget.onConfirm(values);
    } catch (e) {
      // 显示 JSON 解析错误
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON 格式错误: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.widgets, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  '添加 Dynamic Widget 组件',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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

            // 预设模板选择
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('选择预设模板', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._presets.entries.map((entry) {
                  return RadioListTile<String>(
                    title: Text(entry.value),
                    subtitle: _getPresetDescription(entry.key),
                    value: entry.key,
                    groupValue: _selectedPreset,
                    onChanged: (value) {
                      setState(() {
                        _selectedPreset = value!;
                        _updateJsonFromPreset();
                      });
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),

            // JSON 编辑器
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JSON 配置', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _jsonController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    decoration: const InputDecoration(
                      hintText: '请输入或编辑 JSON 配置...',
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _updateJsonFromPreset();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('重置为预设'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        try {
                          // 验证 JSON 格式
                          jsonDecode(_jsonController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('JSON 格式正确'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('JSON 格式错误: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('验证格式'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
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

  Widget? _getPresetDescription(String preset) {
    final descriptions = {
      'simpleText': '显示简单的文本内容',
      'welcomeCard': '包含标题和内容的卡片布局',
    };

    final description = descriptions[preset];
    if (description != null) {
      return Text(
        description,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      );
    }
    return null;
  }
}
