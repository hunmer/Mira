import 'package:flutter/material.dart';
import 'package:mira/dock/dock_theme.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart'
    as docking_drop;
import 'package:tabbed_view/tabbed_view.dart';
import 'dock_tab.dart';
import 'dock_item.dart';
import 'dock_layout_parser.dart';
import 'dock_events.dart';
import 'dock_manager.dart';

/// DockTabs类 - 管理多个DockTab，提供全局的TabbedViewTheme和Docking
class DockTabs {
  final String id;
  final Map<String, DockTab> _dockTabs = {};
  late DockingLayout _globalLayout;
  final ValueNotifier<int> _layoutChangeNotifier = ValueNotifier<int>(0);
  String? _activeTabId;
  TabbedViewThemeData? _themeData;
  DefaultDockLayoutParser? mainParser;
  DockEventStreamController? _eventStreamController;

  // 新增：批量操作标志，用于避免多次重建布局
  bool _batchOperationInProgress = false;

  // 临时调试：重建布局计数器
  static int _rebuildCount = 0;

  DockTabs({
    required this.id,
    Map<String, dynamic>? initData,
    TabbedViewThemeData? themeData,
    DockEventStreamController? eventStreamController,
    bool deferInitialization = false, // 新增参数：是否延迟初始化布局
  }) {
    _themeData = themeData;
    _eventStreamController = eventStreamController;

    if (initData != null) {
      if (deferInitialization) {
        // 延迟初始化模式：不立即重建布局
        _batchOperationInProgress = true;
        _initializeFromJsonWithoutBatch(initData);
        // 注意：这里不调用_rebuildGlobalLayout，等待外部调用finishDeferredInitialization
      } else {
        _initializeFromJson(initData);
      }
    } else {
      // 创建一个默认的空布局
      _globalLayout = DockingLayout(
        root: DockManager.createDefaultHomePageDockItem(),
      );
    }
  }

  bool get isEmpty => _dockTabs.isEmpty;

  /// 从JSON数据初始化（不使用批量操作包装）
  void _initializeFromJsonWithoutBatch(Map<String, dynamic> json) {
    final tabs = json['tabs'] as Map<String, dynamic>? ?? {};

    for (var entry in tabs.entries) {
      final tabData = entry.value as Map<String, dynamic>;
      final dockTab = DockTab(
        id: entry.key,
        parentDockTabId: id,
        initData: tabData,
        defaultDockingItemConfig:
            tabData['defaultDockingItemConfig'] as Map<String, dynamic>? ?? {},
        onLayoutChanged: _rebuildGlobalLayout,
      );
      _dockTabs[entry.key] = dockTab;
    }
  }

  /// 从JSON数据初始化
  void _initializeFromJson(Map<String, dynamic> json) {
    _performBatchOperation(() {
      _initializeFromJsonWithoutBatch(json);
    });
  }

  /// 完成延迟初始化
  void finishDeferredInitialization() {
    if (_batchOperationInProgress) {
      _batchOperationInProgress = false;
      _rebuildGlobalLayout();
    }
  }

  /// 公共方法：从JSON数据重新加载
  void loadFromJson(Map<String, dynamic> json) {
    // 如果当前已经在延迟初始化状态，直接在当前状态下操作
    if (_batchOperationInProgress) {
      // 清除现有数据（不触发布局重建）
      _clearWithoutRebuild();

      // 重新初始化（不使用批量操作包装）
      _initializeFromJsonWithoutBatch(json);

      // 恢复激活状态
      final activeTabId = json['activeTabId'] as String?;
      if (activeTabId != null && _dockTabs.containsKey(activeTabId)) {
        _activeTabId = activeTabId;
      }

      // 检查是否需要创建默认空tab
      if (false) {
        // 如果没有tab或者之前有默认空tab，创建一个新的默认空tab
        createDockTab(
          'home',
          displayName: '首页',
          closable: false,
          maximizable: false,
          buttons: [],
          rebuildLayout: false, // 不立即重建布局
        );
      }
    } else {
      _performBatchOperation(() {
        // 清除现有数据（不触发布局重建）
        _clearWithoutRebuild();

        // 重新初始化
        _initializeFromJsonWithoutBatch(json);

        // 恢复激活状态
        final activeTabId = json['activeTabId'] as String?;
        if (activeTabId != null && _dockTabs.containsKey(activeTabId)) {
          _activeTabId = activeTabId;
        }

        // 检查是否需要创建默认空tab
        final hasDefaultEmptyTabs =
            json['hasDefaultEmptyTabs'] as bool? ?? false;
        if (_dockTabs.isEmpty || hasDefaultEmptyTabs) {
          // 如果没有tab或者之前有默认空tab，创建一个新的默认空tab
          createDockTab(
            'home',
            displayName: '首页',
            closable: false,
            maximizable: false,
            buttons: [],
            rebuildLayout: false, // 不立即重建布局
          );
        }
      });
    }
  }

