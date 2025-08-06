import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mira/dock/dock_item.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/core/storage/storage_manager.dart';
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
  late DockLayoutController layoutController;
  bool _isInitialized = false;

  DockController({this.dockTabsId = 'main'}) {
    layoutController = DockLayoutController(dockTabsId: dockTabsId);
    layoutController.addListener(_onLayoutControllerChanged);
  }

  DockTabs? get dockTabs => _dockTabs;
  bool get isInitialized => _isInitialized;
  Stream<DockEvent> get eventStream => _eventStreamController.stream;

  /// 布局控制器状态变化时的回调
  void _onLayoutControllerChanged() {
    print('LayoutController state changed');
    notifyListeners();
  }

  /// 初始化存储管理器
  Future<void> initializeStorage(StorageManager storageManager) async {
    await layoutController.initializeStorage(storageManager);
  }

  /// 初始化Dock系统
  Future<void> initializeDockSystem() async {
    if (_isInitialized) return;
    // 创建事件流控制器
    _eventStreamController = DockEventStreamController(id: dockTabsId);
    // 监听事件并处理
    _eventSubscription = _eventStreamController.stream.listen(_handleDockEvent);
    // 等待DockManager完成初始化后再尝试加载布局
    await _initializeWithLayout();
    // 初始化布局信息
    await _initializeLayoutInfo();
    _isInitialized = true;
  }

  /// 初始化布局信息
  Future<void> _initializeLayoutInfo() async {
    // 通过DockLayoutController初始化布局信息
    // 这将确保布局控制器有正确的初始状态
    if (layoutController.isStorageInitialized) {
      // 尝试加载已保存的完整布局（包括DockingData和Layout字符串）
      await layoutController.loadCompleteLayout();
    }
  }

  /// 异步初始化布局
  Future<void> _initializeWithLayout() async {
    print('Initializing DockController for $dockTabsId');
    // 使用布局控制器初始化布局数据
    final initData = await layoutController.initializeLayoutData(
      savedLayoutId: dockTabsId,
    );

    // 创建主要的DockTabs
    _dockTabs = DockManager.createDockTabs(
      dockTabsId,
      initData: initData,
      eventStreamController: _eventStreamController,
    );
  }

  /// 处理Dock事件
  void _handleDockEvent(DockEvent event) {
    print('Dock Event: ${event.type} for dockTabsId: ${event.dockTabsId}');

    if (event is DockTabEvent) {
      final item = event.values['item'] as DockingItem?;
      final tab = event.values['tabs'] as DockTabs?;
      switch (event.type) {
        case DockEventType.tabClosed:
        case DockEventType.tabCreated:
          if (tab!.isEmpty) {
            print('is Empty');
          }
          _onLayoutControllerChanged();
          break;
        default:
          break;
      }
    } else {
      switch (event.type) {
        case DockEventType.update:
          _onLayoutControllerChanged();
          break;
        case DockEventType.layoutChanged:
          break;
        case DockEventType.tabPositionChanged:
          break;
        default:
          break;
      }
    }
    // 延迟保存布局
    Future.delayed(const Duration(milliseconds: 1000), () {
      saveLayout();
    });
  }

  /// 保存布局
  Future<bool> saveLayout() async {
    final layoutData = await DockLayoutController.getLayoutData(dockTabsId);
    if (layoutData != null) {
      return await layoutController.saveLayout(layoutData);
    }
    return false;
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    _eventStreamController.dispose();
    layoutController.removeListener(_onLayoutControllerChanged);
    layoutController.dispose();
    super.dispose();
  }
}
