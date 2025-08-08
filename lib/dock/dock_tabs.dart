import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/dock/dock_theme.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart'
    as docking_drop;
import 'package:mira/multi_split_view/lib/multi_split_view.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';
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
  String? _activeTabId;
  TabbedViewThemeData? _themeData;
  DefaultDockLayoutParser? mainParser;
  DockEventStreamController? _eventStreamController;

  // 防抖控制 - 使用 RxDart
  final PublishSubject<DockEvent> _emitdSubject = PublishSubject<DockEvent>();
  late final StreamSubscription _emitSubscription;
  bool get isEmpty => _dockTabs.isEmpty;

  DockTabs({
    required this.id,
    Map<String, dynamic>? initData,
    TabbedViewThemeData? themeData,
    DockEventStreamController? eventStreamController,
  }) {
    _themeData = themeData;
    _eventStreamController = eventStreamController;
    _plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin?;
    _initializeFromJson(initData);
  }

  /// 从JSON数据初始化
  void _initializeFromJson(Map<String, dynamic>? data) {
    if (data != null) {
      final tabs = data['tabs'] as Map<String, dynamic>? ?? {};
      for (var entry in tabs.entries) {
        final tabData = entry.value as Map<String, dynamic>;
        final dockTab = DockTab(
          id: entry.key,
          parentDockTabId: id,
          initData: tabData,
          defaultDockingItemConfig:
              tabData['defaultDockingItemConfig'] as Map<String, dynamic>? ??
              {},
        );
        _dockTabs[entry.key] = dockTab;
      }
    }
    _rebuildGlobalLayout();
    // 恢复激活状态
    // final activeTabId = data['activeTabId'] as String?;
    // if (activeTabId != null && _dockTabs.containsKey(activeTabId)) {
    //   _activeTabId = activeTabId;
    // }
  }

  void loadFromJson(Map<String, dynamic> json) {
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
    // 在添加新tab之前，检查并清除所有默认空tab
    _clearDefaultEmptyTabs();

    final dockTab = DockTab(
      id: tabId,
      displayName: displayName,
      parentDockTabId: id,
      initData: initData,
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

    _dockTabs[tabId] = dockTab;
    _activeTabId ??= tabId;

    // 发送tab创建事件
    emitEvent(
      DockTabEvent(
        type: DockEventType.tabCreated,
        dockTabsId: id,
        values: {'tabs': this, 'item': null},
      ),
    );
    return dockTab;
  }

  void emitEvent(DockEvent event) {
    if (event.type == DockEventType.tabClosed) {
      // 更新布局信息，因为布局要跟标签数量一致
      updateLayout();
    }
    _eventStreamController?.emit(event);
  }

  /// 移除DockTab
  bool removeDockTab(String tabId) {
    final dockTab = _dockTabs.remove(tabId);
    if (dockTab != null) {
      // 发送tab关闭事件
      emitEvent(
        DockTabEvent(
          type: DockEventType.tabClosed,
          dockTabsId: id,
          values: {'tabId': tabId, 'displayName': dockTab.displayName},
        ),
      );
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

  /// 重建全局布局（使用 RxDart 防抖控制）
  void _rebuildGlobalLayout() {
    print('🔄 DockTabs._rebuildGlobalLayout called');
    emitEvent(DockLayoutEvent(dockTabsId: id));
  }

  /// 执行实际的布局重建
  void rebuild() {
    // 多个tab时，创建tab布局，将所有tab作为DockingItem显示
    final tabItems =
        _dockTabs.entries.map((entry) {
          final tab = entry.value;
          final tabId = entry.key;
          final config = tab.getDefaultDockingItemConfig();

          DockLayoutManager.registerParser(
            '${id}_${entry.key}_layout',
            DefaultDockLayoutParser(dockTabsId: id, tabId: entry.key),
          );

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

    final mainParser = DefaultDockLayoutParser(dockTabsId: id, tabId: '');
    DockLayoutManager.registerParser('${id}_layout', mainParser);
    // 创建一个新的布局实例来加载数据
    _globalLayout = DockingLayout(
      root:
          tabItems.isNotEmpty
              ? DockingTabs(tabItems)
              : DockManager.createDefaultHomePageDockItem(),
    );
    if (tabItems.isNotEmpty) {
      // 恢复布局
      DockLayoutManager.loadLayout('${id}_layout', _globalLayout!);
    }
    emitEvent(DockLayoutEvent(dockTabsId: id));
  }

  /// 构建子Tab内容
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

      return TabbedView(controller: TabbedViewController(tabDataList));
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
      setLayout(result);
      _rebuildGlobalLayout();
    }
  }

  /// 构建带主题的Docking Widget
  Widget buildDockingWidget(BuildContext context) {
    rebuild(); // 触发布局重建
    Docking docking = Docking(
      layout: _globalLayout,
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
    );
    return TabbedViewTheme(
      data: _themeData ?? DockTheme.createCustomThemeData(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: MultiSplitViewTheme(
          child: docking,
          data: MultiSplitViewThemeData(
            dividerPainter: DividerPainters.grooved1(
              color: Colors.indigo[100]!,
              highlightedColor: Colors.indigo[900]!,
            ),
          ),
        ),
      ),
    );
  }

  /// 处理DockItem关闭事件
  void _handleItemClose(DockingItem dockingItem) {
    final exists = _dockTabs.containsKey(dockingItem.id);
    if (exists) {
      _dockTabs.remove(dockingItem.id);
    }
    // 总是触发关闭事件
    emitEvent(
      DockTabEvent(
        type: DockEventType.tabClosed,
        dockTabsId: id,
        values: {'item': dockingItem, 'tabs': this},
      ),
    );
  }

  /// 处理DockItem选择事件
  void _handleItemSelection(DockingItem dockingItem) {
    // 这里可以添加选择事件的处理逻辑
    _activeTabId = dockingItem.id;
    // item选择事件
    emitEvent(
      DockTabEvent(
        type: DockEventType.tabSelected,
        dockTabsId: id,
        values: {'item': dockingItem, 'tabs': this},
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
    emitEvent(
      DockTabEvent(
        type: DockEventType.layoutChanged,
        dockTabsId: id,
        values: {'action': 'itemMove'},
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
    emitEvent(
      DockTabEvent(
        type: DockEventType.tabPositionChanged,
        dockTabsId: id,
        values: {'action': 'tabLayoutChanged'},
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
    emitEvent(
      DockTabEvent(
        type: DockEventType.tabPositionChanged,
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
  bool addDockItemToTab(String tabId, DockItem dockItem) {
    final dockTab = getDockTab(tabId);
    if (dockTab != null) {
      // 在添加DockItem之前，清除其他的默认空tab
      _clearDefaultEmptyTabs();
      // 传递rebuildLayout参数，避免DockTab内部立即刷新布局
      dockTab.addDockItem(dockItem, rebuildLayout: false);
      // 发送item创建事件
      emitEvent(
        DockTabEvent(
          type: DockEventType.tabCreated,
          dockTabsId: id,
          values: {'item': dockItem, 'tabs': this},
        ),
      );
      return true;
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
    emitEvent(
      DockTabEvent(
        type: DockEventType.allTabsCleared,
        dockTabsId: id,
        values: {'tabs': this},
      ),
    );
  }

  /// 释放资源
  void dispose() {
    _emitSubscription.cancel();
    _emitdSubject.close();
    clear();
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

  /// 更新布局缓存并返回当前布局
  String updateLayout() {
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
      _globalLayout!,
      mainParser!,
    );

    return layoutString;
  }

  /// 加载布局
  bool setLayout(String layoutString) {
    DockLayoutManager.setSavedLayout('${id}_layout', layoutString);
    return true;
  }
}
