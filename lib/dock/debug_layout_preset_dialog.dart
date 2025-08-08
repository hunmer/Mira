import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'examples/dock_manager.dart';
import 'examples/dock_persistence.dart';
import 'debug_layout_storage_manager.dart';

/// 调试布局预设管理对话框
class DebugLayoutPresetDialog extends StatefulWidget {
  final DockManager manager;

  const DebugLayoutPresetDialog({super.key, required this.manager});

  @override
  State<DebugLayoutPresetDialog> createState() =>
      _DebugLayoutPresetDialogState();
}

class _DebugLayoutPresetDialogState extends State<DebugLayoutPresetDialog> {
  List<DebugLayoutPreset> _presets = [];
  String? _defaultPresetId;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic> _storageStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 加载所有数据
  void _loadData() async {
    setState(() => _isLoading = true);

    try {
      final presets = await DebugLayoutStorageManager.getAllPresets();
      final defaultId = await DebugLayoutStorageManager.getDefaultPresetId();
      final stats = await DebugLayoutStorageManager.getStorageStats();

      setState(() {
        _presets = presets;
        _defaultPresetId = defaultId;
        _storageStats = stats;
      });
    } catch (e) {
      _showMessage('加载数据失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 保存新的布局预设
  void _saveNewPreset() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('请输入布局名称');
      return;
    }

    // 检查名称是否已存在
    if (_presets.any((preset) => preset.name == name)) {
      _showMessage('布局名称已存在');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 从 DockManager 获取当前布局数据
      final persistenceData = widget.manager.getCurrentData();
      if (persistenceData == null) {
        _showMessage('无法获取当前布局数据');
        return;
      }

      // 将 DockPersistenceData 转换为 JSON 字符串
      final layoutData = jsonEncode(persistenceData.toJson());

      // 创建新预设
      final preset = DebugLayoutPreset(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        layoutData: layoutData,
        createdAt: DateTime.now(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        metadata: {
          'managerId': widget.manager.id,
          'dataSize': layoutData.length,
        },
      );

      await DebugLayoutStorageManager.savePreset(preset);
      _nameController.clear();
      _descriptionController.clear();
      _loadData();
      _showMessage('布局预设保存成功');
    } catch (e) {
      _showMessage('保存失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 删除布局预设
  void _deletePreset(DebugLayoutPreset preset) async {
    final confirmed = await _showConfirmDialog(
      '确认删除',
      '确定要删除布局预设 "${preset.name}" 吗？\n\n这个操作无法撤销。',
    );
    if (confirmed) {
      setState(() => _isLoading = true);

      try {
        await DebugLayoutStorageManager.deletePreset(preset.id);
        // 如果删除的是默认预设，清除默认设置
        if (_defaultPresetId == preset.id) {
          await DebugLayoutStorageManager.setDefaultPreset(null);
        }
        _loadData();
        _showMessage('布局预设删除成功');
      } catch (e) {
        _showMessage('删除失败: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 设置默认布局预设
  void _setDefaultPreset(String? presetId) async {
    setState(() => _isLoading = true);

    try {
      await DebugLayoutStorageManager.setDefaultPreset(presetId);
      setState(() => _defaultPresetId = presetId);
      _showMessage(presetId == null ? '已清除默认布局' : '已设置默认布局');
    } catch (e) {
      _showMessage('设置默认布局失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 应用布局预设
  void _applyPreset(DebugLayoutPreset preset) async {
    setState(() => _isLoading = true);

    try {
      // 将预设的布局数据转换为 DockPersistenceData
      final Map<String, dynamic> jsonData = jsonDecode(preset.layoutData);
      final persistenceData = DockPersistenceData.fromJson(jsonData);

      // 使用 DockManager 加载布局数据
      final success = widget.manager.loadFromData(persistenceData);

      if (success) {
        Navigator.of(context).pop(preset.layoutData);
        _showMessage('布局预设应用成功');
      } else {
        _showMessage('应用布局失败');
      }
    } catch (e) {
      _showMessage('应用失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 导出所有布局
  void _exportLayouts() async {
    setState(() => _isLoading = true);

    try {
      final jsonData = await DebugLayoutStorageManager.exportAllLayouts();
      await Clipboard.setData(ClipboardData(text: jsonData));
      _showMessage('布局数据已复制到剪贴板');
    } catch (e) {
      _showMessage('导出失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 导入布局
  void _importLayouts() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('导入布局数据'),
            content: SizedBox(
              width: 400,
              height: 300,
              child: Column(
                children: [
                  const Text('请粘贴布局JSON数据：'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '粘贴JSON数据...',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('导入'),
              ),
            ],
          ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);

      try {
        final count = await DebugLayoutStorageManager.importLayoutsFromJson(
          result,
        );
        _loadData();
        _showMessage('成功导入 $count 个布局预设');
      } catch (e) {
        _showMessage('导入失败: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 清除所有数据
  void _clearAllData() async {
    final confirmed = await _showConfirmDialog(
      '危险操作',
      '确定要清除所有布局数据吗？\n\n这将删除所有保存的布局预设和配置，此操作无法撤销！',
    );

    if (confirmed) {
      setState(() => _isLoading = true);

      try {
        await DebugLayoutStorageManager.clearAllData();
        _loadData();
        _showMessage('所有数据已清除');
      } catch (e) {
        _showMessage('清除数据失败: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 显示存储统计
  void _showStorageStats() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('存储统计信息'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatRow('预设数量', '${_storageStats['presetsCount']}'),
                  _buildStatRow('配置项', '${_storageStats['configKeys']}'),
                  _buildStatRow(
                    '总大小',
                    _formatBytes(_storageStats['totalSizeBytes'] ?? 0),
                  ),
                  const Divider(),
                  _buildStatRow(
                    '布局文件路径',
                    '${_storageStats['layoutsFilePath']}',
                    isPath: true,
                  ),
                  _buildStatRow(
                    '配置文件路径',
                    '${_storageStats['configFilePath']}',
                    isPath: true,
                  ),
                  _buildStatRow(
                    '布局文件存在',
                    '${_storageStats['layoutsFileExists']}',
                  ),
                  _buildStatRow(
                    '配置文件存在',
                    '${_storageStats['configFileExists']}',
                  ),
                ],
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

  Widget _buildStatRow(String label, String value, {bool isPath = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: isPath ? 'monospace' : null,
                fontSize: isPath ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// 显示消息
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 显示确认对话框
  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确定'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题栏
                    Row(
                      children: [
                        const Icon(
                          Icons.bug_report,
                          size: 24,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '调试布局存储管理器',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Tooltip(
                          message: '存储统计信息',
                          child: IconButton(
                            onPressed: _showStorageStats,
                            icon: const Icon(Icons.analytics),
                          ),
                        ),
                        Tooltip(
                          message: '导出所有布局',
                          child: IconButton(
                            onPressed: _exportLayouts,
                            icon: const Icon(Icons.upload),
                          ),
                        ),
                        Tooltip(
                          message: '导入布局',
                          child: IconButton(
                            onPressed: _importLayouts,
                            icon: const Icon(Icons.download),
                          ),
                        ),
                        Tooltip(
                          message: '清除所有数据',
                          child: IconButton(
                            onPressed: _clearAllData,
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),

                    // 新建预设区域
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.save, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  '保存当前布局为预设',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      hintText: '输入布局名称',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _descriptionController,
                                    decoration: const InputDecoration(
                                      hintText: '可选：添加描述',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _saveNewPreset,
                                  icon: const Icon(Icons.save, size: 16),
                                  label: const Text('保存'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 预设列表
                    Row(
                      children: [
                        const Icon(Icons.folder, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          '已保存的布局预设',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          '共 ${_presets.length} 个预设',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child:
                          _presets.isEmpty
                              ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      '暂无保存的布局预设',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                itemCount: _presets.length,
                                itemBuilder: (context, index) {
                                  final preset = _presets[index];
                                  final isDefault =
                                      _defaultPresetId == preset.id;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: ListTile(
                                      leading: Radio<String>(
                                        value: preset.id,
                                        groupValue: _defaultPresetId,
                                        onChanged: (value) {
                                          _setDefaultPreset(
                                            value == _defaultPresetId
                                                ? null
                                                : value,
                                          );
                                        },
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(child: Text(preset.name)),
                                          if (isDefault)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                '默认',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              preset.readableSize,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '创建: ${_formatDateTime(preset.createdAt)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (preset.description != null)
                                            Text(
                                              preset.description!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Tooltip(
                                            message: '应用此布局',
                                            child: IconButton(
                                              onPressed:
                                                  () => _applyPreset(preset),
                                              icon: const Icon(
                                                Icons.play_arrow,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                          Tooltip(
                                            message: '删除此布局',
                                            child: IconButton(
                                              onPressed:
                                                  () => _deletePreset(preset),
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
