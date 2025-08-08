import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';

/// 调试布局存储管理器
/// 使用本地JSON文件存储，不依赖storage，适合调试环境
class DebugLayoutStorageManager {
  static const String _layoutsFileName = 'debug_dock_layouts.json';
  static const String _configFileName = 'debug_dock_config.json';

  static String? _applicationDocumentsPath;
  static File? _layoutsFile;
  static File? _configFile;

  /// 初始化存储管理器
  static Future<void> init() async {
    if (_applicationDocumentsPath == null) {
      if (kIsWeb) {
        // Web环境使用虚拟路径
        _applicationDocumentsPath = 'web_storage';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        _applicationDocumentsPath = directory.path;
      }

      _layoutsFile = File('$_applicationDocumentsPath/$_layoutsFileName');
      _configFile = File('$_applicationDocumentsPath/$_configFileName');
    }
  }

  /// 获取布局文件路径
  static Future<String> get layoutsFilePath async {
    await init();
    return _layoutsFile!.path;
  }

  /// 获取配置文件路径
  static Future<String> get configFilePath async {
    await init();
    return _configFile!.path;
  }

  /// 获取所有布局预设
  static Future<List<DebugLayoutPreset>> getAllPresets() async {
    try {
      await init();

      if (!await _layoutsFile!.exists()) {
        return [];
      }

      final content = await _layoutsFile!.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);

      return jsonList
          .map(
            (json) => DebugLayoutPreset.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('DebugLayoutStorageManager: 获取布局预设失败: $e');
      return [];
    }
  }

  /// 保存布局预设
  static Future<void> savePreset(DebugLayoutPreset preset) async {
    final presets = await getAllPresets();

    // 检查是否已存在，如果存在则更新
    final existingIndex = presets.indexWhere((p) => p.id == preset.id);
    if (existingIndex >= 0) {
      presets[existingIndex] = preset;
    } else {
      presets.add(preset);
    }

    await _saveAllPresets(presets);
  }

  /// 删除布局预设
  static Future<void> deletePreset(String presetId) async {
    final presets = await getAllPresets();
    presets.removeWhere((preset) => preset.id == presetId);
    await _saveAllPresets(presets);
  }

  /// 保存所有预设到文件
  static Future<void> _saveAllPresets(List<DebugLayoutPreset> presets) async {
    try {
      await init();

      final jsonList = presets.map((preset) => preset.toJson()).toList();
      final content = jsonEncode(jsonList);

      await _layoutsFile!.writeAsString(content);
      print('DebugLayoutStorageManager: 已保存 ${presets.length} 个布局预设');
    } catch (e) {
      print('DebugLayoutStorageManager: 保存布局预设失败: $e');
      rethrow;
    }
  }

  /// 获取配置
  static Future<Map<String, dynamic>> getConfig() async {
    try {
      await init();

      if (!await _configFile!.exists()) {
        return {'defaultPresetId': '', 'autoSave': true};
      }

      final content = await _configFile!.readAsString();
      return Map<String, dynamic>.from(jsonDecode(content));
    } catch (e) {
      print('DebugLayoutStorageManager: 获取配置失败: $e');
      return {'defaultPresetId': '', 'autoSave': true};
    }
  }

  /// 设置配置
  static Future<void> setConfig(String key, dynamic value) async {
    final config = await getConfig();
    config[key] = value;
    await _saveConfig(config);
  }

  /// 保存配置
  static Future<void> _saveConfig(Map<String, dynamic> config) async {
    try {
      await init();

      final content = jsonEncode(config);
      await _configFile!.writeAsString(content);
    } catch (e) {
      print('DebugLayoutStorageManager: 保存配置失败: $e');
      rethrow;
    }
  }

  /// 获取默认布局预设ID
  static Future<String?> getDefaultPresetId() async {
    final config = await getConfig();
    final defaultId = config['defaultPresetId'] as String?;
    return (defaultId?.isEmpty ?? true) ? null : defaultId;
  }

  /// 设置默认布局预设
  static Future<void> setDefaultPreset(String? presetId) async {
    await setConfig('defaultPresetId', presetId ?? '');
  }

