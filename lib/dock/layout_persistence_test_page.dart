import 'package:flutter/material.dart';
import 'package:mira/dock/dock_manager.dart';

/// 布局持久化测试页面
class LayoutPersistenceTestPage extends StatefulWidget {
  const LayoutPersistenceTestPage({super.key});

  @override
  State<LayoutPersistenceTestPage> createState() =>
      _LayoutPersistenceTestPageState();
}

class _LayoutPersistenceTestPageState extends State<LayoutPersistenceTestPage> {
  final List<String> _layoutKeys = [];
  String _selectedLayoutKey = '';
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshLayoutKeys();
  }

  void _refreshLayoutKeys() {
    setState(() {
      _layoutKeys.clear();
      // 这里可以添加获取所有布局键的逻辑
      // 暂时添加一些示例键
      _layoutKeys.addAll(['main_layout', 'example_layout', 'test_layout']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('布局持久化测试'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '保存布局',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _keyController,
                      decoration: const InputDecoration(
                        labelText: '布局键',
                        hintText: '例如: my_custom_layout',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dataController,
                      decoration: const InputDecoration(
                        labelText: '布局数据',
                        hintText: '输入布局JSON数据',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saveLayout,
                          icon: const Icon(Icons.save),
                          label: const Text('保存布局'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _generateSampleData,
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('生成示例数据'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '加载布局',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value:
                          _selectedLayoutKey.isEmpty
                              ? null
                              : _selectedLayoutKey,
                      decoration: const InputDecoration(
                        labelText: '选择布局',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _layoutKeys.map((key) {
                            return DropdownMenuItem(
                              value: key,
                              child: Text(key),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLayoutKey = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              _selectedLayoutKey.isEmpty ? null : _loadLayout,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('加载布局'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed:
                              _selectedLayoutKey.isEmpty ? null : _deleteLayout,
                          icon: const Icon(Icons.delete),
                          label: const Text('删除布局'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _refreshLayoutKeys,
                          icon: const Icon(Icons.refresh),
                          tooltip: '刷新列表',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '操作',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _clearAllLayouts,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('清除所有布局'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _showLayoutInfo,
                          icon: const Icon(Icons.info),
                          label: const Text('查看布局信息'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateSampleData() {
    final sampleData = '''
{
  "type": "docking_layout",
  "version": "1.0",
  "tabs": {
    "home": {
      "displayName": "首页",
      "items": [
        {
          "type": "text",
          "title": "示例文本",
          "values": {
            "content": "这是一个示例文本内容"
          }
        }
      ]
    }
  },
  "activeTab": "home"
}''';
    _dataController.text = sampleData;
    _keyController.text =
        'test_layout_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _saveLayout() {
    final key = _keyController.text.trim();
    final data = _dataController.text.trim();

    if (key.isEmpty || data.isEmpty) {
      _showMessage('请输入布局键和数据');
      return;
    }

    try {
      DockManager.storeLayout(key, data);
      _showMessage('布局保存成功: $key');
      _refreshLayoutKeys();
      _keyController.clear();
      _dataController.clear();
    } catch (e) {
      _showMessage('保存失败: $e');
    }
  }

  void _loadLayout() {
    try {
      final data = DockManager.getStoredLayout(_selectedLayoutKey);
      if (data != null) {
        _dataController.text = data;
        _showMessage('布局加载成功: $_selectedLayoutKey');
      } else {
        _showMessage('布局不存在: $_selectedLayoutKey');
      }
    } catch (e) {
      _showMessage('加载失败: $e');
    }
  }

  void _deleteLayout() {
    try {
      DockManager.clearStoredLayout(_selectedLayoutKey);
      _showMessage('布局删除成功: $_selectedLayoutKey');
      _refreshLayoutKeys();
      setState(() {
        _selectedLayoutKey = '';
      });
    } catch (e) {
      _showMessage('删除失败: $e');
    }
  }

  void _clearAllLayouts() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要清除所有保存的布局吗？此操作不可恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  try {
                    DockManager.clearAllStoredLayouts();
                    _showMessage('所有布局已清除');
                    _refreshLayoutKeys();
                    setState(() {
                      _selectedLayoutKey = '';
                    });
                  } catch (e) {
                    _showMessage('清除失败: $e');
                  }
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  void _showLayoutInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('布局信息'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('总布局数量: ${_layoutKeys.length}'),
                const SizedBox(height: 8),
                const Text('布局存储说明:'),
                const SizedBox(height: 4),
                const Text('• 布局数据保存在应用的持久化存储中'),
                const Text('• 应用重启后布局数据会自动加载'),
                const Text('• 支持多个不同的布局配置'),
                const Text('• 布局数据以JSON格式存储'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _dataController.dispose();
    super.dispose();
  }
}
