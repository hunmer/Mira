import 'package:flutter/material.dart';
import 'package:mira/dock/dock_theme.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'dock_tab.dart';
import 'dock_item.dart';
import 'dock_layout_parser.dart';

/// DockTabs类 - 管理多个DockTab，提供全局的TabbedViewTheme和Docking
class DockTabs {
  final String id;
  final Map<String, DockTab> _dockTabs = {};
  late DockingLayout _globalLayout;
  final ValueNotifier<int> _layoutChangeNotifier = ValueNotifier<int>(0);
  void Function(DockingItem)? _onItemClose;
  String? _activeTabId;
  TabbedViewThemeData? _themeData;

  DockTabs({
    required this.id,
    Map<String, dynamic>? initData,
    TabbedViewThemeData? themeData,
    void Function(DockingItem)? onItemClose,
  }) {
    _themeData = themeData;
    _onItemClose = onItemClose;
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
        onLayoutChanged: _rebuildGlobalLayout,
      );
      _dockTabs[entry.key] = dockTab;
    }

    _rebuildGlobalLayout();
  }

  /// 创建新的DockTab
  DockTab createDockTab(
    String tabId, {
    String? displayName,
    Map<String, dynamic>? initData,
    // DockingItem 默认属性配置
    bool closable = true,
    bool keepAlive = false,
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

    // 如果这是第一个tab或者没有激活的tab，将其设为激活状态
    if (_activeTabId == null || _dockTabs.length == 1) {
      _activeTabId = tabId;
    }

    _rebuildGlobalLayout();
    return dockTab;
  }

  /// 移除DockTab
  bool removeDockTab(String tabId) {
    final dockTab = _dockTabs.remove(tabId);
    if (dockTab != null) {
      dockTab.dispose();
      _rebuildGlobalLayout();
      return true;
    }
    return false;
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
    if (_dockTabs.containsKey(tabId)) {
      _activeTabId = tabId;
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
              buttons: (config['buttons'] as List<TabButton>?) ?? [],
              maximizable: config['maximizable'] ?? false,
              maximized: config['maximized'] ?? false,
              leading: config['leading'],
              size: config['size'],
              weight: config['weight'],
              minimalWeight: config['minimalWeight'],
              minimalSize: config['minimalSize'],
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
                  print(
                    '❌ OnItemClose - Item: ${item.name ?? item.id}, ID: ${item.id}',
                  );
                  _handleItemClose(item);
                },
                onItemSelection: (DockingItem item) {
                  print(
                    '🎯 OnItemSelection - Item: ${item.name ?? item.id}, ID: ${item.id}',
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

  /// 添加DockItem到指定的DockTab
  bool addDockItemToTab(String tabId, DockItem dockItem) {
    final dockTab = getDockTab(tabId);
    if (dockTab != null) {
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
    for (var entry in _dockTabs.entries) {
      tabsMap[entry.key] = entry.value.toJson();
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
    final mainParser = DefaultDockLayoutParser(
      dockTabsId: id,
      tabId: _activeTabId ?? _dockTabs.keys.first,
    );
    DockLayoutManager.registerParser('${id}_layout', mainParser);

    // 同时为每个子tab注册parser
    for (var entry in _dockTabs.entries) {
      final tabParser = DefaultDockLayoutParser(
        dockTabsId: id,
        tabId: entry.key,
      );
      DockLayoutManager.registerParser('${id}_${entry.key}_layout', tabParser);
    }

    final layoutString = DockLayoutManager.saveLayout(
      '${id}_layout',
      _globalLayout,
      mainParser,
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
