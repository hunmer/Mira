import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';
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
  // 静态注册的builder映射
  static final Map<String, DockingItem Function(DockItem)> _registeredBuilders =
      {};

  /// 检查是否已初始化
  static bool get isInitialized => _instance._isInitialized;

  /// 创建默认的HomePageDockItem
  static DockingItem createDefaultHomePageDockItem() {
    final homePageItem = HomePageDockItem();
    return homePageItem.buildDockingItem();
  }

  /// 静态方法：注册DockItem类型的builder
  static void registerBuilder(
    String type,
    DockingItem Function(DockItem) builder,
  ) {
    _registeredBuilders[type] = builder;
    print('DockTab: Registered builder for type "$type"');
  }

  /// 静态方法：注销DockItem类型的builder
  static void unregisterBuilder(String type) {
    final removed = _registeredBuilders.remove(type);
    if (removed != null) {
      print('DockTab: Unregistered builder for type "$type"');
    }
  }

  /// 静态方法：检查类型是否已注册
  static bool isTypeRegistered(String type) {
    return _registeredBuilders.containsKey(type);
  }

  /// 静态方法：获取所有已注册的类型
  static List<String> getRegisteredTypes() {
    return _registeredBuilders.keys.toList();
  }

  // getregisteredBuilder
  static DockingItem Function(DockItem)? getRegisteredBuilder(String type) {
    return _registeredBuilders[type];
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
  static bool addDockItem(String dockTabsId, String tabId, DockItem dockItem) {
    final dockTabs = getDockTabs(dockTabsId);
    if (dockTabs == null) return false;
    final newTab = dockTabs.createDockTab(
      tabId,
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

  /// 获取DockItem (基于ID)
  static DockItem? getDockItemById(
    String dockTabsId,
    String tabId,
    String itemId,
  ) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.getDockItemFromTabById(tabId, itemId);
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
  static bool updateLibraryTabValue(
    String tabId,
    String itemId,
    String key,
    dynamic value, {
    String dockTabsId = 'main',
  }) {
    final dockItem = getDockItemById(dockTabsId, tabId, itemId);
    if (dockItem != null) {
      dockItem.update(key, value);
      return true;
    }
    return false;
  }

  /// 获取库标签页的stored值
  static T? getLibraryTabValue<T>(
    String tabId,
    String itemId,
    String key, {
    T? defaultValue,
    String dockTabsId = 'main',
  }) {
    final dockItem = getDockItemById(dockTabsId, tabId, itemId);
    if (dockItem != null) {
      return dockItem.getValue(key) as T? ?? defaultValue;
    }
    return defaultValue;
  }
}
