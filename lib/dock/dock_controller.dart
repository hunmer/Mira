import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/homepage_dock_item.dart';
import 'dock_manager.dart';
import 'dock_tabs.dart';
import 'dock_events.dart';

/// DockController - 控制器类，管理Dock系统的业务逻辑
class DockController extends ChangeNotifier {
  final String dockTabsId;
  late DockTabs _dockTabs;
  String _lastSavedLayout = '';
  late DockEventStreamController _eventStreamController;
  late StreamSubscription<DockEvent> _eventSubscription;

  DockController({this.dockTabsId = 'main'});

  DockTabs get dockTabs => _dockTabs;
  String get lastSavedLayout => _lastSavedLayout;
  bool get hasValidSavedLayout => _lastSavedLayout.isNotEmpty;
  Stream<DockEvent> get eventStream => _eventStreamController.stream;

  /// 初始化Dock系统
  void initializeDockSystem({String? savedLayoutId}) {
    // 创建事件流控制器
    _eventStreamController = DockEventStreamController(id: dockTabsId);

    // 监听事件并处理
    _eventSubscription = _eventStreamController.stream.listen(_handleDockEvent);

    // 等待DockManager完成初始化后再尝试加载布局
    _initializeWithLayout(savedLayoutId);
  }

  /// 异步初始化布局
  void _initializeWithLayout(String? savedLayoutId) async {
    print('Initializing DockController for $dockTabsId');

    // 等待DockManager完成初始化
    int attempts = 0;
    const maxAttempts = 50; // 最多等待5秒
    while (!DockManager.isInitialized && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!DockManager.isInitialized) {
      print('Warning: DockManager initialization timeout');
    }

    Map<String, dynamic>? initData;
    if (savedLayoutId != null) {
      final savedLayout = DockManager.getStoredLayout(savedLayoutId);
      if (savedLayout != null) {
        print(
          'Found saved layout for $savedLayoutId, length: ${savedLayout.length}',
        );
        initData = {'layout': savedLayout};
      } else {
        print('No saved layout found for $savedLayoutId');
      }
    }

    // 创建主要的DockTabs，添加onItemClose回调和事件流
    _dockTabs = DockManager.createDockTabs(
      dockTabsId,
      initData: initData,
      eventStreamController: _eventStreamController,
      onItemClose: (DockingItem item) {
        // 这个回调将在UI层处理
        _eventStreamController.emit(
          DockItemEvent(
            type: DockEventType.itemClosed,
            dockTabsId: dockTabsId,
            tabId: _dockTabs.activeTabId ?? 'home',
            itemTitle: item.name ?? 'unknown',
          ),
        );
        notifyListeners();
      },
    );

    if (_dockTabs.isEmpty) {
      // 创建默认tab和内容
      _createDefaultTabs();
    }
    loadLayout();

    // 通知UI更新
    notifyListeners();
  }

  /// 创建默认的tabs和内容
  void _createDefaultTabs() {
    // 创建一个默认的DockTab，包含HomePage
    DockManager.createDockTab(
      dockTabsId,
      'home',
      displayName: '首页',
      closable: true,
      maximizable: false,
      buttons: [],
    );
  }

  /// 处理Dock事件
  void _handleDockEvent(DockEvent event) {
    print('Dock Event: ${event.type} for dockTabsId: ${event.dockTabsId}');
    switch (event.type) {
      case DockEventType.tabClosed:
      case DockEventType.tabCreated:
      case DockEventType.tabSwitched:
      case DockEventType.itemClosed:
      case DockEventType.itemCreated:
      case DockEventType.layoutChanged:
        // 任何事件都触发布局保存，传递对应的dockTabsId
        _saveLayoutForEvent(event.dockTabsId);
        break;
    }
    notifyListeners();
  }

  /// 根据事件的dockTabsId保存布局
  void _saveLayoutForEvent(String eventDockTabsId) {
    final success = DockManager.saveLayoutForDockTabs(eventDockTabsId);
    if (success && eventDockTabsId == dockTabsId) {
      // 如果是当前控制器的布局，也更新本地的_lastSavedLayout
      _lastSavedLayout =
          DockManager.getStoredLayout('${eventDockTabsId}_layout') ?? '';
    }
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
      dockTabsId,
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
    DockManager.setActiveTab(dockTabsId, tabId);

    // 发送tab创建和切换事件
    _eventStreamController.emit(
      DockTabEvent(
        type: DockEventType.tabCreated,
        dockTabsId: dockTabsId,
        tabId: tabId,
        displayName: name,
      ),
    );

    _eventStreamController.emit(
      DockTabEvent(
        type: DockEventType.tabSwitched,
        dockTabsId: dockTabsId,
        tabId: tabId,
        displayName: name,
      ),
    );

    notifyListeners();
  }

  /// 保存布局
  bool saveLayout() {
    final success = DockManager.saveLayoutForDockTabs(dockTabsId);
    if (success) {
      _lastSavedLayout =
          DockManager.getStoredLayout('${dockTabsId}_layout') ?? '';
      notifyListeners();
    }
    return success;
  }

  /// 加载布局
  bool loadLayout() {
    final success = DockManager.loadLayoutForDockTabs(dockTabsId);
    if (success) {
      _lastSavedLayout =
          DockManager.getStoredLayout('${dockTabsId}_layout') ?? '';
      notifyListeners();
    }
    return success;
  }

  /// 处理DockItem关闭事件
  void handleItemClose(DockingItem item) {
    // 这里可以添加关闭后的清理逻辑
    notifyListeners();
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    _eventStreamController.dispose();
    super.dispose();
  }
}
