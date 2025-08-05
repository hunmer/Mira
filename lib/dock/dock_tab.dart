import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'dock_item.dart';
import 'dock_events.dart';
import 'homepage_dock_item.dart';

/// DockTab类 - 管理单个tab的DockItem集合
class DockTab {
  final String id;
  final String? parentDockTabId;
  String _displayName;
  final List<DockItem> _dockItems = [];
  late DockingLayout _layout;
  final ValueNotifier<int> _layoutChangeNotifier = ValueNotifier<int>(0);
  VoidCallback? _onLayoutChanged;
  final Map<String, dynamic> _defaultDockingItemConfig;
  DockEventStreamController? _eventStreamController;

  // 静态注册的builder映射
  static final Map<String, DockingItem Function(DockItem)> _registeredBuilders =
      {};

  DockTab({
    required this.id,
    this.parentDockTabId,
    String? displayName,
    Map<String, dynamic>? initData,
    VoidCallback? onLayoutChanged,
    void Function(DockingItem)? onItemClose,
    Map<String, dynamic>? defaultDockingItemConfig,
    DockEventStreamController? eventStreamController,
  }) : _displayName = displayName ?? id,
       _onLayoutChanged = onLayoutChanged,
       _defaultDockingItemConfig = defaultDockingItemConfig ?? {},
       _eventStreamController = eventStreamController {
    if (initData != null) {
      _initializeFromJson(initData);
    } else {
      _layout = DockingLayout(
        root: DockingItem(
          name: 'empty',
          widget: const Center(child: Text('No items in this tab')),
        ),
      );
    }
  }

  /// 从JSON数据初始化
  void _initializeFromJson(Map<String, dynamic> json) {
    // 检查是否为默认空状态
    final isDefaultEmpty = json['isDefaultEmpty'] as bool? ?? false;

    // 如果标记为默认空状态，直接使用空布局（会自动显示HomePageDockItem）
    if (isDefaultEmpty) {
      _rebuildLayout();
      return;
    }

    final items = json['items'] as List<dynamic>? ?? [];

    for (var itemData in items) {
      final dockItem = DockItem.fromJson(
        itemData as Map<String, dynamic>,
        _getBuilderForType(itemData['type'] ?? ''),
      );
      _dockItems.add(dockItem);
    }

    _rebuildLayout();
  }

