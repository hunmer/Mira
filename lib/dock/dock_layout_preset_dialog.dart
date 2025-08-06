import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/core/storage/storage_manager.dart';
import 'package:mira/dock/dock_layout_controller.dart';
import 'dock_manager.dart';

/// 布局预设对话框
class DockLayoutPresetDialog extends StatefulWidget {
  final String dockTabsId;
  final StorageManager storageManager;

  const DockLayoutPresetDialog({
    super.key,
    required this.dockTabsId,
    required this.storageManager,
  });

  @override
  State<DockLayoutPresetDialog> createState() =>
  // ignore: no_logic_in_create_state
  _DockLayoutPresetDialogState(storageManager);
}

class _DockLayoutPresetDialogState extends State<DockLayoutPresetDialog> {
  List<LayoutPreset> _presets = [];
  String? _defaultPresetId;
  final TextEditingController _nameController = TextEditingController();
  final StorageManager _storageManager;

  _DockLayoutPresetDialogState(this._storageManager) {
    _loadPresets();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// 加载所有布局预设
  void _loadPresets() async {
    final presets = await LayoutPresetManager.getAllPresets();
    final defaultId = await LayoutPresetManager.getDefaultPresetId();
    setState(() {
      _presets = presets;
      _defaultPresetId = defaultId;
    });
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

    try {
      // 获取当前布局数据
      final currentLayout = await DockLayoutController.getLayoutData(
        widget.dockTabsId,
      );
      if (currentLayout == null) {
        _showMessage('无法获取当前布局数据');
        return;
      }

      // 创建新预设
      final preset = LayoutPreset(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        layoutData: currentLayout,
        createdAt: DateTime.now(),
      );

      await LayoutPresetManager.savePreset(preset);
      _nameController.clear();
      _loadPresets();
      _showMessage('布局预设保存成功');
    } catch (e) {
      _showMessage('保存失败: $e');
    }
  }

  /// 删除布局预设
  void _deletePreset(LayoutPreset preset) async {
    final confirmed = await _showConfirmDialog(
      '确认删除',
      '确定要删除布局预设 "${preset.name}" 吗？',
    );
    if (confirmed) {
      await LayoutPresetManager.deletePreset(preset.id);
      // 如果删除的是默认预设，清除默认设置
      if (_defaultPresetId == preset.id) {
        await LayoutPresetManager.setDefaultPreset(null);
      }
      _loadPresets();
      _showMessage('布局预设删除成功');
    }
  }

  /// 设置默认布局预设
  void _setDefaultPreset(String? presetId) async {
    await LayoutPresetManager.setDefaultPreset(presetId);
    setState(() {
      _defaultPresetId = presetId;
    });
    _showMessage(presetId == null ? '已清除默认布局' : '已设置默认布局');
  }

  /// 应用布局预设
  void _applyPreset(LayoutPreset preset) async {
    try {
      // 保存布局数据到存储
      await _storageManager.save(
        '${widget.dockTabsId}_layout',
        preset.layoutData,
      );
      Navigator.of(context).pop(preset.layoutData);
      _showMessage('布局预设应用成功');
    } catch (e) {
      _showMessage('应用失败: $e');
    }
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
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                const Icon(Icons.view_quilt, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '布局预设管理',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
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
                    const Text(
                      '保存当前布局为预设',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
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
            const Text(
              '已保存的布局预设',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  _presets.isEmpty
                      ? const Center(
                        child: Text(
                          '暂无保存的布局预设',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _presets.length,
                        itemBuilder: (context, index) {
                          final preset = _presets[index];
                          final isDefault = _defaultPresetId == preset.id;

                          return Card(
                            child: ListTile(
                              leading: Radio<String>(
                                value: preset.id,
                                groupValue: _defaultPresetId,
                                onChanged: (value) {
                                  _setDefaultPreset(
                                    value == _defaultPresetId ? null : value,
                                  );
                                },
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(preset.name)),
                                  if (isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '默认',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '创建时间: ${_formatDateTime(preset.createdAt)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _applyPreset(preset),
                                    icon: const Icon(Icons.play_arrow),
                                    tooltip: '应用此布局',
                                  ),
                                  IconButton(
                                    onPressed: () => _deletePreset(preset),
                                    icon: const Icon(Icons.delete),
                                    tooltip: '删除此布局',
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

/// 布局预设数据模型
class LayoutPreset {
  final String id;
  final String name;
  final String layoutData;
  final DateTime createdAt;

  LayoutPreset({
    required this.id,
    required this.name,
    required this.layoutData,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'layoutData': layoutData,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LayoutPreset.fromJson(Map<String, dynamic> json) {
    return LayoutPreset(
      id: json['id'],
      name: json['name'],
      layoutData: json['layoutData'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// 布局预设管理器
class LayoutPresetManager {
  static const String _presetsKey = 'dock_layout_presets';
  static const String _presetConfig = 'dock_layout_config';
  static StorageManager get storageManager =>
      PluginManager.instance.getPlugin('libraries')!.storage;
  // static getConfig
  static Future<Map<String, dynamic>> getConfig() async {
    return await storageManager.load(_presetConfig, {'defaultPresetId': ''});
  }

  // static setConfig
  static Future<void> setConfig(String key, String value) async {
    final config = await getConfig();
    config[key] = value;
    await storageManager.save(_presetConfig, config);
  }

  /// 获取所有布局预设
  static Future<List<LayoutPreset>> getAllPresets() async {
    try {
      final presetsJson = await storageManager.load(_presetsKey);
      if (presetsJson == null) return [];

      final List<dynamic> presetsList = presetsJson;
      return presetsList
          .map((json) => LayoutPreset.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('获取布局预设失败: $e');
      return [];
    }
  }

  /// 保存布局预设
  static Future<void> savePreset(LayoutPreset preset) async {
    final presets = await getAllPresets();
    presets.add(preset);
    await _saveAllPresets(presets);
  }

  /// 删除布局预设
  static Future<void> deletePreset(String presetId) async {
    final presets = await getAllPresets();
    presets.removeWhere((preset) => preset.id == presetId);
    await _saveAllPresets(presets);
  }

  /// 保存所有预设
  static Future<void> _saveAllPresets(List<LayoutPreset> presets) async {
    final presetsJson = presets.map((preset) => preset.toJson()).toList();
    await storageManager.save(_presetsKey, presetsJson);
  }

  /// 获取默认布局预设ID
  static Future<String?> getDefaultPresetId() async {
    return getConfig().then((config) => config['defaultPresetId'] as String?);
  }

  /// 设置默认布局预设
  static Future<void> setDefaultPreset(String? presetId) async {
    await setConfig('defaultPresetId', presetId ?? '');
  }

  /// 获取默认布局预设
  static Future<LayoutPreset?> getDefaultPreset() async {
    final defaultId = await getDefaultPresetId();
    if (defaultId == null) return null;

    final presets = await getAllPresets();
    return presets.firstWhereOrNull((preset) => preset.id == defaultId);
  }
}