  /// 创建新的DockTab
  DockTab createDockTab(
    String tabId, {
    String? displayName,
    Map<String, dynamic>? initData,
    // DockingItem 默认属性配置
    bool closable = true,
    bool keepAlive = true,
    List<TabButton>? buttons,
    bool? maximizable = false,
    bool maximized = false,
    TabLeadingBuilder? leading,
    double? size,
    double? weight,
    double? minimalWeight,
    double? minimalSize,
    bool rebuildLayout = true, // 新增参数，控制是否立即重建布局
  }) {
    final dockTab = DockTab(
      id: tabId,
      displayName: displayName,
      parentDockTabId: id,
      initData: initData,
      onLayoutChanged: _rebuildGlobalLayout,
      eventStreamController: _eventStreamController,
      // 传递 DockingItem 属性配置
      defaultDockingItemConfig: {
        'closable': closable,
        'keepAlive': keepAlive,
        'buttons': buttons ?? [],
        'maximizable': maximizable,
        'maximized': maximized,
        'leading': leading,
        'size': size,
        'weight': weight,
        'minimalWeight': minimalWeight,
        'minimalSize': minimalSize,
      },
    );

    // 在添加新tab之前，检查并清除所有默认空tab
    _clearDefaultEmptyTabs();

    _dockTabs[tabId] = dockTab;

    // 如果这是第一个tab或者没有激活的tab，将其设为激活状态
    if (_activeTabId == null || _dockTabs.length == 1) {
      _activeTabId = tabId;
    }

    // 发送tab创建事件
    _eventStreamController?.emit(
      DockTabEvent(
        type: DockEventType.tabCreated,
        dockTabsId: id,
        values: {'tabId': tabId, 'displayName': displayName},
      ),
    );

    if (rebuildLayout) {
      _rebuildGlobalLayout();
    }
    return dockTab;
  }

  /// 移除DockTab
  bool removeDockTab(String tabId) {
    final dockTab = _dockTabs.remove(tabId);
    if (dockTab != null) {
      // 发送tab关闭事件
      _eventStreamController?.emit(
        DockTabEvent(
          type: DockEventType.tabClosed,
          dockTabsId: id,
          values: {'tabId': tabId, 'displayName': dockTab.displayName},
        ),
      );

      dockTab.dispose();
      _rebuildGlobalLayout();
      return true;
    }
    return false;
  }

  /// 清除所有默认空tab（只显示HomePageDockItem，没有真正DockItem的tab）
  void _clearDefaultEmptyTabs() {
    final tabsToRemove = <String>[];
    for (var tabId in tabsToRemove) {
      final dockTab = _dockTabs.remove(tabId);
      if (dockTab != null) {
        // 如果删除的是当前激活的tab，需要重新选择激活tab
        if (_activeTabId == tabId) {
          _activeTabId =
              _dockTabs.keys.isNotEmpty ? _dockTabs.keys.first : null;
        }

        // 发送tab关闭事件
        _eventStreamController?.emit(
          DockTabEvent(
            type: DockEventType.tabClosed,
            dockTabsId: id,
            values: {'tabId': tabId, 'displayName': dockTab.displayName},
          ),
        );

        dockTab.dispose();
      }
    }

    if (tabsToRemove.isNotEmpty) {
      print('Cleared ${tabsToRemove.length} default empty tabs: $tabsToRemove');
    }
  }

