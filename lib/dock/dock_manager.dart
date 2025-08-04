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

  /// 创建文本类型的DockItem
  static DockItem createTextDockItem(String title, {String? content}) {
    final dockItem = DockItem(
      type: 'text',
      title: title,
      values: {'content': ValueNotifier(content ?? '')},
      builder:
          (dockItem) => DockingItem(
            name: dockItem.title,
            widget: ValueListenableBuilder(
              valueListenable: dockItem.values['content']!,
              builder: (context, value, child) {
                return Center(
                  child: Text(
                    value.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ),
    );
    return dockItem;
  }

  /// 创建计数器类型的DockItem
  static DockItem createCounterDockItem(String title, {int initialCount = 0}) {
    final dockItem = DockItem(
      type: 'counter',
      title: title,
      values: {'count': ValueNotifier(initialCount)},
      builder:
          (dockItem) => DockingItem(
            name: dockItem.title,
            widget: ValueListenableBuilder(
              valueListenable: dockItem.values['count']!,
              builder: (context, value, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Count: $value',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          dockItem.update('count', (value as int) + 1);
                        },
                        child: const Text('Increment'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
    return dockItem;
  }

  /// 创建列表类型的DockItem
  static DockItem createListDockItem(
    String title, {
    List<String>? initialItems,
  }) {
    final dockItem = DockItem(
      type: 'list',
      title: title,
      values: {'items': ValueNotifier(initialItems ?? <String>[])},
      builder:
          (dockItem) => DockingItem(
            name: dockItem.title,
            widget: ValueListenableBuilder(
              valueListenable: dockItem.values['items']!,
              builder: (context, value, child) {
                final items = value as List<String>;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          final newItems = List<String>.from(items);
                          newItems.add('Item ${newItems.length + 1}');
                          dockItem.update('items', newItems);
                        },
                        child: const Text('Add Item'),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(items[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                final newItems = List<String>.from(items);
                                newItems.removeAt(index);
                                dockItem.update('items', newItems);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
    );
    return dockItem;
  }

  /// 创建HomePage类型的DockItem
  static DockItem createHomePageDockItem(
    String title, {
    VoidCallback? onCreateNewTab,
  }) {
    return HomePageDockItem(onCreateNewTab: onCreateNewTab, title: title);
  }

  /// 添加DockItem到指定的DockTab
  static bool addDockItem(String dockTabsId, String tabId, DockItem dockItem) {
    final dockTabs = getDockTabs(dockTabsId);
    return dockTabs?.addDockItemToTab(tabId, dockItem) ?? false;
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

  /// 获取统计信息
  static Map<String, int> getStatistics() {
    int totalDockTabs = _instance._dockTabsMap.length;
    int totalTabs = 0;
    int totalItems = 0;

    for (var dockTabs in _instance._dockTabsMap.values) {
      final tabs = dockTabs.getAllDockTabs();
      totalTabs += tabs.length;
      for (var tab in tabs.values) {
        totalItems += tab.getAllDockItems().length;
      }
    }

    return {'dockTabs': totalDockTabs, 'tabs': totalTabs, 'items': totalItems};
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
}
