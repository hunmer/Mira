import 'package:flutter/material.dart';
import 'package:mira/dock/dock_theme.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'dock_tab.dart';
import 'dock_item.dart';
import 'dock_layout_parser.dart';
import 'dock_events.dart';

/// DockTabs类 - 管理多个DockTab，提供全局的TabbedViewTheme和Docking
class DockTabs {
  final String id;
  final Map<String, DockTab> _dockTabs = {};
  late DockingLayout _globalLayout;
  final ValueNotifier<int> _layoutChangeNotifier = ValueNotifier<int>(0);
  void Function(DockingItem)? _onItemClose;
  void Function(DockingItem)? _onItemSelection;
  void Function(DockingItem, DropArea, DropPosition?, int?)? _onItemMove;
  void Function(DockingItem, DockingItem, DropArea, DropPosition?, int?)?
  _onItemLayoutChanged;

  String? _activeTabId;
  TabbedViewThemeData? _themeData;
  DefaultDockLayoutParser? mainParser;
  DockEventStreamController? _eventStreamController;

  DockTabs({
    required this.id,
    Map<String, dynamic>? initData,
    TabbedViewThemeData? themeData,
    void Function(DockingItem)? onItemClose,
    void Function(DockingItem)? onItemSelection,
    void Function(DockingItem, DropArea, DropPosition?, int?)? onItemMove,
    void Function(DockingItem, DockingItem, DropArea, DropPosition?, int?)?
    onItemLayoutChanged,
    DockEventStreamController? eventStreamController,
  }) {
    _themeData = themeData;
    _onItemClose = onItemClose;
    _onItemSelection = onItemSelection;
    _onItemMove = onItemMove;
    _onItemLayoutChanged = onItemLayoutChanged;
    _eventStreamController = eventStreamController;

    if (initData != null) {
      _initializeFromJson(initData);
    } else {
      // 创建一个默认的空布局
      _globalLayout = DockingLayout(
        root: DockingItem(
          name: 'empty',
          widget: const Center(child: Text('No content')),
        ),
      );
    }
  }

  bool get isEmpty => _dockTabs.isEmpty;

  /// 从JSON数据初始化
  void _initializeFromJson(Map<String, dynamic> json) {
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

    _rebuildGlobalLayout();
  }

  /// 公共方法：从JSON数据重新加载
  void loadFromJson(Map<String, dynamic> json) {
    // 清除现有数据
    clear();

    // 重新初始化
    _initializeFromJson(json);

    // 恢复激活状态
    final activeTabId = json['activeTabId'] as String?;
    if (activeTabId != null && _dockTabs.containsKey(activeTabId)) {
      _activeTabId = activeTabId;
    }

    // 检查是否需要创建默认空tab
    final hasDefaultEmptyTabs = json['hasDefaultEmptyTabs'] as bool? ?? false;
    if (_dockTabs.isEmpty || hasDefaultEmptyTabs) {
      // 如果没有tab或者之前有默认空tab，创建一个新的默认空tab
      createDockTab(
        'home',
        displayName: '首页',
        closable: false,
        maximizable: false,
        buttons: [],
      );
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
        tabId: tabId,
        displayName: displayName,
      ),
    );

    _rebuildGlobalLayout();
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
          tabId: tabId,
          displayName: dockTab.displayName,
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