  /// 获取DockTab
  DockTab? getDockTab(String tabId) {
    return _dockTabs[tabId];
  }

  /// 获取所有DockTab
  Map<String, DockTab> getAllDockTabs() {
    return Map.unmodifiable(_dockTabs);
  }

  /// 设置激活的Tab
  void setActiveTab(String tabId) {
    if (_dockTabs.containsKey(tabId) && _activeTabId != tabId) {
      final previousTabId = _activeTabId;
      _activeTabId = tabId;

      // 发送tab切换事件
      _eventStreamController?.emit(
        DockTabEvent(
          type: DockEventType.itemSelected,
          dockTabsId: id,
          values: {
            'tabId': tabId,
            'displayName': _dockTabs[tabId]?.displayName,
            'data': {'previousTabId': previousTabId},
          },
        ),
      );

      _rebuildGlobalLayout();
    }
  }

  /// 获取当前激活的Tab ID
  String? get activeTabId => _activeTabId;

  /// 获取当前激活的Tab
  DockTab? get activeTab =>
      _activeTabId != null ? _dockTabs[_activeTabId] : null;

  /// 更新DockTab
  bool updateDockTab(String tabId, Map<String, dynamic> updates) {
    final dockTab = getDockTab(tabId);
    if (dockTab != null) {
      // 这里可以根据需要实现具体的更新逻辑
      return true;
    }
    return false;
  }

  /// 刷新全局布局（保持现有布局结构）
  void _refreshGlobalLayout() {
    // 保存当前布局字符串（如果有的话）
    String? currentLayoutString;
    try {
      currentLayoutString = saveLayout();
    } catch (e) {
      print('无法保存当前布局: $e');
    }

    // 先重建布局
    _rebuildGlobalLayout();

    // 如果有保存的布局且成功保存，尝试恢复布局结构
    if (currentLayoutString != null && currentLayoutString.isNotEmpty) {
      try {
        // 延迟恢复布局，确保新的item已经正确添加
        Future.delayed(const Duration(milliseconds: 50), () {
          loadLayout(currentLayoutString!);
        });
      } catch (e) {
        print('无法恢复布局: $e');
        // 如果恢复失败，保持重建后的布局
      }
    }
  }

  /// 重建全局布局
  void _rebuildGlobalLayout() {
    // 如果正在进行批量操作，延迟重建布局
    if (_batchOperationInProgress) {
      return;
    }

    _rebuildCount++;
    print(
      '🔄 DockTabs._rebuildGlobalLayout #$_rebuildCount called for DockTabs: $id',
    );

    if (_dockTabs.isEmpty) {
      _globalLayout = DockingLayout(
        root: DockManager.createDefaultHomePageDockItem(),
      );
    } else if (_dockTabs.length == 1) {
      // 如果只有一个tab，直接使用其layout
      _globalLayout = _dockTabs.values.first.layout;
    } else {
      // 多个tab时，创建tab布局，将所有tab作为DockingItem显示
      final tabItems =
          _dockTabs.entries.map((entry) {
            final tab = entry.value;
            final tabId = entry.key;
            final config = tab.getDefaultDockingItemConfig();

            return DockingItem(
              name: tab.displayName,
              id: tabId,
              widget: _buildTabContentWithEvents(tab),
              // 应用默认配置
              closable: config['closable'] ?? true,
              buttons:
                  (config['buttons'] is List
                      ? (config['buttons'] as List)
                          .whereType<TabButton>()
                          .toList()
                      : []),
              maximizable: config['maximizable'] ?? false,
              maximized: config['maximized'] ?? false,
              leading: config['leading'],
              size: config['size'],
              weight: config['weight'],
              minimalWeight: config['minimalWeight'],
              minimalSize: config['minimalSize'],
              keepAlive: config['keepAlive'] ?? true,
            );
          }).toList();

      if (tabItems.isNotEmpty) {
        _globalLayout = DockingLayout(root: DockingTabs(tabItems));
      } else {
        _globalLayout = DockingLayout(
          root: DockManager.createDefaultHomePageDockItem(),
        );
      }
    }

    // 触发布局变化通知
    _layoutChangeNotifier.value++;
  }

