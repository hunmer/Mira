import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'dock_manager.dart';
import 'dock_tabs.dart';

/// DockController - 控制器类，管理Dock系统的业务逻辑
class DockController extends ChangeNotifier {
  late DockTabs _dockTabs;
  String _lastSavedLayout = '';

  DockTabs get dockTabs => _dockTabs;
  String get lastSavedLayout => _lastSavedLayout;
  bool get hasValidSavedLayout => _lastSavedLayout.isNotEmpty;

  /// 初始化Dock系统
  void initializeDockSystem() {
    // 创建主要的DockTabs，添加onItemClose回调
    _dockTabs = DockManager.createDockTabs(
      'main',
      onItemClose: (DockingItem item) {
        // 这个回调将在UI层处理
        notifyListeners();
      },
    );
    if (_dockTabs.isEmpty) {
      // 创建默认tab和内容
      _createDefaultTabs();
    }
  }

  /// 创建默认的tabs和内容
  void _createDefaultTabs() {
    // 创建一个默认的DockTab，包含HomePage
    DockManager.createDockTab(
      'main',
      'home',
      displayName: '首页',
      closable: true,
      maximizable: false,
      buttons: [],
    );

    // 添加默认的HomePage DockItem
    final homePageItem = DockManager.createHomePageDockItem(
      'Home',
      onCreateNewTab: () {
        createNewTab();
      },
    );
    DockManager.addDockItem('main', 'home', homePageItem);
  }

  /// 创建新tab
  void createNewTab() {
    // 这个方法将在UI层处理用户交互
    notifyListeners();
  }

  /// 使用指定名称创建Tab
  void createTabWithName(String name, {String type = 'empty'}) {
    final tabId = 'tab_${DateTime.now().millisecondsSinceEpoch}';

    // 创建新Tab
    DockManager.createDockTab(
      'main',
      tabId,
      displayName: name,
      closable: true,
      maximizable: false,
      buttons: [],
    );

    // 根据类型添加默认内容
    switch (type) {
      case 'empty':
      default:
        // 空白tab不添加任何内容
        break;
    }

    // 激活新创建的Tab
    DockManager.setActiveTab('main', tabId);
    notifyListeners();
  }

  /// 保存布局
  bool saveLayout() {
    try {
      final layoutString = DockManager.saveDockTabsLayout('main');
      if (layoutString != null) {
        _lastSavedLayout = layoutString;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving layout: $e');
      return false;
    }
  }

  /// 加载布局
  bool loadLayout() {
    if (_lastSavedLayout.isEmpty) {
      return false;
    }

    try {
      final success = DockManager.loadDockTabsLayout('main', _lastSavedLayout);
      if (success) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error loading layout: $e');
      return false;
    }
  }

  /// 获取统计信息
  Map<String, int> getStatistics() {
    return DockManager.getStatistics();
  }

  /// 处理DockItem关闭事件
  void handleItemClose(DockingItem item) {
    // 这里可以添加关闭后的清理逻辑
    notifyListeners();
  }

  @override
  void dispose() {
    DockManager.clearAll();
    super.dispose();
  }
}
