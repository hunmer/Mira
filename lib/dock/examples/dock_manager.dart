import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/area_builder.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';
import 'package:mira/dock/docking/lib/src/layout/layout_parser.dart';
import 'package:mira/dock/examples/dock_insert_mode.dart';
import 'package:mira/dock/examples/dialog/insert_location_dialog.dart';
import 'package:mira/core/event/event.dart';
import 'dock_item_registry.dart';
import 'dock_persistence.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tab_button.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tab_leading_builder.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabbed_view_menu_builder.dart';

/// 增强版 DockManager，支持持久化
class DockManager extends ChangeNotifier {
  static final Map<String, DockManager> _instances = {};

  final String id;
  final DockingLayout layout;
  final DockItemRegistry registry = DockItemRegistry();

  bool _autoSave = false;
  Map<String, DockItemData> _itemDataCache = {};

  // 广播相关
  final Map<String, Map<String, String>> _tabEventSubscriptions = {};

  DockManager({required this.id, DockingArea? root, bool autoSave = true})
    : layout = DockingLayout(root: root),
      _autoSave = autoSave {
    _instances[id] = this; // 注册实例
    layout.addListener(_onLayoutChanged);
  }

  void _onLayoutChanged() {
    notifyListeners();
    if (_autoSave) {
      saveToFile();
    }
  }

  @override
  void dispose() {
    _instances.remove(id); // 移除实例注册
    layout.removeListener(_onLayoutChanged);

    // 清理所有标签的事件订阅
    for (final tabId in _tabEventSubscriptions.keys) {
      removeAllTabEventListeners(tabId);
    }
    _tabEventSubscriptions.clear();

    super.dispose();
  }

  // ========= 广播功能 =========

  /// 为指定标签添加事件监听器
  /// [tabId] 标签ID
  /// [eventType] 事件类型
  /// [callback] 回调函数
  /// 返回事件监听器的key，用于后续删除
  String addTabEventListener(
    String tabId,
    String eventType,
    void Function(EventArgs) callback,
  ) {
    // 确保该标签的订阅映射存在
    _tabEventSubscriptions[tabId] ??= <String, String>{};

    // 生成唯一的监听器key
    final listenerKey = '${eventType}_${DateTime.now().millisecondsSinceEpoch}';

    // 添加事件监听器
    final subscriptionId = EventManager.instance.subscribe(eventType, (
      EventArgs args,
    ) {
      // 检查事件是否与该标签相关
      if (args is MapEventArgs) {
        final eventTabId = args.item['tabId'];
        if (eventTabId == tabId) {
          callback(args);
        }
      } else {
        // 对于非Map类型的事件，直接调用回调
        callback(args);
      }
    });

    _tabEventSubscriptions[tabId]![listenerKey] = subscriptionId;
    return listenerKey;
  }

  /// 移除指定标签的事件监听器
  /// [tabId] 标签ID
  /// [listenerKey] 监听器key（由addTabEventListener返回）
  void removeTabEventListener(String tabId, String listenerKey) {
    final tabSubscriptions = _tabEventSubscriptions[tabId];
    if (tabSubscriptions != null) {
      final subscriptionId = tabSubscriptions[listenerKey];
      if (subscriptionId != null) {
        EventManager.instance.unsubscribeById(subscriptionId);
        tabSubscriptions.remove(listenerKey);

        // 如果该标签没有任何监听器了，清理映射
        if (tabSubscriptions.isEmpty) {
          _tabEventSubscriptions.remove(tabId);
        }
      }
    }
  }

  /// 为指定标签广播事件
  /// [tabId] 标签ID
  /// [eventType] 事件类型
  /// [data] 事件数据
  void broadcastTabEvent(
    String tabId,
    String eventType,
    Map<String, dynamic> data,
  ) {
    // 确保数据中包含tabId
    final eventData = Map<String, dynamic>.from(data);
    eventData['tabId'] = tabId;

    EventManager.instance.broadcast(eventType, MapEventArgs(eventData));
  }

  /// 移除指定标签的所有事件监听器
  /// [tabId] 标签ID
  void removeAllTabEventListeners(String tabId) {
    final tabSubscriptions = _tabEventSubscriptions[tabId];
    if (tabSubscriptions != null) {
      for (final subscriptionId in tabSubscriptions.values) {
        EventManager.instance.unsubscribeById(subscriptionId);
      }
      _tabEventSubscriptions.remove(tabId);
    }
  }

