import '../widgets/docking_dock_item.dart';

/// DockingExampleService - 展示如何使用DockingDockItem的示例服务
class DockingExampleService {
  /// 创建一个简单的docking标签页
  static String createSimpleDockingTab({
    String title = 'Simple Docking',
    String dockTabsId = 'main',
    String? dockTabId,
  }) {
    return DockingDockItem.addTab(
      title: title,
      dockTabsId: dockTabsId,
      dockTabId: dockTabId,
    );
  }

  /// 创建一个复杂的docking标签页，包含自定义布局
  static String createComplexDockingTab({
    String title = 'Complex Docking',
    String dockTabsId = 'main',
    String? dockTabId,
  }) {
    // 自定义布局配置
    final customLayoutData = {
      'type': 'row',
      'items': [
        {
          'id': 'left_panel',
          'name': 'Left Panel',
          'type': 'item',
          'closable': false,
          'maximizable': true,
          'keepAlive': true,
          'weight': 0.3,
        },
        {
          'type': 'column',
          'items': [
            {
              'id': 'top_center',
              'name': 'Top Center',
              'type': 'item',
              'closable': true,
              'maximizable': true,
              'keepAlive': false,
              'weight': 0.6,
            },
            {
              'type': 'tabs',
              'items': [
                {
                  'id': 'tab1',
                  'name': 'Tab 1',
                  'type': 'item',
                  'closable': true,
                  'maximizable': true,
                  'keepAlive': true,
                },
                {
                  'id': 'tab2',
                  'name': 'Tab 2',
                  'type': 'item',
                  'closable': true,
                  'maximizable': true,
                  'keepAlive': true,
                },
                {
                  'id': 'tab3',
                  'name': 'Tab 3',
                  'type': 'item',
                  'closable': true,
                  'maximizable': true,
                  'keepAlive': false,
                },
              ],
            },
          ],
        },
        {
          'id': 'right_panel',
          'name': 'Right Panel',
          'type': 'item',
          'closable': true,
          'maximizable': false,
          'keepAlive': true,
          'weight': 0.25,
          'minimalSize': 200.0,
        },
      ],
    };

    // 自定义主题配置
    final customThemeConfig = {
      'divider': {
        'thickness': 6.0,
        'color': 0xFF2196F3, // Blue
        'highlightedColor': 0xFFFFFFFF, // White
        'backgroundColor': 0xFF1976D2, // Dark Blue
        'painter': 'grooved2',
      },
      'tabs': {
        'theme': 'dark',
        'tabsAreaButtonsVisibility': true,
        'tabsAreaVisible': true,
        'contentAreaVisible': true,
        'menuButtonTooltip': 'Show menu',
      },
    };

    // 自定义按钮配置
    final customButtonsConfig = {
      'enabled': true,
      'buttons': [
        {
          'id': 'refresh',
          'icon': 'refresh',
          'tooltip': 'Refresh Layout',
          'onPressed': 'refresh',
        },
        {
          'id': 'add',
          'icon': 'add',
          'tooltip': 'Add New Item',
          'onPressed': 'add',
        },
        {
          'id': 'settings',
          'icon': 'settings',
          'tooltip': 'Settings',
          'onPressed': 'settings',
        },
      ],
    };

    return DockingDockItem.addTab(
      title: title,
      layoutData: customLayoutData,
      themeConfig: customThemeConfig,
      buttonsConfig: customButtonsConfig,
      dockTabsId: dockTabsId,
      dockTabId: dockTabId,
    );
  }

  /// 创建一个展示不同布局类型的docking标签页
  static String createLayoutDemoTab({
    String title = 'Layout Demo',
    String dockTabsId = 'main',
    String? dockTabId,
  }) {
    final layoutDemoData = {
      'type': 'tabs',
      'items': [
        {
          'id': 'demo1',
          'name': 'Row Layout Demo',
          'type': 'item',
          'closable': true,
          'maximizable': true,
          'keepAlive': true,
        },
        {
          'id': 'demo2',
          'name': 'Column Layout Demo',
          'type': 'item',
          'closable': true,
          'maximizable': true,
          'keepAlive': true,
        },
        {
          'id': 'demo3',
          'name': 'Mixed Layout Demo',
          'type': 'item',
          'closable': true,
          'maximizable': true,
          'keepAlive': true,
        },
      ],
    };

    return DockingDockItem.addTab(
      title: title,
      layoutData: layoutDemoData,
      dockTabsId: dockTabsId,
      dockTabId: dockTabId,
    );
  }

