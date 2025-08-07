import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:rxdart/rxdart.dart';
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
  final VoidCallback? _onLayoutChanged;
  final Map<String, dynamic> _defaultDockingItemConfig;
  final DockEventStreamController? _eventStreamController;

  // 防抖控制
  final BehaviorSubject<void> _rebuildSubject = BehaviorSubject<void>();
  late StreamSubscription<void> _rebuildSubscription;
  static const Duration _rebuildDelay = Duration(milliseconds: 500);

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

    // 初始化rxdart防抖流
    _rebuildSubscription = _rebuildSubject
        .debounceTime(_rebuildDelay)
        .listen((_) => _performRebuild());

    // 然后如果有initData，尝试从JSON初始化
    if (initData != null) {
      _initializeFromJson(initData);
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
  }

  /// 根据type获取对应的builder
  DockingItem Function(DockItem) _getBuilderForType(String type) {
    if (DockManager.isTypeRegistered(type)) {
      return DockManager.getRegisteredBuilder(type)!;
    }
    return (dockItem) => DockingItem(
      name: dockItem.title,
      widget: Center(child: Text('Unknown type: ${dockItem.type}')),
    );
  }

  /// 添加DockItem
  void addDockItem(DockItem dockItem, {bool rebuildLayout = true}) {
    if (dockItem.title.isEmpty) {
      dockItem = dockItem.copyWith(title: _displayName);
    }
    _dockItems.add(dockItem);
    _rebuildLayout();
  }

  bool removeDockItem(DockItem dockItem) {
    final index = _dockItems.indexOf(dockItem);
    if (index != -1) {
      _dockItems.removeAt(index);
      _eventStreamController?.emit(
        DockTabEvent(
          type: DockEventType.tabClosed,
          dockTabsId: parentDockTabId ?? 'unknown',
          values: {
            'tabId': id,
            'itemTitle': dockItem.title,
            'itemType': dockItem.type,
          },
        ),
      );
      return true;
    }
    return false;
  }

  /// 移除DockItem (基于ID)
  bool removeDockItemById(String id) {
    final index = _dockItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final dockItem = _dockItems[index];

      // 先释放资源并移除项目
      dockItem.dispose();
      _dockItems.removeAt(index);
      // 然后发送item关闭事件
      _eventStreamController?.emit(
        DockTabEvent(
          type: DockEventType.tabClosed,
          dockTabsId: parentDockTabId ?? 'unknown',
          values: {'dockItem': dockItem},
        ),
      );
      return true;
    }
    return false;
  }

  /// 获取DockItem (基于ID)
  DockItem? getDockItemById(String id) {
    for (var item in _dockItems) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  /// 获取所有DockItem
  List<DockItem> getAllDockItems() {
    return List.unmodifiable(_dockItems);
  }

  /// 更新DockItem (基于ID)
  bool updateDockItemById(String id, Map<String, dynamic> updates) {
    final dockItem = getDockItemById(id);
    if (dockItem != null) {
      return updateDockItem(dockItem, updates);
    }
    return false;
  }

  /// 更新DockItem
  bool updateDockItem(DockItem dockItem, Map<String, dynamic> updates) {
    // 优先尝试作为ID查找
    for (var entry in updates.entries) {
      dockItem.update(entry.key, entry.value);
    }
    return true;
  }

  /// 重建布局（使用rxdart防抖控制）
  void _rebuildLayout() {
    print('🔄 DockTab._rebuildLayout called for tab: $id');
    // 通过Subject触发防抖重建
    _rebuildSubject.add(null);
  }

  /// 执行实际的布局重建
  void _performRebuild() {
    try {
      // 多个item时，使用Tabs布局
      final dockingItems =
          _dockItems
              .map(
                (item) => item.buildDockingItem(
                  defaultConfig: _defaultDockingItemConfig,
                ),
              )
              .toList();

      _layout = DockingLayout(
        root:
            dockingItems.isEmpty
                ? DockManager.createDefaultHomePageDockItem()
                : DockingTabs(dockingItems),
      );
    } catch (e) {
      print('DockTab: Error during layout rebuild: $e');
      // 发生错误时，使用默认布局
      _layout = DockingLayout(
        root: DockManager.createDefaultHomePageDockItem(),
      );
    } finally {
      _onLayoutChanged?.call();
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
    if (_dockItems.isNotEmpty) {
      for (var item in _dockItems) {
        item.dispose();
      }
      _rebuildLayout();
    }
  }

  /// 释放资源
  void dispose({bool rebuildLayout = true}) {
    _rebuildSubscription.cancel();
    _rebuildSubject.close();
    clear(rebuildLayout: rebuildLayout);
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