  // ========= 持久化相关 =========

  /// 保存当前状态到文件
  Future<void> saveToFile() async {
    final data = _extractCurrentData();
    if (data != null) {
      await DockPersistence.save(id, data);
    }
  }

  /// 获取当前布局数据（公共方法）
  DockPersistenceData? getCurrentData() {
    return _extractCurrentData();
  }

  /// 从数据恢复布局（公共方法）
  bool loadFromData(DockPersistenceData data) {
    return _restoreData(data);
  }

  /// 从文件恢复状态
  Future<bool> restoreFromFile() async {
    final data = await DockPersistence.load(id);
    if (data != null) {
      return _restoreData(data);
    }
    return false;
  }

  /// 清除保存的数据
  Future<void> clearSavedData() async {
    await DockPersistence.clear(id);
    _itemDataCache.clear();
  }

  /// 提取当前布局数据
  DockPersistenceData? _extractCurrentData() {
    if (layout.root == null) return null;

    // 提取布局字符串
    final layoutStr = layout.stringify(parser: _Parser());

    // 提取所有 items 的数据
    final items = <DockItemData>[];
    for (final area in layout.layoutAreas()) {
      if (area is DockingItem) {
        final cachedData = _itemDataCache[area.id];
        if (cachedData != null) {
          items.add(
            DockItemData(
              id: area.id.toString(),
              type: cachedData.type,
              values: cachedData.values,
              name: area.name,
              closable: area.closable,
              keepAlive: area.globalKey != null,
              maximizable: area.maximizable,
              weight: area.weight,
            ),
          );
        }
      }
    }

    // 提取最大化区域
    String? maximizedId;
    if (layout.maximizedArea != null) {
      maximizedId = layout.maximizedArea!.id?.toString();
    }

    return DockPersistenceData(
      layout: layoutStr,
      items: items,
      maximizedAreaId: maximizedId,
    );
  }

  /// 恢复布局数据
  bool _restoreData(DockPersistenceData data) {
    try {
      // 缓存 item 数据
      _itemDataCache = {for (final item in data.items) item.id: item};

      // 恢复布局
      layout.load(
        layout: data.layout,
        parser: _Parser(),
        builder: _Builder(this),
      );

      // 恢复最大化状态
      if (data.maximizedAreaId != null) {
        final area = layout.findDockingArea(data.maximizedAreaId);
        if (area is DockingItem) {
          layout.maximizeDockingItem(area);
        } else if (area is DockingTabs) {
          layout.maximizeDockingTabs(area);
        }
      }

      return true;
    } catch (e) {
      print('Failed to restore dock data: $e');
      return false;
    }
  }

  // ========= 添加 Item 增强版 =========

