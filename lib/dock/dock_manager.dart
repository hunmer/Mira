import 'dart:convert';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:mira/core/storage/storage_manager.dart';
import 'dock_tabs.dart';
import 'dock_tab.dart';
import 'dock_item.dart';
import 'dock_layout_parser.dart';
import 'dock_events.dart';
import 'homepage_dock_item.dart';

/// DockManager类 - 全局管理器，提供静态方法管理DockTabs
class DockManager {
  static final DockManager _instance = DockManager._internal();
  factory DockManager() => _instance;
  static DockManager get instance => _instance;
  DockManager._internal();

  final Map<String, DockTabs> _dockTabsMap = {};
  final Map<String, String> _layoutStorage = {};
  StorageManager? _storageManager;
  bool _isInitialized = false;
  static const String _layoutStorageKey = 'dock_layouts';

  /// 检查是否已初始化
  static bool get isInitialized => _instance._isInitialized;

  /// 创建默认的HomePageDockItem
  static DockingItem createDefaultHomePageDockItem() {
    final homePageItem = HomePageDockItem();
    return homePageItem.buildDockingItem();
  }

  /// 设置StorageManager实例
  static Future<void> setStorageManager(StorageManager storageManager) async {
    _instance._storageManager = storageManager;
    await _instance._loadLayoutsFromStorage();
    _instance._isInitialized = true;
  }

  /// 从持久化存储加载布局
  Future<void> _loadLayoutsFromStorage() async {
    try {
      final layouts = await _storageManager!.readJson(
        _layoutStorageKey,
        <String, String>{},
      );
      if (layouts != null && layouts is Map) {
        _layoutStorage.clear();
        _layoutStorage.addAll(Map<String, String>.from(layouts));
        print(
          'Loaded ${_layoutStorage.length} layouts from persistent storage',
        );
      }
    } catch (e) {
      print('Error loading layouts from storage: $e');
    }
  }

  /// 保存布局到持久化存储
  void _saveLayoutsToStorage() async {
    if (_storageManager == null) return;

    try {
      await _storageManager!.writeJson(_layoutStorageKey, _layoutStorage);
      print('Saved ${_layoutStorage.length} layouts to persistent storage');
    } catch (e) {
      print('Error saving layouts to storage: $e');
    }
  }

