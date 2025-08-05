import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'dock_manager.dart';
import 'dock_tabs.dart';
import 'dock_events.dart';
import 'dock_layout_controller.dart';

/// DockController - 控制器类，管理Dock系统的业务逻辑
class DockController extends ChangeNotifier {
  final String dockTabsId;
  DockTabs? _dockTabs;
  late DockEventStreamController _eventStreamController;
  late StreamSubscription<DockEvent> _eventSubscription;
  late DockLayoutController _layoutController;
  bool _isInitialized = false;

  DockController({this.dockTabsId = 'main'}) {
    _layoutController = DockLayoutController(dockTabsId: dockTabsId);
    _layoutController.addListener(_onLayoutControllerChanged);
  }

  DockTabs? get dockTabs => _dockTabs;
  bool get isInitialized => _isInitialized;
  DockLayoutController get layoutController => _layoutController;

  // 布局相关的便捷访问器
  String get lastSavedLayout => _layoutController.lastSavedLayout;
  bool get hasValidSavedLayout => _layoutController.hasValidSavedLayout;
  bool get isLayoutLoading => _layoutController.isLayoutLoading;

  Stream<DockEvent> get eventStream => _eventStreamController.stream;

  /// 布局控制器状态变化时的回调
  void _onLayoutControllerChanged() {
    notifyListeners();
  }

  /// 初始化Dock系统
  Future<void> initializeDockSystem({String? savedLayoutId}) async {
    if (_isInitialized) return;

    // 创建事件流控制器
    _eventStreamController = DockEventStreamController(id: dockTabsId);

    // 监听事件并处理
    _eventSubscription = _eventStreamController.stream.listen(_handleDockEvent);

    // 等待DockManager完成初始化后再尝试加载布局
    await _initializeWithLayout(savedLayoutId);
    _isInitialized = true;
  }

  /// 异步初始化布局
  Future<void> _initializeWithLayout(String? savedLayoutId) async {
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

    // 使用布局控制器初始化布局数据
    final initData = await _layoutController.initializeLayoutData(
      savedLayoutId: savedLayoutId,
    );

    // 创建主要的DockTabs，使用延迟初始化模式
    _dockTabs = DockManager.createDockTabs(
      dockTabsId,
      initData: initData,
      eventStreamController: _eventStreamController,
      deferInitialization: true, // 启用延迟初始化
    );

    // 应用待处理的布局
    _layoutController.applyPendingLayout(_dockTabs);

    // 完成延迟初始化，统一重建布局
    DockManager.finishDeferredInitialization(dockTabsId);

    // 通知UI更新
    notifyListeners();
  }

  /// 处理Dock事件
  void _handleDockEvent(DockEvent event) {
    print('Dock Event: ${event.type} for dockTabsId: ${event.dockTabsId}');

    bool shouldNotifyListeners = false;
    switch (event.type) {
      case DockEventType.tabClosed:
      case DockEventType.tabCreated:
      case DockEventType.itemClosed:
      case DockEventType.itemCreated:
      case DockEventType.layoutChanged:
        break;
      case DockEventType.itemSelected:
        break;
      case DockEventType.itemPositionChanged:
        break;
    }
    _saveLayoutForEvent(event.dockTabsId);
    if (event is DockTabEvent && event.values.containsKey('rebuild')) {
      notifyListeners();
    }
  }

  /// 根据事件的dockTabsId保存布局
  void _saveLayoutForEvent(String eventDockTabsId) {
    if (eventDockTabsId == dockTabsId) {
      // 委托给布局控制器处理
      _layoutController.handleLayoutChanged(eventDockTabsId);
    }
  }

  /// 创建新tab
  void createNewTab() {
    // 这个方法将在UI层处理用户交互
    notifyListeners();
  }

  /// 保存布局
  bool saveLayout({bool useDebounce = false}) {
    return _layoutController.saveLayout(useDebounce: useDebounce);
  }

  /// 强制执行待处理的防抖保存操作
  void flushPendingSave() {
    _layoutController.flushPendingSave();
  }

  /// 加载布局
  bool loadLayout() {
    return _layoutController.loadLayout();
  }

  /// 处理DockItem关闭事件
  void handleItemClose(DockingItem item) {
    // 这里可以添加关闭后的清理逻辑
    notifyListeners();
  }

  @override
  void dispose() {
    // 在销毁前强制刷新任何待处理的布局保存操作
    _layoutController.flushPendingSave();

    _eventSubscription.cancel();
    _eventStreamController.dispose();
    _layoutController.removeListener(_onLayoutControllerChanged);
    _layoutController.dispose();
    super.dispose();
  }
}