  /// 构建带事件监听的Tab内容
  Widget _buildTabContentWithEvents(DockTab tab) {
    final items = tab.getAllDockItems();
    if (items.isEmpty) {
      return const Center(child: Text('Empty tab'));
    } else if (items.length == 1) {
      return items.first
          .buildDockingItem(defaultConfig: tab.getDefaultDockingItemConfig())
          .widget;
    } else {
      // 创建TabData列表
      final tabDataList =
          items.map((item) {
            final dockingItem = item.buildDockingItem(
              defaultConfig: tab.getDefaultDockingItemConfig(),
            );
            return TabData(
              value: dockingItem,
              text: dockingItem.name ?? 'Untitled',
              content: dockingItem.widget,
              closable: dockingItem.closable,
            );
          }).toList();

      // TODO: 正确的TabbedView位置
      return TabbedView(
        controller: TabbedViewController(tabDataList),
        onDraggableBuild: (controller, tabIndex, tabData) {
          final dockingItem = tabData.value as DockingItem;
          return DraggableConfig(
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  dockingItem.name ?? 'Untitled',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      );
    }
  }

  /// 构建带主题的Docking Widget
  Widget buildDockingWidget(BuildContext context) {
    return TabbedViewTheme(
      data: _themeData ?? DockTheme.createCustomThemeData(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<int>(
          valueListenable: _layoutChangeNotifier,
          builder: (context, value, child) {
            return _buildContextMenuWrapper(
              Docking(
                layout: _globalLayout,
                onItemClose: _handleItemClose,
                onItemSelection: _handleItemSelection,
                onTabMove: _handleItemMove,
                onTabLayoutChanged: _handleItemLayoutChanged,
                onItemPositionChanged: _handleItemPositionChanged,
              ),
            );
          },
        ),
      ),
    );
  }

  /// 包装右键菜单功能
  Widget _buildContextMenuWrapper(Widget child) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        // 这里需要获取当前被右键点击的tab信息
        // 由于docking库的限制，我们将在DockItem级别处理右键菜单
      },
      child: child,
    );
  }

  /// 刷新界面
  void refresh() {
    _rebuildGlobalLayout();
  }

  /// 批量操作：创建多个DockTab，避免多次重建布局
  void createMultipleDockTabs(List<Map<String, dynamic>> tabConfigs) {
    _performBatchOperation(() {
      for (var config in tabConfigs) {
        createDockTab(
          config['tabId'] as String,
          displayName: config['displayName'] as String?,
          initData: config['initData'] as Map<String, dynamic>?,
          closable: config['closable'] as bool? ?? true,
          keepAlive: config['keepAlive'] as bool? ?? true,
          buttons: config['buttons'] as List<TabButton>?,
          maximizable: config['maximizable'] as bool? ?? false,
          maximized: config['maximized'] as bool? ?? false,
          leading: config['leading'] as TabLeadingBuilder?,
          size: config['size'] as double?,
          weight: config['weight'] as double?,
          minimalWeight: config['minimalWeight'] as double?,
          minimalSize: config['minimalSize'] as double?,
          rebuildLayout: false, // 批量操作期间不重建布局
        );
      }
    });
  }

  /// 处理DockItem关闭事件
  void _handleItemClose(DockingItem dockingItem) {
    // 从所有DockTab中查找并移除对应的DockItem
    // 优先使用ID查找，如果没有ID则使用name
    for (var dockTab in _dockTabs.values) {
      bool removed = false;

      // 如果DockingItem有ID，优先使用ID查找
      if (dockingItem.id != null) {
        // 通过ID查找对应的DockItem
        final dockItem = dockTab.getDockItemById(dockingItem.id.toString());
        if (dockItem != null) {
          removed = dockTab.removeDockItemById(dockItem.id);
        }
      }

      // 如果通过ID没有找到，则尝试使用name
      if (!removed && dockingItem.name != null) {
        removed = dockTab.removeDockItem(dockingItem.name!);
      }

      if (removed) {
        break; // 找到并移除后跳出循环
      }
    }

    // 发送关闭事件
    _eventStreamController?.emit(
      DockTabEvent(
        type: DockEventType.itemClosed,
        dockTabsId: id,
        values: {
          'itemId': dockingItem.id,
          'itemTitle': dockingItem.name,
          'itemType': dockingItem.widget.runtimeType.toString(),
        },
      ),
    );
  }

  /// 处理DockItem选择事件
  void _handleItemSelection(DockingItem dockingItem) {
    // 这里可以添加选择事件的处理逻辑
    print('Item selected: ${dockingItem.name}');

    // 发送item选择事件
    _eventStreamController?.emit(
      DockTabEvent(
        type: DockEventType.itemSelected,
        dockTabsId: id,
        values: {
          'itemTitle': dockingItem.name,
          'itemType': dockingItem.widget.runtimeType.toString(),
        },
      ),
    );
  }

  /// 处理DockItem移动事件
  void _handleItemMove({
    required DockingItem draggedItem,
    required DropArea targetArea,
    docking_drop.DropPosition? dropPosition,
    int? dropIndex,
  }) {
    // 这里可以添加移动事件的处理逻辑
    print(
      'Dragged item: ${draggedItem.name}, Target area: $targetArea, Drop position: $dropPosition, Drop index: $dropIndex',
    );

    // 发送item移动事件
    _eventStreamController?.emit(
      DockTabEvent(
        type: DockEventType.layoutChanged,
        dockTabsId: id,
        values: {
          'action': 'itemMove',
          'draggedItem': draggedItem.name,
          'targetArea': targetArea.toString(),
          'dropPosition': dropPosition.toString(),
          'dropIndex': dropIndex,
        },
      ),
    );
  }

  /// 处理DockItem布局变化事件
  ///
  void _handleItemLayoutChanged({
    required DockingItem oldItem,
    required DockingItem newItem,
    required DropArea targetArea,
    docking_drop.DropPosition? newIndex,
    int? dropIndex,
  }) {
    // 这里可以添加布局变化事件的处理逻辑
    print(
      'Old item: ${oldItem.name}, New item: ${newItem.name}, Target area: $targetArea, Drop position: $newIndex, Drop index: $dropIndex',
    );

    // 发送tab布局变化事件
    _eventStreamController?.emit(
      DockTabEvent(
        type: DockEventType.layoutChanged,
        dockTabsId: id,
        values: {
          'action': 'tabLayoutChanged',
          'oldItem': oldItem.name,
          'newItem': newItem.name,
          'targetArea': targetArea.toString(),
          'newIndex': newIndex.toString(),
          'dropIndex': dropIndex,
        },
      ),
    );
  }

  /// 处理DockItem位置变化事件 (内容区域拖拽)
  void _handleItemPositionChanged({
    required DockingItem draggedItem,
    required DropArea targetArea,
    required docking_drop.DropPosition dropPosition,
  }) {
    // 这里可以添加位置变化事件的处理逻辑
    print(
      'Item position changed: ${draggedItem.name}, Target area: $targetArea, Drop position: $dropPosition',
    );

    // 发送item位置变化事件
    _eventStreamController?.emit(
      DockTabEvent(
        type: DockEventType.itemPositionChanged,
        dockTabsId: id,
        values: {
          'action': 'itemPositionChanged',
          'draggedItem': draggedItem.name,
          'targetArea': targetArea.toString(),
          'dropPosition': dropPosition.toString(),
        },
      ),
    );
  }

  /// 添加DockItem到指定的DockTab
  bool addDockItemToTab(
    String tabId,
    DockItem dockItem, {
    bool rebuildLayout = true,
  }) {
    final dockTab = getDockTab(tabId);
    if (dockTab != null) {
      // 在添加DockItem之前，清除其他的默认空tab
      _clearDefaultEmptyTabs();

      // 传递rebuildLayout参数，避免DockTab内部立即刷新布局
      dockTab.addDockItem(dockItem, rebuildLayout: false);

      // 发送item创建事件
      _eventStreamController?.emit(
        DockTabEvent(
          type: DockEventType.itemCreated,
          dockTabsId: id,
          values: {
            'tabId': tabId,
            'itemId': dockItem.id,
            'itemTitle': dockItem.title,
            'itemType': dockItem.type,
          },
        ),
      );

      if (rebuildLayout) {
        _refreshGlobalLayout();
      }
      return true;
    }
    return false;
  }

  /// 从指定的DockTab移除DockItem (基于ID)
  bool removeDockItemFromTabById(String tabId, String itemId) {
    final dockTab = getDockTab(tabId);
    if (dockTab != null) {
      // 获取item信息用于事件发射
      final dockItem = dockTab.getDockItemById(itemId);
      final result = dockTab.removeDockItemById(itemId);
      if (result) {
        // 发送item关闭事件
        _eventStreamController?.emit(
          DockTabEvent(
            type: DockEventType.itemClosed,
            dockTabsId: id,
            values: {
              'tabId': tabId,
              'itemId': itemId,
              'itemTitle': dockItem?.title,
              'itemType': dockItem?.type,
            },
          ),
        );

        _refreshGlobalLayout();
      }
      return result;
    }
    return false;
  }

  /// 从指定的DockTab移除DockItem (基于title，保持向后兼容)
  bool removeDockItemFromTab(String tabId, String itemTitle) {
    final dockTab = getDockTab(tabId);
    if (dockTab != null) {
      // 获取item信息用于事件发射
      final dockItem = dockTab.getDockItem(itemTitle);
      final result = dockTab.removeDockItem(itemTitle);
      if (result) {
        // 发送item关闭事件
        _eventStreamController?.emit(
          DockTabEvent(
            type: DockEventType.itemClosed,
            dockTabsId: id,
            values: {
              'tabId': tabId,
              'itemId': dockItem?.id,
              'itemTitle': itemTitle,
              'itemType': dockItem?.type,
            },
          ),
        );

        _refreshGlobalLayout();
      }
      return result;
    }
    return false;
  }

  /// 获取指定DockTab中的DockItem (基于ID)
  DockItem? getDockItemFromTabById(String tabId, String itemId) {
    final dockTab = getDockTab(tabId);
    return dockTab?.getDockItemById(itemId);
  }

  /// 获取指定DockTab中的DockItem (基于title，保持向后兼容)
  DockItem? getDockItemFromTab(String tabId, String itemTitle) {
    final dockTab = getDockTab(tabId);
    return dockTab?.getDockItem(itemTitle);
  }

  /// 更新指定DockTab中的DockItem (基于ID)
  bool updateDockItemInTabById(
    String tabId,
    String itemId,
    Map<String, dynamic> updates,
  ) {
    final dockTab = getDockTab(tabId);
    if (dockTab != null) {
      return dockTab.updateDockItemById(itemId, updates);
    }
    return false;
  }

  /// 更新指定DockTab中的DockItem (基于title，保持向后兼容)
  bool updateDockItemInTab(
    String tabId,
    String itemTitle,
    Map<String, dynamic> updates,
  ) {
    final dockTab = getDockTab(tabId);
    if (dockTab != null) {
      return dockTab.updateDockItem(itemTitle, updates);
    }
    return false;
  }

  /// 执行批量操作，避免多次重建布局
  void _performBatchOperation(void Function() operation) {
    final wasBatchOperationInProgress = _batchOperationInProgress;
    _batchOperationInProgress = true;

    try {
      operation();
    } finally {
      _batchOperationInProgress = wasBatchOperationInProgress;
      if (!wasBatchOperationInProgress) {
        _rebuildGlobalLayout(); // 只有在最外层批量操作结束时才重建布局
      }
    }
  }

  /// 清空所有DockTab，但不重建布局（用于批量操作）
  void _clearWithoutRebuild() {
    for (var dockTab in _dockTabs.values) {
      dockTab.dispose(rebuildLayout: false); // 不重建布局
    }
    _dockTabs.clear();
  }

  /// 清空所有DockTab
  void clear() {
    _clearWithoutRebuild();
    _rebuildGlobalLayout();
  }

  /// 释放资源
  void dispose() {
    clear();
    _layoutChangeNotifier.dispose();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final tabsMap = <String, dynamic>{};
    String? activeTabIdToSave = _activeTabId;

    for (var entry in _dockTabs.entries) {
      final dockTab = entry.value;

      // 如果tab不应该被序列化（默认空状态），则跳过

      // 如果跳过的tab是当前激活的tab，需要重新选择一个激活tab
      if (_activeTabId == entry.key) {
        activeTabIdToSave = tabsMap.keys.isNotEmpty ? tabsMap.keys.first : null;
      }
    }

    return {'id': id, 'tabs': tabsMap, 'activeTabId': activeTabIdToSave};
  }

  /// 保存当前布局
  String saveLayout() {
    // 保存当前的激活tab状态
    final layoutData = {
      'activeTabId': _activeTabId,
      'tabs': _dockTabs.keys.toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // 为每个tab创建parser，而不是只为活动tab
    if (mainParser == null) {
      mainParser = DefaultDockLayoutParser(
        dockTabsId: id,
        tabId: _activeTabId!,
      );
      DockLayoutManager.registerParser('${id}_layout', mainParser!);

      // 同时为每个子tab注册parser
      for (var entry in _dockTabs.entries) {
        final tabParser = DefaultDockLayoutParser(
          dockTabsId: id,
          tabId: entry.key,
        );
        DockLayoutManager.registerParser(
          '${id}_${entry.key}_layout',
          tabParser,
        );
      }
    }

    final layoutString = DockLayoutManager.saveLayout(
      '${id}_layout',
      _globalLayout,
      mainParser!,
    );

    // 保存元数据
    DockLayoutManager.setSavedLayout('${id}_metadata', layoutData.toString());

    return layoutString;
  }

  /// 加载布局
  bool loadLayout(String layoutString) {
    try {
      // 尝试恢复元数据
      final metadataString = DockLayoutManager.getSavedLayout('${id}_metadata');
      if (metadataString != null) {
        // 这里可以解析元数据来恢复状态
      }

      // 为所有可能的tab注册parser
      for (var entry in _dockTabs.entries) {
        final tabParser = DefaultDockLayoutParser(
          dockTabsId: id,
          tabId: entry.key,
        );
        DockLayoutManager.registerParser(
          '${id}_${entry.key}_layout',
          tabParser,
        );
      }

      final mainParser = DefaultDockLayoutParser(
        dockTabsId: id,
        tabId: _activeTabId ?? _dockTabs.keys.first,
      );
      DockLayoutManager.registerParser('${id}_layout', mainParser);

      // 临时保存布局字符串
      DockLayoutManager.setSavedLayout('${id}_layout', layoutString);

      // 创建一个新的布局实例来加载数据
      final tempLayout = DockingLayout(
        root: DockingItem(
          name: 'temp',
          widget: const Center(child: Text('Loading...')),
        ),
      );

      // 加载布局到临时对象中
      final success = DockLayoutManager.loadLayout('${id}_layout', tempLayout);

      if (success) {
        // 将加载的布局设置为全局布局
        _globalLayout = tempLayout;
        // 强制重新构建UI
        _layoutChangeNotifier.value++;
        return true;
      } else {
        print('Failed to load layout - loadLayout returned false');
        return false;
      }
    } catch (e) {
      print('Failed to load layout: $e');
      return false;
    }
  }

  /// 保存当前Tab的布局
  String? saveTabLayout(String tabId) {
    final tab = getDockTab(tabId);
    if (tab != null) {
      final parser = DefaultDockLayoutParser(dockTabsId: id, tabId: tabId);
      DockLayoutManager.registerParser('${id}_${tabId}_layout', parser);
      return DockLayoutManager.saveLayout(
        '${id}_${tabId}_layout',
        tab.layout,
        parser,
      );
    }
    return null;
  }

  /// 加载Tab布局
  bool loadTabLayout(String tabId, String layoutString) {
    final tab = getDockTab(tabId);
    if (tab != null) {
      try {
        final parser = DefaultDockLayoutParser(dockTabsId: id, tabId: tabId);
        DockLayoutManager.registerParser('${id}_${tabId}_layout', parser);

        // 临时保存布局字符串
        DockLayoutManager.setSavedLayout('${id}_${tabId}_layout', layoutString);

        final success = DockLayoutManager.loadLayout(
          '${id}_${tabId}_layout',
          tab.layout,
        );
        if (success) {
          _rebuildGlobalLayout();
        }
        return success;
      } catch (e) {
        print('Failed to load tab layout: $e');
        return false;
      }
    }
    return false;
  }
}