  /// 演示如何动态修改docking配置
  static void demonstrateConfigModification() {
    // 这里演示如何通过DockManager获取和修改docking项
    // 注意：这需要实际的tabId和dockTabsId
    /*
    final tabId = 'your_tab_id_here';
    final dockTabsId = 'main';
    
    // 获取dock item
    final dockItem = DockManager.getDockItem(dockTabsId, tabId);
    if (dockItem is DockingDockItem) {
      // 修改layout数据
      final currentLayout = dockItem.getLayoutData();
      if (currentLayout != null) {
        // 添加新的item到layout
        final newItem = {
          'id': 'new_item_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Dynamic Item',
          'type': 'item',
          'closable': true,
          'maximizable': true,
          'keepAlive': false,
        };
        
        // 如果是row或column，直接添加到items
        if (currentLayout['type'] == 'row' || currentLayout['type'] == 'column') {
          final items = List<Map<String, dynamic>>.from(currentLayout['items'] ?? []);
          items.add(newItem);
          currentLayout['items'] = items;
          dockItem.updateLayoutData(currentLayout);
        }
      }
      
      // 修改主题配置
      final currentTheme = dockItem.getThemeConfig();
      if (currentTheme != null) {
        final dividerConfig = Map<String, dynamic>.from(currentTheme['divider'] ?? {});
        dividerConfig['thickness'] = 8.0;
        dividerConfig['color'] = 0xFF4CAF50; // Green
        currentTheme['divider'] = dividerConfig;
        dockItem.updateThemeConfig(currentTheme);
      }
      
      // 修改按钮配置
      final currentButtons = dockItem.getButtonsConfig();
      if (currentButtons != null) {
        final buttons = List<Map<String, dynamic>>.from(currentButtons['buttons'] ?? []);
        buttons.add({
          'id': 'custom',
          'icon': 'star',
          'tooltip': 'Custom Action',
          'onPressed': 'custom',
        });
        currentButtons['buttons'] = buttons;
        dockItem.updateButtonsConfig(currentButtons);
      }
    }
    */
  }

  /// 获取一些预定义的配置模板
  static Map<String, Map<String, dynamic>> getConfigTemplates() {
    return {
      'simple_row': {
        'type': 'row',
        'items': [
          {'id': 'item1', 'name': 'Item 1', 'type': 'item', 'weight': 0.5},
          {'id': 'item2', 'name': 'Item 2', 'type': 'item', 'weight': 0.5},
        ],
      },
      'simple_column': {
        'type': 'column',
        'items': [
          {'id': 'item1', 'name': 'Top Item', 'type': 'item', 'weight': 0.4},
          {'id': 'item2', 'name': 'Bottom Item', 'type': 'item', 'weight': 0.6},
        ],
      },
      'simple_tabs': {
        'type': 'tabs',
        'items': [
          {'id': 'tab1', 'name': 'Tab 1', 'type': 'item'},
          {'id': 'tab2', 'name': 'Tab 2', 'type': 'item'},
          {'id': 'tab3', 'name': 'Tab 3', 'type': 'item'},
        ],
      },
      'ide_layout': {
        'type': 'row',
        'items': [
          {
            'id': 'explorer',
            'name': 'Explorer',
            'type': 'item',
            'weight': 0.2,
            'closable': false,
            'minimalSize': 200.0,
          },
          {
            'type': 'column',
            'items': [
              {
                'type': 'tabs',
                'items': [
                  {
                    'id': 'editor1',
                    'name': 'main.dart',
                    'type': 'item',
                    'keepAlive': true,
                  },
                  {
                    'id': 'editor2',
                    'name': 'widgets.dart',
                    'type': 'item',
                    'keepAlive': true,
                  },
                ],
              },
              {
                'type': 'tabs',
                'items': [
                  {'id': 'terminal', 'name': 'Terminal', 'type': 'item'},
                  {'id': 'debug', 'name': 'Debug Console', 'type': 'item'},
                ],
              },
            ],
          },
          {
            'id': 'properties',
            'name': 'Properties',
            'type': 'item',
            'weight': 0.25,
            'minimalSize': 250.0,
          },
        ],
      },
    };
  }
}
