import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'dock_item.dart';
import 'dock_events.dart';
import 'dock_manager.dart';

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

  // 防抖控制
  Timer? _rebuildTimer;
  static const Duration _rebuildDelay = Duration(milliseconds: 500);

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
    // 首先初始化默认布局，确保_layout字段不为null
    _layout = DockingLayout(root: DockManager.createDefaultHomePageDockItem());

    // 然后如果有initData，尝试从JSON初始化
    if (initData != null) {
      try {
        _initializeFromJson(initData);
      } catch (e) {
        print(
          'DockTab: Failed to initialize from JSON, using default layout. Error: $e',
        );
        // 如果初始化失败，保持默认布局
      }
    }
  }

  /// 从JSON数据初始化
  void _initializeFromJson(Map<String, dynamic> json) {
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
  void addDockItem(DockItem dockItem, {bool rebuildLayout = true}) {
    if (dockItem.title.isEmpty) {
      dockItem = dockItem.copyWith(title: _displayName);
    }
    _dockItems.add(dockItem);

    // 发送item创建事件
    _eventStreamController?.emit(
      DockTabEvent(
        type: DockEventType.itemCreated,
        dockTabsId: parentDockTabId ?? 'unknown',
        values: {
          'tabId': id,
          'itemTitle': dockItem.title,
          'itemType': dockItem.type,
        },
      ),
    );

    if (rebuildLayout) {
      _rebuildLayout();
    }
  }

  bool removeDockItem(DockItem dockItem, {bool rebuildLayout = true}) {
    final index = _dockItems.indexOf(dockItem);
    if (index != -1) {
      // 发送item关闭事件
      _eventStreamController?.emit(
        DockTabEvent(
          type: DockEventType.itemClosed,
          dockTabsId: parentDockTabId ?? 'unknown',
          values: {
            'tabId': id,
            'itemTitle': dockItem.title,
            'itemType': dockItem.type,
          },
        ),
      );

      _dockItems.removeAt(index);
      if (rebuildLayout) {
        _rebuildLayout();
      }
      return true;
    }
    return false;
  }

  /// 移除DockItem (基于ID)
  bool removeDockItemById(String id) {
    final index = _dockItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final dockItem = _dockItems[index];

      // 发送item关闭事件
      _eventStreamController?.emit(
        DockTabEvent(
          type: DockEventType.itemClosed,
          dockTabsId: parentDockTabId ?? 'unknown',
          values: {'dockItem': dockItem},
        ),
      );

      dockItem.dispose();
      _dockItems.removeAt(index);
      _rebuildLayout();
      return true;
    }
    return false;
  }

  /// 获取DockItem (基于ID)
  DockItem? getDockItemById(String id) {
    print('Searching for DockItem with ID: "$id" in tab: ${this.id}');
    print(
      'Available items in this tab: ${_dockItems.map((item) => '${item.id}:${item.title}').toList()}',
    );

    if (_dockItems.isEmpty) {
      print('No items in this tab');
      return null;
    }

    try {
      for (var item in _dockItems) {
        if (item.id == id) {
          print('Found match by ID: ${item.id} (${item.title})');
          return item;
        }
      }

      print('No match found for ID: "$id"');
      return null;
    } catch (e) {
      print('Error in getDockItemById for ID "$id": $e');
      return null;
    }
  }

  /// 获取所有DockItem
  List<DockItem> getAllDockItems() {
    return List.unmodifiable(_dockItems);
  }

  /// 更新DockItem (基于ID)
  bool updateDockItemById(String id, Map<String, dynamic> updates) {
    final dockItem = getDockItemById(id);
    if (dockItem != null) {
      for (var entry in updates.entries) {
        dockItem.update(entry.key, entry.value);
      }
      return true;
    }
    return false;
  }

  /// 更新DockItem (基于title，保持向后兼容)
  bool updateDockItem(String title, Map<String, dynamic> updates) {
    // 优先尝试作为ID查找
    var dockItem = getDockItemById(title);
    if (dockItem != null) {
      for (var entry in updates.entries) {
        dockItem.update(entry.key, entry.value);
      }
      return true;
    }
    return false;
  }

  /// 重建布局（使用防抖控制）
  void _rebuildLayout() {
    // 取消之前的定时器
    _rebuildTimer?.cancel();

    // 使用防抖延迟重建
    _rebuildTimer = Timer(_rebuildDelay, () {
      _performRebuild();
    });
  }

  /// 执行实际的布局重建
  void _performRebuild() {
    try {
      // 检查是否真的需要重建布局
      if (_layout.root != null && _dockItems.isNotEmpty) {
        // 如果当前布局结构与期望结构一致，避免重建
        if (_shouldSkipRebuild()) {
          print(
            'DockTab: Skipping layout rebuild - layout is already up to date',
          );
          return;
        }
      }

      print('DockTab: Rebuilding layout for ${_dockItems.length} items');

      if (_dockItems.isEmpty) {
        // 当没有items时，使用DockManager创建默认HomePageDockItem
        _layout = DockingLayout(
          root: DockManager.createDefaultHomePageDockItem(),
        );
      } else if (_dockItems.length == 1) {
        // 如果只有一个item，直接使用它
        final dockingItem = _dockItems.first.buildDockingItem(
          defaultConfig: _defaultDockingItemConfig,
        );
        _layout = DockingLayout(root: dockingItem);
      } else {
        // 多个item时，使用Tabs布局
        final dockingItems =
            _dockItems
                .map(
                  (item) => item.buildDockingItem(
                    defaultConfig: _defaultDockingItemConfig,
                  ),
                )
                .where((item) => item != null) // 过滤掉null项
                .toList();

        // 确保dockingItems不为空，如果为空则使用默认布局
        if (dockingItems.isEmpty) {
          print(
            'DockTab: All docking items failed to build, using default layout',
          );
          _layout = DockingLayout(
            root: DockManager.createDefaultHomePageDockItem(),
          );
        } else if (dockingItems.length == 1) {
          // 如果只剩一个有效item，直接使用它
          _layout = DockingLayout(root: dockingItems.first);
        } else {
          // 使用DockingTabs包装多个items
          _layout = DockingLayout(root: DockingTabs(dockingItems));
        }
      }

      // 触发布局变化通知
      _layoutChangeNotifier.value++;

      // 通知父级DockTabs布局变化
      _onLayoutChanged?.call();
    } catch (e) {
      print('DockTab: Error during layout rebuild: $e');
      // 发生错误时，使用默认布局
      _layout = DockingLayout(
        root: DockManager.createDefaultHomePageDockItem(),
      );
      _layoutChangeNotifier.value++;
      _onLayoutChanged?.call();
    }
  }

  /// 检查是否应该跳过重建
  bool _shouldSkipRebuild() {
    try {
      final root = _layout.root;
      if (root == null) {
        return false;
      }

      print(
        'DockTab: Checking if should skip rebuild - items: ${_dockItems.length}, root type: ${root.runtimeType}',
      );

      if (_dockItems.length == 1) {
        // 单个item的情况：检查root是否是同一个DockingItem
        if (root is DockingItem) {
          final currentItem = _dockItems.first;
          final shouldSkip =
              root.id == currentItem.id && currentItem.hasCachedDockingItem;
          print(
            'DockTab: Single item check - root.id: ${root.id}, current.id: ${currentItem.id}, hasCached: ${currentItem.hasCachedDockingItem}, shouldSkip: $shouldSkip',
          );
          return shouldSkip;
        }
      } else if (_dockItems.length > 1) {
        // 多个item的情况：检查root是否是DockingTabs且包含相同的items
        if (root is DockingTabs && root.childrenCount == _dockItems.length) {
          bool allMatched = true;
          for (int i = 0; i < _dockItems.length; i++) {
            final currentItem = _dockItems[i];
            final rootChild = root.childAt(i);
            if (rootChild.id != currentItem.id ||
                !currentItem.hasCachedDockingItem) {
              allMatched = false;
              print(
                'DockTab: Multi item mismatch at index $i - rootChild.id: ${rootChild.id}, current.id: ${currentItem.id}, hasCached: ${currentItem.hasCachedDockingItem}',
              );
              break;
            }
          }
          print('DockTab: Multi item check - allMatched: $allMatched');
          return allMatched;
        }
      }

      return false;
    } catch (e) {
      print('DockTab: Error in _shouldSkipRebuild: $e');
      return false; // 出错时总是重建
    }
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
  void clear({bool rebuildLayout = true}) {
    for (var item in _dockItems) {
      item.dispose();
    }
    _dockItems.clear();
    if (rebuildLayout) {
      _rebuildLayout();
    }
  }

  /// 释放资源
  void dispose({bool rebuildLayout = true}) {
    _rebuildTimer?.cancel();
    clear(rebuildLayout: rebuildLayout);
    _layoutChangeNotifier.dispose();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    // 过滤掉 HomePageDockItem，它们不应该被保存
    final filteredItems =
        _dockItems.where((item) => item.type != 'homepage').toList();
    return {
      'id': id,
      'parentDockTabId': parentDockTabId,
      'items': filteredItems.map((item) => item.toJson()).toList(),
      'defaultDockingItemConfig': _defaultDockingItemConfig,
    };
  }
}
