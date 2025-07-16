// ignore_for_file: unused_element

import 'dart:convert';
import 'package:mira/core/config_manager.dart';
import 'package:flutter/material.dart';
import 'plugin_base.dart';
import 'storage/storage_manager.dart';

/// 插件管理器，负责管理所有已注册的插件
class PluginManager {
  StorageManager? _storageManager;
  Map<String, int> _pluginAccessTimes = {};
  static const String _accessTimesStorageKey = 'configs/plugin_access_times';
  static const String _settingsStorageKey = 'configs/plugin_manager_settings';
  PluginBase? _currentPlugin; // 当前打开的插件
  // 单例实例
  static final PluginManager _instance = PluginManager._internal();

  // 私有构造函数
  PluginManager._internal();

  // 工厂构造函数
  factory PluginManager() => _instance;

  // 获取单例实例
  static PluginManager get instance => _instance;

  // 设置存储管理器并初始化数据
  Future<void> setStorageManager(StorageManager manager) async {
    _storageManager = manager;

    // 设置存储管理器后加载数据
    await _loadAccessTimes();
    await _loadSettings();
  }

  // 获取存储管理器
  StorageManager? get storageManager => _storageManager;

  final List<PluginBase> _plugins = [];

  /// 注册插件
  Future<void> registerPlugin(PluginBase plugin) async {
    if (!_plugins.any((p) => p.id == plugin.id)) {
      if (_storageManager != null) {
        plugin.setStorageManager(_storageManager!);
      }
      _plugins.add(plugin);
      await plugin.registerToApp(this, ConfigManager(_storageManager!));
    }
  }

  /// 获取所有已注册的插件
  /// [sortByRecentlyOpened] 是否按最近打开时间排序
  List<PluginBase> getAllPlugins({bool sortByRecentlyOpened = false}) {
    if (!sortByRecentlyOpened) {
      return List.unmodifiable(_plugins);
    }

    // 创建插件列表的副本并按访问时间排序
    final sortedPlugins = List<PluginBase>.from(_plugins);
    sortedPlugins.sort((a, b) {
      final timeA = _pluginAccessTimes[a.id] ?? 0;
      final timeB = _pluginAccessTimes[b.id] ?? 0;
      return timeB.compareTo(timeA); // 降序排列，最近的在前
    });
    return List.unmodifiable(sortedPlugins);
  }

  /// 获取所有已注册的插件（向后兼容的getter）
  List<PluginBase> get allPlugins => getAllPlugins();

  /// 根据ID获取插件
  PluginBase? getPlugin(String id) {
    try {
      return _plugins.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 移除插件
  Future<void> removePlugin(String id) async {
    _plugins.removeWhere((p) => p.id == id);
  }

  /// 加载插件访问时间记录
  Future<void> _loadAccessTimes() async {
    // 确保初始化为空Map
    _pluginAccessTimes = {};

    if (_storageManager == null) return;

    try {
      final data = await _storageManager!.read(_accessTimesStorageKey);
      if (data.isNotEmpty) {
        _pluginAccessTimes = Map<String, int>.from(
          data.map((key, value) => MapEntry(key, value as int)),
        );
      }
    } catch (e) {
      debugPrint('Warning: Failed to load plugin access times: $e');
      // 保持使用空Map
    }
  }

  /// 保存插件访问时间记录
  Future<void> _saveAccessTimes() async {
    if (_storageManager == null) return;

    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        _pluginAccessTimes,
      );
      await _storageManager!.write(_accessTimesStorageKey, data);
    } catch (e) {
      debugPrint('Warning: Failed to save plugin access times: $e');
    }
  }

  /// 更新插件访问时间
  Future<void> _updatePluginAccessTime(String pluginId) async {
    _pluginAccessTimes[pluginId] = DateTime.now().millisecondsSinceEpoch;
    await _saveAccessTimes();
  }

  /// 获取当前打开的插件
  PluginBase? getCurrentPlugin() => _currentPlugin;

  /// 获取当前打开的插件ID
  String? getCurrentPluginId() => _currentPlugin?.id;

  /// 加载设置
  Future<void> _loadSettings() async {
    if (_storageManager == null) return;

    try {
      final settings = await _storageManager!.readFile(
        _settingsStorageKey,
        '{}',
      );
      final data = jsonDecode(settings);
    } catch (e) {}
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    if (_storageManager == null) return;

    try {
      final settings = jsonEncode({});
      await _storageManager!.writeFile(_settingsStorageKey, settings);
    } catch (e) {
      debugPrint('Warning: Failed to save plugin manager settings: $e');
    }
  }

  /// 打开插件界面
  void openPlugin(BuildContext context, PluginBase plugin) {
    // 检查当前路由是否已经是该插件
    bool isPluginAlreadyOpen =
        ModalRoute.of(context)?.settings.name == '/${plugin.id}';
    if (isPluginAlreadyOpen) {
      return;
    }
    _currentPlugin = plugin; // 记录当前打开的插件
    _updatePluginAccessTime(plugin.id);
    Navigator.pushNamed(context, '/${plugin.id}');
  }

  static toHomeScreen(BuildContext context) {
    PluginManager.instance._currentPlugin = null; // 清除当前插件记录
    Navigator.pushNamed(context, '/');
  }
}