  /// 添加带类型的 Item
  void addTypedItem({
    required String id,
    required String type,
    required Map<String, dynamic> values,
    DropArea? targetArea,
    DropPosition? dropPosition,
    int? dropIndex,
    String? name,
    bool closable = true,
    bool keepAlive = false,
    bool? maximizable,
    double? weight,
    List<TabButton>? buttons,
    TabLeadingBuilder? leading,
    TabbedViewMenuBuilder? menuBuilder,
    DockInsertMode insertMode = DockInsertMode.auto,
    BuildContext? context,
  }) async {
    final widget = registry.build(type, values);
    if (widget == null) {
      throw ArgumentError('Unknown item type: $type');
    }

    // 根据插入模式决定目标区域
    DropPosition? finalDropPosition = dropPosition;
    int? finalDropIndex = dropIndex;

    if (insertMode == DockInsertMode.choose && context != null) {
      final result = await showInsertLocationDialog(context, layout);
      Navigator.of(context).pop();
      if (result == null) {
        // 用户取消了选择
        return;
      }
      if (result.targetArea is! DropArea) {
        throw ArgumentError('Selected area is not a valid drop target');
      }
      targetArea = result.targetArea as DropArea;
      finalDropPosition = result.dropPosition;
      finalDropIndex = result.dropIndex;
    } else if (targetArea == null) {
      // 选择一个可投放区域（优先 Tabs 或 Item，否则 root）
      for (final area in layout.layoutAreas()) {
        if (area is DockingTabs) {
          targetArea = area;
          break;
        }
      }
      targetArea ??=
          layout.layoutAreas().firstWhereOrNull((a) => a is DockingItem)
              as DropArea?;
    }
    // 读取类型的默认 UI 配置
    buttons = buttons ?? registry.defaultButtonsOf(type);
    leading = leading ?? registry.defaultLeadingOf(type);
    menuBuilder = menuBuilder ?? registry.defaultMenuOf(type);

    // 缓存数据（函数/回调不做持久化，仅运行时缓存）
    _itemDataCache[id] = DockItemData(
      id: id,
      type: type,
      values: values,
      name: name,
      closable: closable,
      keepAlive: keepAlive,
      maximizable: maximizable,
      weight: weight,
      buttons: buttons,
      leading: leading,
      menuBuilder: menuBuilder,
    );

    if (targetArea == null) {
      if (layout.root == null) {
        // 创建根区域 - 创建一个默认的DockingTabs作为根区域
        _createDefaultRootLayout();
      }
      // 安全地查找可投放的区域
      if (layout.root is DropArea) {
        targetArea = layout.root! as DropArea;
      } else {
        // 如果根区域不是DropArea，查找第一个可投放的区域
        targetArea =
            layout.layoutAreas().firstWhereOrNull((area) => area is DropArea)
                as DropArea?;
        if (targetArea == null) {
          throw Exception('No valid DropArea found to add docking item');
        }
      }
    }

    // 检查是否需要替换占位符布局
    final isPlaceholderLayout = _isDefaultPlaceholderLayout();

    if (isPlaceholderLayout && targetArea == layout.root) {
      // 如果目标是占位符布局，直接用新项目替换整个 root
      final newItem = DockingItem(
        id: id,
        name: name,
        widget: widget,
        closable: closable,
        keepAlive: keepAlive,
        maximizable: maximizable,
        weight: weight,
        buttons: buttons,
        leading: leading,
        menuBuilder: menuBuilder,
      );

      // 直接设置新的根布局
      layout.root = DockingTabs([newItem]);
      return;
    }

    // 添加到布局
    layout.addItemOn(
      newItem: DockingItem(
        id: id,
        name: name,
        widget: widget,
        closable: closable,
        keepAlive: keepAlive,
        maximizable: maximizable,
        weight: weight,
        buttons: buttons,
        leading: leading,
        menuBuilder: menuBuilder,
      ),
      targetArea: targetArea,
      dropPosition:
          finalDropPosition ??
          (targetArea is DockingTabs ? null : DropPosition.right),
      dropIndex: finalDropIndex ?? (targetArea is DockingTabs ? 0 : null),
    );
  }

  /// 更新 Item 的值
  void updateItemValues(String id, Map<String, dynamic> values) {
    final item = layout.findDockingItem(id);
    if (item != null) {
      final cachedData = _itemDataCache[id];
      if (cachedData != null) {
        // 更新缓存
        _itemDataCache[id] = DockItemData(
          id: id,
          type: cachedData.type,
          values: values,
          name: item.name,
          closable: item.closable,
          keepAlive: item.globalKey != null,
          maximizable: item.maximizable,
          weight: item.weight,
          buttons: cachedData.buttons,
          leading: cachedData.leading,
          menuBuilder: cachedData.menuBuilder,
        );

        // 重建 Widget
        final newWidget = registry.build(cachedData.type, values);
        if (newWidget != null) {
          item.widget = newWidget;
          layout.rebuild();
        }
      }
    }
  }

  // ========= 实例管理方法 =========

  /// 根据ID获取DockManager实例
  ///
  /// [id] 实例的唯一标识符
  /// [defaultValue] 当找不到实例时返回的默认值
  ///
  /// 返回找到的DockManager实例，如果不存在则返回defaultValue
  static DockManager? getInstance({String? id = 'libraries_main_layout'}) {
    return _instances[id];
  }

  /// 获取所有已注册的实例ID列表
  static List<String> getAllInstanceIds() {
    return _instances.keys.toList();
  }

  /// 检查指定ID的实例是否存在
  static bool hasInstance(String id) {
    return _instances.containsKey(id);
  }

  // ========= Library Tab 兼容方法 =========