  /// 获取默认布局预设
  static Future<DebugLayoutPreset?> getDefaultPreset() async {
    final defaultId = await getDefaultPresetId();
    if (defaultId == null) return null;

    final presets = await getAllPresets();
    return presets.firstWhereOrNull((preset) => preset.id == defaultId);
  }

  /// 导出所有布局到JSON字符串
  static Future<String> exportAllLayouts() async {
    final presets = await getAllPresets();
    final config = await getConfig();

    final exportData = {
      'presets': presets.map((p) => p.toJson()).toList(),
      'config': config,
      'exportTime': DateTime.now().toIso8601String(),
      'version': '1.0',
    };

    return jsonEncode(exportData);
  }

  /// 从JSON字符串导入布局
  static Future<int> importLayoutsFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      final List<dynamic> presetsData = data['presets'] ?? [];
      final List<DebugLayoutPreset> importedPresets =
          presetsData
              .map(
                (json) =>
                    DebugLayoutPreset.fromJson(json as Map<String, dynamic>),
              )
              .toList();

      // 合并现有预设
      final existingPresets = await getAllPresets();
      final Map<String, DebugLayoutPreset> presetsMap = {
        for (var preset in existingPresets) preset.id: preset,
      };

      // 添加或更新导入的预设
      for (var preset in importedPresets) {
        presetsMap[preset.id] = preset;
      }

      await _saveAllPresets(presetsMap.values.toList());

      // 导入配置（如果有）
      if (data.containsKey('config')) {
        final importedConfig = data['config'] as Map<String, dynamic>;
        final currentConfig = await getConfig();

        // 合并配置，保留当前的某些设置
        currentConfig.addAll(importedConfig);
        await _saveConfig(currentConfig);
      }

      return importedPresets.length;
    } catch (e) {
      print('DebugLayoutStorageManager: 导入布局失败: $e');
      rethrow;
    }
  }

  /// 清除所有数据
  static Future<void> clearAllData() async {
    try {
      await init();

      if (await _layoutsFile!.exists()) {
        await _layoutsFile!.delete();
      }

      if (await _configFile!.exists()) {
        await _configFile!.delete();
      }

      print('DebugLayoutStorageManager: 已清除所有数据');
    } catch (e) {
      print('DebugLayoutStorageManager: 清除数据失败: $e');
      rethrow;
    }
  }

  /// 获取存储统计信息
  static Future<Map<String, dynamic>> getStorageStats() async {
    await init();

    final presets = await getAllPresets();
    final config = await getConfig();

    int totalSize = 0;
    if (await _layoutsFile!.exists()) {
      totalSize += await _layoutsFile!.length();
    }
    if (await _configFile!.exists()) {
      totalSize += await _configFile!.length();
    }

    return {
      'presetsCount': presets.length,
      'configKeys': config.keys.length,
      'totalSizeBytes': totalSize,
      'layoutsFilePath': _layoutsFile!.path,
      'configFilePath': _configFile!.path,
      'layoutsFileExists': await _layoutsFile!.exists(),
      'configFileExists': await _configFile!.exists(),
    };
  }
}

/// 调试布局预设数据模型
class DebugLayoutPreset {
  final String id;
  final String name;
  final String layoutData;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? description;
  final Map<String, dynamic>? metadata;

  DebugLayoutPreset({
    required this.id,
    required this.name,
    required this.layoutData,
    required this.createdAt,
    this.updatedAt,
    this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'layoutData': layoutData,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory DebugLayoutPreset.fromJson(Map<String, dynamic> json) {
    return DebugLayoutPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      layoutData: json['layoutData'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 创建副本并更新某些字段
  DebugLayoutPreset copyWith({
    String? id,
    String? name,
    String? layoutData,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return DebugLayoutPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      layoutData: layoutData ?? this.layoutData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 获取预设大小（字节）
  int get sizeInBytes {
    final jsonString = jsonEncode(toJson());
    return utf8.encode(jsonString).length;
  }

  /// 获取可读的大小字符串
  String get readableSize {
    final bytes = sizeInBytes;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
