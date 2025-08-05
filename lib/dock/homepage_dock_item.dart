import 'package:flutter/material.dart';
import 'package:mira/dock/dock_tab.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'dock_item.dart';

/// HomePage DockItem - 默认的首页面板
class HomePageDockItem extends DockItem {
  final VoidCallback? onCreateNewTab;
  static bool _isBuilderRegistered = false;

  HomePageDockItem({this.onCreateNewTab, String title = 'Home'})
    : super(
        type: 'homepage',
        title: title,
        values: {},
        builder: (dockItem) => _buildDockingItem(dockItem),
      ) {
    _ensureBuilderRegistered();
  }

  /// 确保homepage类型的builder已经注册
  static void _ensureBuilderRegistered() {
    if (!_isBuilderRegistered) {
      registerHomePageTabBuilder();
      _isBuilderRegistered = true;
    }
  }

  /// 注册homepage类型的builder
  static void registerHomePageTabBuilder() {
    DockTab.registerBuilder('homepage', (dockItem) {
      if (dockItem is HomePageDockItem) {
        return DockingItem(
          name: dockItem.title,
          widget: _buildHomePageWidget(dockItem),
        );
      }

      // 如果不是HomePageDockItem实例，创建默认首页
      return DockingItem(
        name: dockItem.title,
        widget: _buildHomePageWidget(HomePageDockItem(title: dockItem.title)),
      );
    });
  }

  /// 静态方法：手动注册builder（供外部调用）
  static void ensureRegistered() {
    _ensureBuilderRegistered();
  }

  /// 构建DockingItem
  static DockingItem _buildDockingItem(DockItem dockItem) {
    return DockingItem(
      name: dockItem.title,
      widget: _buildHomePageWidget(dockItem),
    );
  }

  static Widget _buildHomePageWidget(DockItem dockItem) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to the Home Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Handle new tab creation
              if (dockItem is HomePageDockItem &&
                  dockItem.onCreateNewTab != null) {
                dockItem.onCreateNewTab!();
              }
            },
            child: Text('Create New Tab'),
          ),
        ],
      ),
    );
  }
}