  /// 获取Library Tab的值
  static T? getLibraryTabValue<T>(
    String tabId,
    String itemId,
    String key, {
    T? defaultValue,
  }) {
    // 这里需要实现从当前DockManager实例获取值的逻辑
    // 暂时返回默认值，实际应该从item的values中获取
    return defaultValue;
  }

  /// 更新Library Tab的值
  static void updateLibraryTabValue(
    String tabId,
    String itemId,
    String key,
    dynamic value, {
    bool overwrite = true,
  }) {
    // 这里需要实现更新值的逻辑
    // 暂时空实现，实际应该更新item的values
    print('updateLibraryTabValue: $tabId.$itemId.$key = $value');
  }

  /// 根据ID获取DockItem
  static DockItemData? getDockItemById(
    String dockTabsId,
    String tabId,
    String itemId,
  ) {
    // 这里需要实现根据ID查找DockItem的逻辑
    // 暂时返回null，实际应该从全局的DockManager实例中查找
    return null;
  }

  // ========= 基础功能（保持原有） =========

  void setRoot(DockingArea? root) {
    layout.root = root;
  }

  /// 获取item数据缓存（用于兼容性访问）
  Map<String, DockItemData> get itemDataCache => _itemDataCache;

  // ========= 默认布局管理辅助方法 =========

  /// 创建默认的根布局
  void _createDefaultRootLayout() {
    final defaultRoot = DockingTabs([
      DockingItem(
        id: '_placeholder_item',
        name: 'Empty',
        widget: Container(
          child: Center(
            child: Text(
              'No items in layout',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        closable: false,
      ),
    ]);
    layout.root = defaultRoot;
  }

  /// 检查当前是否是默认占位符布局
  bool _isDefaultPlaceholderLayout() {
    if (layout.root is DockingTabs) {
      final tabs = layout.root as DockingTabs;
      return tabs.childrenCount == 1 &&
          tabs.childAt(0).id == '_placeholder_item';
    }
    return false;
  }

  void removeAllItems() {
    // 清空缓存
    _itemDataCache.clear();

    // 获取所有 DockingItem 的 id
    final allItemIds = <dynamic>[];
    for (final area in layout.layoutAreas()) {
      if (area is DockingItem) {
        allItemIds.add(area.id);
      }
    }

    // 批量移除所有 items
    if (allItemIds.isNotEmpty) {
      layout.removeItemByIds(allItemIds);
    }
  }

  void removeItemById(dynamic id) {
    _itemDataCache.remove(id.toString());
    layout.removeItemByIds([id]);
  }

  void renameItem(dynamic id, String newName) {
    final item = layout.findDockingItem(id);
    if (item != null) {
      item.name = newName;
      // 更新缓存中的名称
      final cachedData = _itemDataCache[id.toString()];
      if (cachedData != null) {
        _itemDataCache[id.toString()] = DockItemData(
          id: cachedData.id,
          type: cachedData.type,
          values: cachedData.values,
          name: newName,
          closable: cachedData.closable,
          keepAlive: cachedData.keepAlive,
          maximizable: cachedData.maximizable,
          weight: cachedData.weight,
          buttons: cachedData.buttons,
          leading: cachedData.leading,
          menuBuilder: cachedData.menuBuilder,
        );
      }
      layout.rebuild();
    }
  }
}

/// 解析器
class _Parser with LayoutParserMixin {}

/// 构建器
class _Builder with AreaBuilderMixin {
  final DockManager manager;
  _Builder(this.manager);

  DockingItem buildDockingItem({
    required dynamic id,
    required double? weight,
    required bool maximized,
  }) {
    final itemData = manager._itemDataCache[id.toString()];
    if (itemData != null) {
      final widget = manager.registry.build(itemData.type, itemData.values);
      if (widget != null) {
        return DockingItem(
          id: id,
          name: itemData.name,
          widget: widget,
          closable: itemData.closable,
          keepAlive: itemData.keepAlive,
          maximizable: itemData.maximizable,
          maximized: maximized,
          weight: weight ?? itemData.weight,
          buttons: itemData.buttons,
          leading: itemData.leading,
          menuBuilder: itemData.menuBuilder,
        );
      }
    }
    // 降级处理
    return DockingItem(
      id: id,
      name: 'Unknown',
      widget: Container(child: Center(child: Text('Item not found: $id'))),
      weight: weight,
      maximized: maximized,
    );
  }
}
