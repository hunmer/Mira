import 'package:flutter/material.dart';

/// Dynamic Widget 配置对话框
class DynamicWidgetConfigDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onConfirm;

  const DynamicWidgetConfigDialog({Key? key, required this.onConfirm})
    : super(key: key);

  @override
  State<DynamicWidgetConfigDialog> createState() =>
      _DynamicWidgetConfigDialogState();
}

class _DynamicWidgetConfigDialogState extends State<DynamicWidgetConfigDialog> {
  final _nameController = TextEditingController();
  String _name = 'Dynamic Widget';
  String _selectedPreset = 'welcomeCard';

  final Map<String, String> _presets = {
    'welcomeCard': '欢迎卡片',
    'featureList': '功能列表',
    'counterExample': '计数器示例',
  };

  @override
  void initState() {
    super.initState();
    _nameController.text = _name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getPresetData() {
    switch (_selectedPreset) {
      case 'welcomeCard':
        return {
          'type': 'card',
          'args': {
            'margin': {'all': 16},
            'elevation': 4,
            'child': {
              'type': 'padding',
              'args': {
                'padding': {'all': 20},
                'child': {
                  'type': 'text',
                  'args': {
                    'data': '欢迎使用 Dynamic Widget',
                    'style': {
                      'fontSize': 18,
                      'fontWeight': 'bold',
                      'color': '#1976D2',
                    },
                  },
                },
              },
            },
          },
        };
      case 'featureList':
        return {
          'type': 'column',
          'args': {
            'children': [
              {
                'type': 'list_tile',
                'args': {
                  'leading': {
                    'type': 'icon',
                    'args': {
                      'icon': 59534, // Icons.build.codePoint
                      'color': '#4CAF50',
                    },
                  },
                  'title': {
                    'type': 'text',
                    'args': {'data': '动态构建'},
                  },
                  'subtitle': {
                    'type': 'text',
                    'args': {'data': '通过 JSON 动态构建 Widget'},
                  },
                },
              },
            ],
          },
        };
      case 'counterExample':
        return {
          'type': 'container',
          'args': {
            'padding': {'all': 16},
            'decoration': {'color': '#F5F5F5', 'borderRadius': 12},
            'child': {
              'type': 'column',
              'args': {
                'mainAxisAlignment': 'center',
                'children': [
                  {
                    'type': 'text',
                    'args': {
                      'data': '计数器示例',
                      'style': {'fontSize': 18, 'fontWeight': 'bold'},
                    },
                  },
                ],
              },
            },
          },
        };
      default:
        return {
          'type': 'text',
          'args': {'data': 'Dynamic Widget'},
        };
    }
  }

  void _onConfirm() {
    final values = {
      'jsonData': _getPresetData(),
      'name': _name.isEmpty ? 'Dynamic Widget' : _name,
    };
    widget.onConfirm(values);
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
                      });
                    },
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: 16),

            // 预览区域
            Container(
              width: double.infinity,
              height: 200,
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '预设: ${_presets[_selectedPreset]}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
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

  Widget? _getPresetDescription(String preset) {
    final descriptions = {
      'welcomeCard': '包含图标、标题和按钮的欢迎卡片',
      'featureList': '展示功能特性的列表布局',
      'counterExample': '带计数功能的交互式组件',
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