  /// 根据type获取对应的builder
  DockingItem Function(DockItem) _getBuilderForType(String type) {
    if (_registeredBuilders.containsKey(type)) {
      return _registeredBuilders[type]!;
    }
    return (dockItem) => DockingItem(
      name: dockItem.title,
      widget: Center(child: Text('Unknown type: ${dockItem.type}')),
    );
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

  /// 静态方法：调试用，打印所有已注册的类型
  static void printRegisteredTypes() {
    print('DockTab registered types: ${getRegisteredTypes()}');
  }

  /// 添加DockItem
  void addDockItem(DockItem dockItem) {
    if (dockItem.title.isEmpty) {
      dockItem = dockItem.copyWith(title: _displayName);
    }
    _dockItems.add(dockItem);

    // 发送item创建事件
    _eventStreamController?.emit(
      DockItemEvent(
        type: DockEventType.itemCreated,
        dockTabsId: parentDockTabId ?? 'unknown',
        tabId: id,
        itemTitle: dockItem.title,
        itemType: dockItem.type,
      ),
    );

    _rebuildLayout();
  }

  /// 移除DockItem
  bool removeDockItem(String title) {
    final index = _dockItems.indexWhere((item) => item.title == title);
    if (index != -1) {
      final dockItem = _dockItems[index];

      // 发送item关闭事件
      _eventStreamController?.emit(
        DockItemEvent(
          type: DockEventType.itemClosed,
          dockTabsId: parentDockTabId ?? 'unknown',
          tabId: id,
          itemTitle: dockItem.title,
          itemType: dockItem.type,
        ),
      );

      dockItem.dispose();
      _dockItems.removeAt(index);
      _rebuildLayout();
      return true;
    }
    return false;
  }

  /// 获取DockItem
  DockItem? getDockItem(String title) {
    print('Searching for DockItem with title: "$title" in tab: $id');
    print(
      'Available items in this tab: ${_dockItems.map((item) => item.title).toList()}',
    );

    if (_dockItems.isEmpty) {
      print('No items in this tab');
      return null;
    }

    try {
      // 首先尝试精确匹配
      for (var item in _dockItems) {
        if (item.title == title) {
          print('Found exact match: ${item.title}');
          return item;
        }
      }

      // 如果精确匹配失败，尝试忽略大小写匹配
      for (var item in _dockItems) {
        if (item.title.toLowerCase() == title.toLowerCase()) {
          print('Found case-insensitive match: ${item.title}');
          return item;
        }
      }

      print('No match found for title: "$title"');
      return null;
    } catch (e) {
      print('Error in getDockItem for title "$title": $e');
      return null;
    }
  }

  /// 获取所有DockItem
  List<DockItem> getAllDockItems() {
    return List.unmodifiable(_dockItems);
  }

  /// 检查是否为默认空状态（只显示HomePageDockItem，没有真正的DockItem）
  bool get isDefaultEmpty => _dockItems.isEmpty;

  /// 检查是否应该在序列化时忽略（当只有默认内容时不保存）
  bool get shouldSkipSerialization => isDefaultEmpty;

  /// 更新DockItem
  bool updateDockItem(String title, Map<String, dynamic> updates) {
    final dockItem = getDockItem(title);
    if (dockItem != null) {
      for (var entry in updates.entries) {
        dockItem.update(entry.key, entry.value);
      }
      return true;
    }
    return false;
  }

  /// 重建布局
  void _rebuildLayout() {
    if (_dockItems.isEmpty) {
      // 当没有items时，创建一个HomePageDockItem作为默认内容
      final homePageItem = HomePageDockItem();
      _layout = DockingLayout(
        root: homePageItem.buildDockingItem(
          defaultConfig: _defaultDockingItemConfig,
        ),
      );
    } else if (_dockItems.length == 1) {
      // 如果只有一个item，直接使用它
      _layout = DockingLayout(
        root: _dockItems.first.buildDockingItem(
          defaultConfig: _defaultDockingItemConfig,
        ),
      );
    } else {
      // 多个item时，使用Tabs布局
      final dockingItems =
          _dockItems
              .map(
                (item) => item.buildDockingItem(
                  defaultConfig: _defaultDockingItemConfig,
                ),
              )
              .toList();
      _layout = DockingLayout(root: DockingTabs(dockingItems));
    }

    // 触发布局变化通知
    _layoutChangeNotifier.value++;

    // 通知父级DockTabs布局变化
    _onLayoutChanged?.call();
  }

  /// 获取布局
  DockingLayout get layout => _layout;

  /// 获取默认的DockingItem配置
  Map<String, dynamic> getDefaultDockingItemConfig() {
    return _defaultDockingItemConfig;
  }

  /// 获取显示名称
  String get displayName => _displayName;

  /// 设置显示名称
  void setDisplayName(String name) {
    _displayName = name;
    _onLayoutChanged?.call(); // 通知布局更新
  }

  /// 清空所有DockItem
  void clear() {
    for (var item in _dockItems) {
      item.dispose();
    }
    _dockItems.clear();
    _rebuildLayout();
  }

  /// 释放资源
  void dispose() {
    clear();
    _layoutChangeNotifier.dispose();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    // 如果是默认空状态，返回标记信息而不是完整数据
    if (shouldSkipSerialization) {
      return {
        'id': id,
        'parentDockTabId': parentDockTabId,
        'isDefaultEmpty': true,
        'items': [], // 空列表表示这是默认状态
      };
    }

    return {
      'id': id,
      'parentDockTabId': parentDockTabId,
      'isDefaultEmpty': false,
      'items': _dockItems.map((item) => item.toJson()).toList(),
    };
  }
}