    for (var entry in _dockTabs.entries) {
      if (entry.value.isDefaultEmpty) {
        tabsToRemove.add(entry.key);
      }
    }

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
            tabId: tabId,
            displayName: dockTab.displayName,
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
          type: DockEventType.tabSwitched,
          dockTabsId: id,
          tabId: tabId,
          displayName: _dockTabs[tabId]?.displayName,
          data: {'previousTabId': previousTabId},
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
    if (_dockTabs.isEmpty) {
      _globalLayout = DockingLayout(
        root: DockingItem(
          name: 'empty',
          widget: const Center(child: Text('No content')),
        ),
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
          root: DockingItem(
            name: 'empty',
            widget: const Center(child: Text('No content')),
          ),
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
              value: dockingItem, // 🔧 修复：添加 value 字段
              text: dockingItem.name ?? 'Untitled',
              content: dockingItem.widget,
              closable: dockingItem.closable,
            );
          }).toList();

      return TabbedView(
        controller: TabbedViewController(tabDataList),
        onDraggableBuild: (controller, tabIndex, tabData) {
          // 🔧 修复：正确实现拖拽配置
          final dockingItem = tabData.value as DockingItem;
          return DraggableConfig(
            feedback: Material(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(),
                  color: Colors.grey[300],
                ),
                child: Text(
                  dockingItem.name ?? 'Untitled',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },

        onTabClose: (tabIndex, tabData) {
          print('❌ OnTabClose - TabIndex: $tabIndex, TabData: ${tabData.text}');
        },
        onTabSelection: (newTabIndex) {
          print('🎯 OnTabSelection - NewTabIndex: $newTabIndex');
          return true;
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
                onItemClose: (DockingItem item) {
                  _handleItemClose(item);
                },
                onItemSelection: (DockingItem item) {
                  _handleItemSelection(item);
                },
                onItemMove: ({
                  required DockingItem draggedItem,
                  required DropArea targetArea,
                  DropPosition? dropPosition,
                  int? dropIndex,
                }) {
                  _handleItemMove(
                    draggedItem,
                    targetArea,
                    dropPosition,
                    dropIndex,
                  );
                },
                onItemLayoutChanged: ({
                  required DockingItem oldItem,
                  required DockingItem newItem,
                  required DropArea targetArea,
                  DropPosition? newIndex,
                  int? dropIndex,
                }) {
                  _handleItemLayoutChanged(
                    oldItem,
                    newItem,
                    targetArea,
                    newIndex,
                    dropIndex,
                  );
                },
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

  /// 处理DockItem关闭事件
  void _handleItemClose(DockingItem dockingItem) {
    // 从所有DockTab中查找并移除对应的DockItem
    for (var dockTab in _dockTabs.values) {
      if (dockTab.removeDockItem(dockingItem.name ?? '')) {
        break; // 找到并移除后跳出循环
      }
    }

    // 调用外部回调
    _onItemClose?.call(dockingItem);
  }

  /// 处理DockItem选择事件

  void _handleItemSelection(DockingItem dockingItem) {
    // 这里可以添加选择事件的处理逻辑
    print('Item selected: ${dockingItem.name}');
    _onItemSelection?.call(dockingItem);
  }

  /// 处理DockItem移动事件
  void _handleItemMove(
    DockingItem draggedItem,
    DropArea targetArea,
    DropPosition? dropPosition,
    int? dropIndex,
  ) {
    // 这里可以添加移动事件的处理逻辑
    print(
      'Dragged item: ${draggedItem.name}, Target area: $targetArea, Drop position: $dropPosition, Drop index: $dropIndex',
    );
    _onItemMove?.call(draggedItem, targetArea, dropPosition, dropIndex);
  }

  /// 处理DockItem布局变化事件
  ///
  void _handleItemLayoutChanged(
    DockingItem oldItem,
    DockingItem newItem,
    DropArea targetArea,
    DropPosition? newIndex,
    int? dropIndex,
  ) {
    // 这里可以添加布局变化事件的处理逻辑
    print(
      'Old item: ${oldItem.name}, New item: ${newItem.name}, Target area: $targetArea, Drop position: $newIndex, Drop index: $dropIndex',
    );
    _onItemLayoutChanged?.call(
      oldItem,
      newItem,
      targetArea,
      newIndex,
      dropIndex,
    );
  }

  /// 添加DockItem到指定的DockTab
  bool addDockItemToTab(String tabId, DockItem dockItem) {
    final dockTab = getDockTab(tabId);
    if (dockTab != null) {
      // 在添加DockItem之前，清除其他的默认空tab
      _clearDefaultEmptyTabs();

      dockTab.addDockItem(dockItem);
      _refreshGlobalLayout();
      return true;
    }
    return false;
  }

  /// 从指定的DockTab移除DockItem
  bool removeDockItemFromTab(String tabId, String itemTitle) {
    final dockTab = getDockTab(tabId);
    if (dockTab != null) {
      final result = dockTab.removeDockItem(itemTitle);
      if (result) {
        _refreshGlobalLayout();
      }
      return result;
    }
    return false;
  }

  /// 获取指定DockTab中的DockItem
  DockItem? getDockItemFromTab(String tabId, String itemTitle) {
    final dockTab = getDockTab(tabId);
    return dockTab?.getDockItem(itemTitle);
  }

  /// 更新指定DockTab中的DockItem
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
      if (!dockTab.shouldSkipSerialization) {
        tabsMap[entry.key] = dockTab.toJson();
      } else {
        // 如果跳过的tab是当前激活的tab，需要重新选择一个激活tab
        if (_activeTabId == entry.key) {
          activeTabIdToSave =
              tabsMap.keys.isNotEmpty ? tabsMap.keys.first : null;
        }
      }
    }

    return {
      'id': id,
      'tabs': tabsMap,
      'activeTabId': activeTabIdToSave,
      'hasDefaultEmptyTabs': _dockTabs.values.any((tab) => tab.isDefaultEmpty),
    };
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
