import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';
import 'package:mira/multi_split_view/lib/multi_split_view.dart';
import '../models/docking_tab_data.dart';

/// DockingContentView - Docking内容视图
class DockingContentView extends StatefulWidget {
  final DockingTabData tabData;

  const DockingContentView({super.key, required this.tabData});

  @override
  State<DockingContentView> createState() => _DockingContentViewState();
}

class _DockingContentViewState extends State<DockingContentView>
    with TickerProviderStateMixin {
  late DockingLayout _dockingLayout;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDockingLayout();
  }

  @override
  void didUpdateWidget(DockingContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabData != widget.tabData) {
      _initializeDockingLayout();
    }
  }

  /// 初始化Docking布局
  void _initializeDockingLayout() {
    try {
      final layoutData =
          widget.tabData.stored['layoutData'] as Map<String, dynamic>?;
      if (layoutData != null) {
        _dockingLayout = _buildLayoutFromData(layoutData);
      } else {
        _dockingLayout = _buildDefaultLayout();
      }
      _isInitialized = true;
    } catch (e) {
      print('Error initializing docking layout: $e');
      _dockingLayout = _buildDefaultLayout();
      _isInitialized = true;
    }

    if (mounted) {
      setState(() {});
    }
  }

  /// 从数据构建布局
  DockingLayout _buildLayoutFromData(Map<String, dynamic> layoutData) {
    final root = _buildAreaFromData(layoutData);
    return DockingLayout(root: root);
  }

  /// 从数据构建区域
  DockingArea _buildAreaFromData(Map<String, dynamic> data) {
    final type = data['type'] as String;
    final items = data['items'] as List<dynamic>? ?? [];

    switch (type) {
      case 'row':
        final areas =
            items
                .map((item) => _buildAreaFromData(item as Map<String, dynamic>))
                .toList();
        return DockingRow(areas);
      case 'column':
        final areas =
            items
                .map((item) => _buildAreaFromData(item as Map<String, dynamic>))
                .toList();
        return DockingColumn(areas);
      case 'tabs':
        final dockingItems =
            items
                .map((item) => _buildAreaFromData(item as Map<String, dynamic>))
                .whereType<DockingItem>()
                .toList();
        return DockingTabs(dockingItems);
      case 'item':
      default:
        return _buildDockingItem(data);
    }
  }

  /// 构建DockingItem
  DockingItem _buildDockingItem(Map<String, dynamic> data) {
    final id =
        data['id'] as String? ??
        'item_${DateTime.now().millisecondsSinceEpoch}';
    final name = data['name'] as String? ?? 'Item';
    final closable = data['closable'] as bool? ?? true;
    final maximizable = data['maximizable'] as bool? ?? true;
    final keepAlive = data['keepAlive'] as bool? ?? false;
    final weight = data['weight'] as double?;
    final size = data['size'] as double?;
    final minimalSize = data['minimalSize'] as double?;

    return DockingItem(
      id: id,
      name: name,
      closable: closable,
      maximizable: maximizable,
      keepAlive: keepAlive,
      weight: weight,
      size: size,
      minimalSize: minimalSize,
      widget: _buildItemWidget(id, name),
      buttons: _buildItemButtons(data),
      leading: _buildLeadingWidget(data),
    );
  }

  /// 构建Item的Widget内容
  Widget _buildItemWidget(String id, String name) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Docking Item: $name',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('ID: $id'),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dashboard, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      'Content Area for $name',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _addNewItem(),
                      child: const Text('Add Item'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建Item按钮
  List<TabButton>? _buildItemButtons(Map<String, dynamic> data) {
    final buttonsConfig =
        widget.tabData.stored['buttonsConfig'] as Map<String, dynamic>?;
    if (buttonsConfig == null ||
        !(buttonsConfig['enabled'] as bool? ?? false)) {
      return null;
    }

    final buttons = buttonsConfig['buttons'] as List<dynamic>? ?? [];
    return buttons.map((buttonData) {
      final buttonMap = buttonData as Map<String, dynamic>;
      final iconName = buttonMap['icon'] as String? ?? 'settings';
      final tooltip = buttonMap['tooltip'] as String? ?? '';
      final action = buttonMap['onPressed'] as String? ?? '';

      return TabButton(
        icon: IconProvider.data(_getIconData(iconName)),
        onPressed: () => _handleButtonAction(action),
      );
    }).toList();
  }

  /// 构建Leading Widget
  Widget Function(BuildContext, TabStatus)? _buildLeadingWidget(
    Map<String, dynamic> data,
  ) {
    final itemProperties =
        widget.tabData.stored['itemProperties'] as Map<String, dynamic>?;
    final leadingWidget = itemProperties?['leadingWidget'] as String?;

    if (leadingWidget != null) {
      return (context, status) => Icon(_getIconData(leadingWidget), size: 16);
    }

    return null;
  }

  /// 获取图标数据
  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'refresh':
        return Icons.refresh;
      case 'add':
        return Icons.add;
      case 'dashboard':
        return Icons.dashboard;
      case 'star':
        return Icons.star;
      case 'folder':
        return Icons.folder;
      default:
        return Icons.widgets;
    }
  }

  /// 处理按钮动作
  void _handleButtonAction(String action) {
    switch (action.toLowerCase()) {
      case 'refresh':
        _refreshLayout();
        break;
      case 'add':
        _addNewItem();
        break;
      default:
        print('Unknown action: $action');
    }
  }

  /// 刷新布局
  void _refreshLayout() {
    _initializeDockingLayout();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Layout refreshed')));
  }

  /// 添加新项目
  void _addNewItem() {
    final newItemId = 'item_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = DockingItem(
      id: newItemId,
      name: 'New Item',
      widget: _buildItemWidget(newItemId, 'New Item'),
    );

    // 这里可以实现动态添加逻辑
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added new item: $newItemId')));
  }

  /// 构建默认布局
  DockingLayout _buildDefaultLayout() {
    return DockingLayout(
      root: DockingRow([
        DockingItem(
          id: 'item1',
          name: 'Item 1',
          widget: _buildItemWidget('item1', 'Item 1'),
        ),
        DockingColumn([
          DockingItem(
            id: 'item2',
            name: 'Item 2',
            widget: _buildItemWidget('item2', 'Item 2'),
          ),
          DockingTabs([
            DockingItem(
              id: 'item3',
              name: 'Item 3',
              widget: _buildItemWidget('item3', 'Item 3'),
            ),
            DockingItem(
              id: 'item4',
              name: 'Item 4',
              widget: _buildItemWidget('item4', 'Item 4'),
            ),
          ]),
        ]),
      ]),
    );
  }

  /// 构建Theme
  Widget _buildThemedDocking(Widget docking) {
    final themeConfig =
        widget.tabData.stored['themeConfig'] as Map<String, dynamic>?;
    if (themeConfig == null) return docking;

    Widget themedWidget = docking;

    // 应用Tabs主题
    final tabsConfig = themeConfig['tabs'] as Map<String, dynamic>?;
    if (tabsConfig != null) {
      final themeType = tabsConfig['theme'] as String? ?? 'mobile';
      TabbedViewThemeData tabbedTheme;

      switch (themeType) {
        case 'dark':
        case 'light':
        case 'mobile':
        default:
          // 使用默认主题构造函数
          tabbedTheme = TabbedViewThemeData();
          break;
      }

      themedWidget = TabbedViewTheme(data: tabbedTheme, child: themedWidget);
    }

    // 应用Divider主题
    final dividerConfig = themeConfig['divider'] as Map<String, dynamic>?;
    if (dividerConfig != null) {
      final thickness = dividerConfig['thickness'] as double? ?? 4.0;
      final color = Color(dividerConfig['color'] as int? ?? 0xFF424242);
      final highlightedColor = Color(
        dividerConfig['highlightedColor'] as int? ?? 0xFFFFFFFF,
      );
      final backgroundColor = Color(
        dividerConfig['backgroundColor'] as int? ?? 0xFF616161,
      );

      themedWidget = MultiSplitViewTheme(
        data: MultiSplitViewThemeData(
          dividerThickness: thickness,
          dividerPainter: DividerPainters.grooved2(
            backgroundColor: backgroundColor,
            color: color,
            highlightedColor: highlightedColor,
          ),
        ),
        child: themedWidget,
      );
    }

    return themedWidget;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final docking = Docking(
      layout: _dockingLayout,
      onItemSelection: (DockingItem item) {
        print('Selected item: ${item.name}');
      },
      onItemClose: (DockingItem item) {
        print('Closed item: ${item.name}');
      },
      itemCloseInterceptor: (DockingItem item) {
        final itemProperties =
            widget.tabData.stored['itemProperties'] as Map<String, dynamic>?;
        final closeInterceptor =
            itemProperties?['closeInterceptor'] as bool? ?? true;

        if (closeInterceptor && item.name == 'Item 1') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item 1 cannot be closed'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      dockingButtonsBuilder: _buildDockingButtons,
    );

    return _buildThemedDocking(docking);
  }

  /// 构建Docking按钮
  List<TabButton> _buildDockingButtons(
    BuildContext context,
    DockingTabs? dockingTabs,
    DockingItem? dockingItem,
  ) {
    final buttonsConfig =
        widget.tabData.stored['buttonsConfig'] as Map<String, dynamic>?;
    if (buttonsConfig == null ||
        !(buttonsConfig['enabled'] as bool? ?? false)) {
      return [];
    }

    if (dockingTabs != null) {
      // 为DockingTabs区域提供按钮
      return [
        TabButton(
          icon: IconProvider.data(Icons.add),
          onPressed: () => _addNewItem(),
        ),
      ];
    }

    // 为DockingItem提供按钮
    return [
      TabButton(
        icon: IconProvider.data(Icons.refresh),
        onPressed: () => _refreshLayout(),
      ),
    ];
  }
}
