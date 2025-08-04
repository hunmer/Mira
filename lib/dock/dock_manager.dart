import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'dock_tabs.dart';
import 'dock_tab.dart';
import 'dock_item.dart';
import 'homepage_dock_item.dart';
import 'dock_layout_parser.dart';

/// DockManager类 - 全局管理器，提供静态方法管理DockTabs
class DockManager {
  static final DockManager _instance = DockManager._internal();
  factory DockManager() => _instance;
  DockManager._internal();

  final Map<String, DockTabs> _dockTabsMap = {};
  static DockManager get instance => _instance;

  /// 创建DockTabs
  static DockTabs createDockTabs(
    String id, {
    Map<String, dynamic>? initData,
    TabbedViewThemeData? themeData,
    void Function(DockingItem)? onItemClose,
  }) {
    final dockTabs = DockTabs(
      id: id,
      initData: initData,
      themeData: themeData,
      onItemClose: onItemClose,
    );
    _instance._dockTabsMap[id] = dockTabs;
    return dockTabs;
  }

  /// 移除DockTabs
  static bool removeDockTabs(String id) {
    final dockTabs = _instance._dockTabsMap.remove(id);
    if (dockTabs != null) {
      dockTabs.dispose();
      return true;
    }
    return false;
  }

  /// 获取DockTabs
  static DockTabs? getDockTabs(String id) {
    return _instance._dockTabsMap[id];
  }

  /// 获取所有DockTabs
  static Map<String, DockTabs> getAllDockTabs() {
    return Map.unmodifiable(_instance._dockTabsMap);
  }

  /// 检查DockTabs是否存在
  static bool hasDockTabs(String id) {
    return _instance._dockTabsMap.containsKey(id);
  }

