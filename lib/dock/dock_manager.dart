import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';
import 'package:mira/core/storage/storage_manager.dart';
import 'dock_tabs.dart';
import 'dock_tab.dart';
import 'dock_item.dart';
import 'dock_events.dart';
import 'homepage_dock_item.dart';

/// DockManager类 - 全局管理器，提供静态方法管理DockTabs
class DockManager {
  static final DockManager _instance = DockManager._internal();
  factory DockManager() => _instance;
  static DockManager get instance => _instance;
  DockManager._internal();

  final Map<String, DockTabs> _dockTabsMap = {};
  bool _isInitialized = false;

  /// 检查是否已初始化
  static bool get isInitialized => _instance._isInitialized;

  /// 创建默认的HomePageDockItem
  static DockingItem createDefaultHomePageDockItem() {
    final homePageItem = HomePageDockItem();
    return homePageItem.buildDockingItem();
  }

  /// 创建DockTabs
  static DockTabs createDockTabs(
    String id, {
    Map<String, dynamic>? initData,
    TabbedViewThemeData? themeData,
    DockEventStreamController? eventStreamController,
  }) {
    final dockTabs = DockTabs(
      id: id,
      initData: initData,
      themeData: themeData,
      eventStreamController: eventStreamController,
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
    bool keepAlive = true,
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

  /// 添加DockItem到指定的DockTab
  static bool addDockItem(String dockTabsId, String? tabId, DockItem dockItem) {
    final dockTabs = getDockTabs(dockTabsId);
    if (dockTabs == null) return false;

    // 如果没有指定tabId，创建一个新的tab
    if (tabId == null || tabId.isEmpty) {
      // 根据DockItem类型生成不同的前缀
      final newTabId =
          '${dockItem.type}_${DateTime.now().millisecondsSinceEpoch}';
      final newTab = dockTabs.createDockTab(
        newTabId,
        displayName: dockItem.title,
        closable: true,
        rebuildLayout: false, // 创建tab时先不刷新布局
      );
      if (newTab != null) {
        newTab.addDockItem(dockItem, rebuildLayout: true); // 添加item时再刷新布局
        return true;
      }
      return false;
    }

    // 尝试添加到现有tab
    return dockTabs.addDockItemToTab(tabId, dockItem);
  }

  /// 移除DockItem (基于ID)
  static bool removeDockItemById(
    String dockTabsId,
    String tabId,
    String itemId,
  ) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.removeDockItemFromTabById(tabId, itemId) ?? false;
  }

  /// 获取DockItem (基于ID)
  static DockItem? getDockItemById(
    String dockTabsId,
    String tabId,
    String itemId,
  ) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.getDockItemFromTabById(tabId, itemId);
  }

  /// 获取DockItem (基于title，保持向后兼容)
  static DockItem? getDockItem(
    String dockTabsId,
    String tabId,
    String itemTitle,
  ) {
    final dockTabs = getDockTabs(dockTabsId);
    // 先尝试按ID查找，如果找不到再按title查找（为了向后兼容）
    return dockTabs?.getDockItemFromTabById(tabId, itemTitle);
  }

  /// 更新DockItem (基于ID)
  static bool updateDockItemById(
    String dockTabsId,
    String tabId,
    String itemId,
    Map<String, dynamic> updates,
  ) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.updateDockItemInTabById(tabId, itemId, updates) ?? false;
  }

  /// 清空所有DockTabs
  static void clearAll() {
    for (var dockTabs in _instance._dockTabsMap.values) {
      dockTabs.dispose();
    }
    _instance._dockTabsMap.clear();
  }

  // ===================== Library Tab Management =====================
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
        itemsToRemove.add(item.id);
      }
      for (final itemId in itemsToRemove) {
        removeDockItemById(dockTabsId, dockTabId, itemId); // 使用ID删除
      }
    }
  }

  /// 设置StorageManager实例（已废弃，布局存储现在由DockLayoutController管理）
  @Deprecated('Use DockLayoutController.initializeStorage instead')
  static Future<void> setStorageManager(StorageManager storageManager) async {
    // 空实现，保持向后兼容
    _instance._isInitialized = true;
  }
}
