import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/dock/dock_theme.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart'
    as docking_drop;
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:rxdart/rxdart.dart';
import 'dock_tab.dart';
import 'dock_item.dart';
import 'dock_layout_parser.dart';
import 'dock_events.dart';
import 'dock_manager.dart';
import 'dock_layout_preset_dialog.dart';

/// DockTabs类 - 管理多个DockTab，提供全局的TabbedViewTheme和Docking
class DockTabs {
  final String id;
  late final LibrariesPlugin? _plugin;
  final Map<String, DockTab> _dockTabs = {};
  DockingLayout? _globalLayout;
  final ValueNotifier<int> _layoutChangeNotifier = ValueNotifier<int>(0);
  String? _activeTabId;
  TabbedViewThemeData? _themeData;
  DefaultDockLayoutParser? mainParser;
  DockEventStreamController? _eventStreamController;

  // 防抖控制 - 使用 RxDart
  final PublishSubject<void> _rebuildSubject = PublishSubject<void>();
  late final StreamSubscription _rebuildSubscription;
  static const Duration _rebuildDelay = Duration(milliseconds: 200);

  // 临时调试：重建布局计数器
  static int _rebuildCount = 0;

  DockTabs({
    required this.id,
    Map<String, dynamic>? initData,
    TabbedViewThemeData? themeData,
    DockEventStreamController? eventStreamController,
    bool deferInitialization = false, // 保留参数但简化逻辑
  }) {
    _themeData = themeData;
    _eventStreamController = eventStreamController;
    _plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin?;

    // 初始化防抖订阅
    _rebuildSubscription = _rebuildSubject
        .debounceTime(_rebuildDelay)
        .listen((_) => _performRebuild());

    if (initData != null) {
      _initializeFromJson(initData);
    } else {
      // 创建一个默认的空布局
      _globalLayout = DockingLayout(
        root: DockManager.createDefaultHomePageDockItem(),
      );
    }
  }

  bool get isEmpty => _dockTabs.isEmpty;

  /// 安全获取全局布局，如果未初始化则创建默认布局
  DockingLayout get _safeGlobalLayout {
    if (_globalLayout == null) {
      _globalLayout = DockingLayout(
        root: DockManager.createDefaultHomePageDockItem(),
      );
    }
    return _globalLayout!;
  }

  /// 从JSON数据初始化
  void _initializeFromJson(Map<String, dynamic> data) {
    final tabs = data['tabs'] as Map<String, dynamic>? ?? {};

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

    // 恢复激活状态
    final activeTabId = data['activeTabId'] as String?;
    if (activeTabId != null && _dockTabs.containsKey(activeTabId)) {
      _activeTabId = activeTabId;
    }

    _rebuildGlobalLayout();
  }

