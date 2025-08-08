import 'package:flutter/material.dart';
import 'examples/dock_manager.dart';
import 'debug_layout_preset_dialog.dart';

/// 测试调试布局存储管理器的简单示例
class DebugLayoutStorageExample extends StatefulWidget {
  const DebugLayoutStorageExample({super.key});

  @override
  State<DebugLayoutStorageExample> createState() =>
      _DebugLayoutStorageExampleState();
}

class _DebugLayoutStorageExampleState extends State<DebugLayoutStorageExample> {
  late DockManager manager;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initManager();
  }

  void _initManager() {
    // 创建 DockManager 用于测试
    manager = DockManager(id: 'debug_test', autoSave: false);
    _addLog('DockManager 初始化完成');
  }

  void _addLog(String message) {
    if (mounted) {
      setState(() {
        _logs.add('${TimeOfDay.now().format(context)}: $message');
      });
    }
  }

  /// 显示调试布局存储管理器
  void _showDebugLayoutManager() {
    showDialog(
      context: context,
      builder: (context) => DebugLayoutPresetDialog(manager: manager),
    ).then((result) {
      if (result != null) {
        _addLog('布局预设应用完成');
      }
    });
  }

  /// 测试保存当前数据
  void _testSaveCurrentData() async {
    try {
      final data = manager.getCurrentData();
      if (data != null) {
        _addLog('成功获取当前布局数据: ${data.layout.length} 字符');
        _addLog('包含 ${data.items.length} 个项目');
      } else {
        _addLog('获取当前布局数据失败');
      }
    } catch (e) {
      _addLog('测试保存数据时出错: $e');
    }
  }

  /// 测试直接保存到文件
  void _testSaveToFile() async {
    try {
      await manager.saveToFile();
      _addLog('布局已保存到文件');
    } catch (e) {
      _addLog('保存到文件时出错: $e');
    }
  }

  /// 测试从文件恢复
  void _testRestoreFromFile() async {
    try {
      final success = await manager.restoreFromFile();
      if (success) {
        _addLog('从文件恢复布局成功');
      } else {
        _addLog('从文件恢复布局失败或无保存数据');
      }
    } catch (e) {
      _addLog('从文件恢复时出错: $e');
    }
  }

  /// 清理日志
  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试布局存储管理器示例'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.clear_all),
            tooltip: '清除日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 控制面板
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '测试控制面板',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showDebugLayoutManager,
                        icon: const Icon(Icons.storage),
                        label: const Text('打开调试管理器'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _testSaveCurrentData,
                        icon: const Icon(Icons.info),
                        label: const Text('获取当前数据'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _testSaveToFile,
                        icon: const Icon(Icons.save),
                        label: const Text('保存到文件'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _testRestoreFromFile,
                        icon: const Icon(Icons.restore),
                        label: const Text('从文件恢复'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 日志显示区域
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.terminal),
                        const SizedBox(width: 8),
                        const Text(
                          '操作日志',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_logs.length} 条',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child:
                        _logs.isEmpty
                            ? const Center(
                              child: Text(
                                '暂无日志，点击上方按钮开始测试',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    _logs[index],
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDebugLayoutManager,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.storage),
        label: const Text('调试管理器'),
      ),
    );
  }
}