  /// 创建DockTab到指定的DockTabs
  static DockTab? createDockTab(
    String dockTabsId,
    String tabId, {
    String? displayName,
    Map<String, dynamic>? initData,
    // DockingItem 默认属性配置
    bool closable = true,
    bool keepAlive = false,
    List<TabButton>? buttons,
    bool? maximizable = false, // 默认不显示全屏按钮
    bool maximized = false,
    TabLeadingBuilder? leading,
    double? size,
    double? weight,
    double? minimalWeight,
    double? minimalSize,
  }) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.createDockTab(
      tabId,
      displayName: displayName,
      initData: initData,
      // 传递 DockingItem 属性配置
      closable: closable,
      keepAlive: keepAlive,
      buttons: buttons ?? [], // 默认不显示按钮
      maximizable: maximizable,
      maximized: maximized,
      leading: leading,
      size: size,
      weight: weight,
      minimalWeight: minimalWeight,
      minimalSize: minimalSize,
    );
  }

  /// 移除DockTab
  static bool removeDockTab(String dockTabsId, String tabId) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.removeDockTab(tabId) ?? false;
  }

  /// 获取DockTab
  static DockTab? getDockTab(String dockTabsId, String tabId) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.getDockTab(tabId);
  }

  /// 激活指定的Tab
  static bool setActiveTab(String dockTabsId, String tabId) {
    final dockTabs = getDockTabs(dockTabsId);
    if (dockTabs != null) {
      dockTabs.setActiveTab(tabId);
      return true;
    }
    return false;
  }

  /// 创建HomePage类型的DockItem
  static DockItem createHomePageDockItem(
    String title, {
    VoidCallback? onCreateNewTab,
  }) {
    return HomePageDockItem(onCreateNewTab: onCreateNewTab, title: title);
  }

  /// 添加DockItem到指定的DockTab
  static bool addDockItem(String dockTabsId, String? tabId, DockItem dockItem) {
    final dockTabs = getDockTabs(dockTabsId);
    if (dockTabs == null) return false;

    // 如果没有指定tabId，创建一个新的tab
    if (tabId == null || tabId.isEmpty) {
      final newTabId = 'tab_${DateTime.now().millisecondsSinceEpoch}';
      final newTab = dockTabs.createDockTab(
        newTabId,
        displayName: dockItem.title,
        closable: true,
      );
      if (newTab != null) {
        newTab.addDockItem(dockItem);
        return true;
      }
      return false;
    }

    // 尝试添加到现有tab
    return dockTabs.addDockItemToTab(tabId, dockItem);
  }

  /// 移除DockItem
  static bool removeDockItem(
    String dockTabsId,
    String tabId,
    String itemTitle,
  ) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.removeDockItemFromTab(tabId, itemTitle) ?? false;
  }

  /// 获取DockItem
  static DockItem? getDockItem(
    String dockTabsId,
    String tabId,
    String itemTitle,
  ) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.getDockItemFromTab(tabId, itemTitle);
  }

  /// 更新DockItem
  static bool updateDockItem(
    String dockTabsId,
    String tabId,
    String itemTitle,
    Map<String, dynamic> updates,
  ) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.updateDockItemInTab(tabId, itemTitle, updates) ?? false;
  }

  /// 清空所有DockTabs
  static void clearAll() {
    for (var dockTabs in _instance._dockTabsMap.values) {
      dockTabs.dispose();
    }
    _instance._dockTabsMap.clear();
  }

  /// 保存所有DockTabs为JSON
  static Map<String, dynamic> saveToJson() {
    final result = <String, dynamic>{};
    for (var entry in _instance._dockTabsMap.entries) {
      result[entry.key] = entry.value.toJson();
    }
    return result;
  }

  /// 从JSON恢复DockTabs
  static void loadFromJson(Map<String, dynamic> json) {
    clearAll();
    for (var entry in json.entries) {
      final dockTabs = DockTabs(
        id: entry.key,
        initData: entry.value as Map<String, dynamic>,
      );
      _instance._dockTabsMap[entry.key] = dockTabs;
    }
  }

  /// 保存指定DockTabs的布局
  static String? saveDockTabsLayout(String dockTabsId) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.saveLayout();
  }

  /// 加载指定DockTabs的布局
  static bool loadDockTabsLayout(String dockTabsId, String layoutString) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.loadLayout(layoutString) ?? false;
  }

  /// 保存指定Tab的布局
  static String? saveTabLayout(String dockTabsId, String tabId) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.saveTabLayout(tabId);
  }

  /// 加载指定Tab的布局
  static bool loadTabLayout(
    String dockTabsId,
    String tabId,
    String layoutString,
  ) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.loadTabLayout(tabId, layoutString) ?? false;
  }

  /// 保存所有布局数据
  static Map<String, dynamic> saveAllLayouts() {
    final result = <String, dynamic>{};

    // 保存基础JSON数据
    result['dockTabsData'] = saveToJson();

    // 保存布局字符串
    result['layouts'] = DockLayoutManager.saveAllLayoutsToJson();

    return result;
  }

  /// 加载所有布局数据
  static void loadAllLayouts(Map<String, dynamic> data) {
    // 加载基础JSON数据
    if (data.containsKey('dockTabsData')) {
      loadFromJson(data['dockTabsData'] as Map<String, dynamic>);
    }

    // 加载布局字符串
    if (data.containsKey('layouts')) {
      DockLayoutManager.loadAllLayoutsFromJson(
        data['layouts'] as Map<String, dynamic>,
      );
    }
  }

  // ===================== Library Tab Management =====================

  /// 添加库标签页
  static String addLibraryTab(
    dynamic library, {
    String title = '',
    bool isRecycleBin = false,
    String dockTabsId = 'main',
    String? dockTabId, // 改为可为空，默认不指定
  }) {
    // 动态导入LibraryDockItem以避免循环依赖
    // 这个方法将在LibraryDockItem中实现
    throw UnimplementedError('Use LibraryDockItem.addTab instead');
  }

  /// 关闭库标签页
  static bool closeLibraryTab(
    String tabId, {
    String dockTabsId = 'main',
    String dockTabId = 'home',
  }) {
    return removeDockItem(dockTabsId, dockTabId, 'library_$tabId');
  }

  /// 获取当前激活的库标签页ID
  static String? getCurrentLibraryTabId({
    String dockTabsId = 'main',
    String dockTabId = 'home',
  }) {
    final dockTabs = getDockTabs(dockTabsId);
    final dockTab = dockTabs?.getDockTab(dockTabId);
    // 这里需要实现获取当前活动项的逻辑
    // 暂时返回null，具体实现需要在dock system中添加
    return null;
  }

  /// 激活指定的库标签页
  static bool activateLibraryTab(
    String tabId, {
    String dockTabsId = 'main',
    String dockTabId = 'home',
  }) {
    // 这里需要实现激活指定dock item的逻辑
    // 暂时返回false，具体实现需要在dock system中添加
    return false;
  }

  /// 更新库标签页的stored值
  static bool updateLibraryTabStoredValue(
    String tabId,
    String key,
    dynamic value, {
    String dockTabsId = 'main',
    String dockTabId = 'home',
  }) {
    final dockItem = getDockItem(dockTabsId, dockTabId, 'library_$tabId');
    if (dockItem != null) {
      final stored = Map<String, dynamic>.from(
        dockItem.getValue('stored') as Map<String, dynamic>? ?? {},
      );
      stored[key] = value;
      dockItem.update('stored', stored);
      return true;
    }
    return false;
  }

  /// 获取库标签页的stored值
  static T? getLibraryTabStoredValue<T>(
    String tabId,
    String key, {
    T? defaultValue,
    String dockTabsId = 'main',
    String dockTabId = 'home',
  }) {
    final dockItem = getDockItem(dockTabsId, dockTabId, 'library_$tabId');
    if (dockItem != null) {
      final stored = dockItem.getValue('stored') as Map<String, dynamic>?;
      return stored?[key] as T? ?? defaultValue;
    }
    return defaultValue;
  }

  /// 关闭所有库标签页
  static void closeAllLibraryTabs({
    String dockTabsId = 'main',
    String dockTabId = 'home',
  }) {
    final dockTabs = getDockTabs(dockTabsId);
    final dockTab = dockTabs?.getDockTab(dockTabId);
    if (dockTab != null) {
      // 获取所有library类型的dock items并移除
      final itemsToRemove = <String>[];
      for (final item in dockTab.getAllDockItems()) {
        if (item.type == 'library_tab') {
          itemsToRemove.add(item.title);
        }
      }
      for (final itemTitle in itemsToRemove) {
        removeDockItem(dockTabsId, dockTabId, itemTitle);
      }
    }
  }

  /// 保存库标签页数据到存储
  static Future<void> saveLibraryTabsToStorage() async {
    // 这里需要实现保存到插件存储的逻辑
    // 暂时不实现，等待与LibrariesPlugin的集成
  }

  /// 从存储加载库标签页数据
  static Future<void> loadLibraryTabsFromStorage() async {
    // 这里需要实现从插件存储加载的逻辑
    // 暂时不实现，等待与LibrariesPlugin的集成
  }
}