  void loadFromJson(Map<String, dynamic> json) {
    // 清除现有数据
    for (var dockTab in _dockTabs.values) {
      dockTab.dispose();
    }
    _dockTabs.clear();

    // 重新初始化
    _initializeFromJson(json);
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
    _activeTabId ??= tabId;

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

  /// 清除所有类型为homepage且确实为空的tab
  void _clearDefaultEmptyTabs() {
    for (var entry in _dockTabs.entries) {
      final dockTab = entry.value;
      final allItems = dockTab.getAllDockItems();
      for (var item in allItems) {
        if (item.type == 'homepage') {
          dockTab.removeDockItem(item);
        }
      }
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

  /// 重建全局布局（使用 RxDart 防抖控制）
  void _rebuildGlobalLayout() {
    // 触发防抖事件
    _rebuildSubject.add(null);
  }

  /// 执行实际的布局重建
  void _performRebuild() {
    _rebuildCount++;
    print(
      '🔄 DockTabs._performRebuild #$_rebuildCount called for DockTabs: $id',
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
    final defaultConfig = tab.getDefaultDockingItemConfig();
    if (items.isEmpty) {
      return DockManager.createDefaultHomePageDockItem().widget;
    } else if (items.length == 1) {
      return items.first.buildDockingItem(defaultConfig: defaultConfig).widget;
    } else {
      // 创建TabData列表
      final tabDataList =
          items.map((item) {
            final dockingItem = item.buildDockingItem(
              defaultConfig: defaultConfig,
            );
            return TabData(
              value: dockingItem,
              text: dockingItem.name ?? 'Untitled',
              content: dockingItem.widget,
              closable: dockingItem.closable,
            );
          }).toList();

      return TabbedView(
        controller: TabbedViewController(tabDataList),
        // tabsAreaButtonsBuilder: (context, tabsCount) {
        //   return _buildTabsAreaButtons(context, tabsCount);
        // },
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

  /// 构建Tab区域的按钮
  List<TabButton> _buildTabsAreaButtons(
    BuildContext context,
    DockingTabs? dockingTabs,
  ) {
    List<TabButton> buttons = [];

    // 添加新tab按钮
    buttons.add(
      TabButton(
        icon: IconProvider.data(Icons.add),
        onPressed: () {
          _handleAddNewTab(context);
        },
      ),
    );

    // 如果有tab，添加删除所有tab按钮
    if (dockingTabs != null) {
      buttons.add(
        TabButton(
          icon: IconProvider.data(Icons.clear_all),
          onPressed: () {
            _handleDeleteAllTabs();
          },
        ),
      );
    }

    // 预设菜单按钮
    buttons.add(
      TabButton(
        icon: IconProvider.data(Icons.more_vert),
        onPressed: () {
          _showPresetDialog(context);
        },
      ),
    );

    return buttons;
  }

  /// 处理添加新tab
  void _handleAddNewTab(BuildContext context) {
    // TODO 展示所有注册的窗口类型
    _plugin?.libraryUIController.openLibrary(context);
  }

  /// 处理删除所有tab
  void _handleDeleteAllTabs() {
    // 删除所有tab
    final tabIds = _dockTabs.keys.toList();
    for (final tabId in tabIds) {
      removeDockTab(tabId);
    }
  }

  /// 显示预设对话框
  void _showPresetDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => DockLayoutPresetDialog(
            dockTabsId: id,
            storageManager: _plugin!.storage,
          ),
    );

    if (result != null && result.isNotEmpty) {
      // 重新加载布局
      loadLayout(result);
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
                layout: _safeGlobalLayout,
                dockingButtonsBuilder: (
                  BuildContext context,
                  DockingTabs? dockingTabs,
                  DockingItem? dockingItem,
                ) {
                  return _buildTabsAreaButtons(context, dockingTabs);
                },
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
    // 注意：由于使用了 RxDart 防抖，无需手动取消，自动防抖处理

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
        rebuildLayout: false, // 创建时不重建布局
      );
    }

    // 批量创建完成后重建一次布局
    _rebuildGlobalLayout();
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
          'itemType': dockingItem.widget.runtimeType.toString(),
        },
      ),
    );
  }

  /// 处理DockItem选择事件
  void _handleItemSelection(DockingItem dockingItem) {
    // 这里可以添加选择事件的处理逻辑
    print('Item selected: ${dockingItem.name}');
    _activeTabId = dockingItem.id;
    // 发送item选择事件
    _eventStreamController?.emit(
      DockTabEvent(
        type: DockEventType.itemSelected,
        dockTabsId: id,
        values: {
          'itemId': dockingItem.id,
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

  /// 清空所有DockTab
  void clear() {
    for (var dockTab in _dockTabs.values) {
      dockTab.dispose();
    }
    _dockTabs.clear();
    _rebuildGlobalLayout();
  }

  /// 释放资源
  void dispose() {
    _rebuildSubscription.cancel();
    _rebuildSubject.close();
    clear();
    _layoutChangeNotifier.dispose();
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final tabsMap = <String, dynamic>{};
    for (var entry in _dockTabs.entries) {
      final dockTab = entry.value;
      tabsMap[entry.key] = dockTab.toJson();
    }
    return {'id': id, 'tabs': tabsMap, 'activeTabId': _activeTabId};
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
      mainParser = DefaultDockLayoutParser(dockTabsId: id, tabId: id);
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
      _safeGlobalLayout,
      mainParser!,
    );

    return layoutString;
  }

  /// 加载布局
  bool loadLayout(String layoutString) {
    if (_dockTabs.isEmpty) {
      return false;
    }
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