  /// 创建DockTabs
  static DockTabs createDockTabs(
    String id, {
    Map<String, dynamic>? initData,
    TabbedViewThemeData? themeData,
    DockEventStreamController? eventStreamController,
    bool deferInitialization = false, // 保留参数以兼容，但不再使用
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

  /// 批量添加DockItem，避免多次布局刷新
  static bool addDockItems(
    String dockTabsId,
    List<DockItem> dockItems, {
    String? tabId,
  }) {
    final dockTabs = getDockTabs(dockTabsId);
    if (dockTabs == null) return false;

    if (dockItems.isEmpty) return true;

    bool success = true;

    if (tabId == null || tabId.isEmpty) {
      // 为第一个item创建新tab
      final firstItem = dockItems.first;
      final newTabId =
          '${firstItem.type}_${DateTime.now().millisecondsSinceEpoch}';
      final newTab = dockTabs.createDockTab(
        newTabId,
        displayName: firstItem.title,
        closable: true,
        rebuildLayout: false, // 创建tab时不刷新布局
      );

      if (newTab != null) {
        // 批量添加所有items，只在最后一个item时刷新布局
        for (int i = 0; i < dockItems.length; i++) {
          final isLast = i == dockItems.length - 1;
          newTab.addDockItem(dockItems[i], rebuildLayout: isLast);
        }
      } else {
        success = false;
      }
    } else {
      // 添加到现有tab，只在最后一个item时刷新布局
      for (int i = 0; i < dockItems.length; i++) {
        final isLast = i == dockItems.length - 1;
        final itemSuccess = dockTabs.addDockItemToTab(
          tabId,
          dockItems[i],
          rebuildLayout: isLast,
        );
        if (!itemSuccess) success = false;
      }
    }

    return success;
  }

  /// 批量创建DockTab，避免多次布局刷新
  static bool createMultipleDockTabs(
    String dockTabsId,
    List<Map<String, dynamic>> tabConfigs,
  ) {
    final dockTabs = getDockTabs(dockTabsId);
    if (dockTabs == null) return false;

    dockTabs.createMultipleDockTabs(tabConfigs);
    return true;
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

  /// 存储布局到内存和持久化存储
  static void storeLayout(String id, String layoutData) {
    _instance._layoutStorage[id] = layoutData;
    // 异步保存到持久化存储
    _instance._saveLayoutsToStorage();
  }

  /// 获取存储的布局
  static String? getStoredLayout(String id) {
    return _instance._layoutStorage[id];
  }

  /// 清除存储的布局
  static void clearStoredLayout(String id) {
    _instance._layoutStorage.remove(id);
    // 异步保存到持久化存储
    _instance._saveLayoutsToStorage();
  }

  /// 清除所有存储的布局
  static void clearAllStoredLayouts() {
    _instance._layoutStorage.clear();
    // 异步保存到持久化存储
    _instance._saveLayoutsToStorage();
  }

  /// 统一保存布局方法 - 由DockController调用
  static bool saveLayoutForDockTabs(String dockTabsId) {
    try {
      // 保存布局字符串
      final layoutString = saveDockTabsLayout(dockTabsId);

      // 保存DockTabs数据
      final dockTabs = getDockTabs(dockTabsId);
      final dockTabsData = dockTabs?.toJson();

      if (layoutString != null && dockTabsData != null) {
        // 创建完整的布局数据，包含布局字符串和数据
        final completeLayoutData = {
          'layoutString': layoutString,
          'dockTabsData': dockTabsData,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'version': '1.0',
        };

        // 使用统一的布局ID命名规则
        final layoutId = '${dockTabsId}_layout';
        final jsonString = json.encode(completeLayoutData);
        storeLayout(layoutId, jsonString);

        print('Complete layout saved for dockTabsId: $dockTabsId');
        print('Layout string length: ${layoutString.length}');
        print('DockTabs data keys: ${dockTabsData.keys.toList()}');
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving layout for dockTabsId $dockTabsId: $e');
      return false;
    }
  }

  /// 统一加载布局方法 - 由DockController调用
  static bool loadLayoutForDockTabs(String dockTabsId) {
    try {
      final layoutId = '${dockTabsId}_layout';
      final storedData = getStoredLayout(layoutId);

      if (storedData != null) {
        try {
          // 尝试解析为完整的布局数据
          final layoutData = json.decode(storedData) as Map<String, dynamic>;

          // 检查是否是新格式（包含完整数据）
          if (layoutData.containsKey('layoutString') &&
              layoutData.containsKey('dockTabsData')) {
            final layoutString = layoutData['layoutString'] as String;
            final dockTabsData =
                layoutData['dockTabsData'] as Map<String, dynamic>;

            // 首先重建DockTabs及其数据
            final existingDockTabs = getDockTabs(dockTabsId);
            if (existingDockTabs != null) {
              // 从JSON数据恢复DockTabs的内容
              existingDockTabs.loadFromJson(dockTabsData);
              print('DockTabs data restored from saved layout');
            }

            // 然后应用布局
            final success = loadDockTabsLayout(dockTabsId, layoutString);
            if (success) {
              print('Complete layout loaded for dockTabsId: $dockTabsId');
              print('Layout version: ${layoutData['version']}');
              print('Saved timestamp: ${layoutData['timestamp']}');
              return true;
            }
          }
        } catch (jsonError) {
          // 如果JSON解析失败，尝试作为纯布局字符串处理（兼容性）
          print('JSON parse failed, trying as layout string: $jsonError');
          final success = loadDockTabsLayout(dockTabsId, storedData);
          if (success) {
            print('Layout string loaded for dockTabsId: $dockTabsId');
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error loading layout for dockTabsId $dockTabsId: $e');
      return false;
    }
  }
}
