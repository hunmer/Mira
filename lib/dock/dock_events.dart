import 'dart:async';

/// Dock事件类型枚举
enum DockEventType {
  tabClosed,
  tabCreated,
  tabSwitched,
  itemClosed,
  itemCreated,
  layoutChanged,
}

/// 基础Dock事件类
abstract class DockEvent {
  final DockEventType type;
  final String dockTabsId;
  final DateTime timestamp;

  DockEvent({required this.type, required this.dockTabsId})
    : timestamp = DateTime.now();
}

/// Tab相关事件
class DockTabEvent extends DockEvent {
  final String tabId;
  final String? displayName;
  final Map<String, dynamic>? data;

  DockTabEvent({
    required super.type,
    required super.dockTabsId,
    required this.tabId,
    this.displayName,
    this.data,
  });
}

/// Item相关事件
class DockItemEvent extends DockEvent {
  final String tabId;
  final String itemTitle;
  final String? itemType;
  final Map<String, dynamic>? data;

  DockItemEvent({
    required super.type,
    required super.dockTabsId,
    required this.tabId,
    required this.itemTitle,
    this.itemType,
    this.data,
  });
}

/// 布局变更事件
class DockLayoutEvent extends DockEvent {
  final String? tabId;
  final String layoutData;

  DockLayoutEvent({
    required super.dockTabsId,
    this.tabId,
    required this.layoutData,
  }) : super(type: DockEventType.layoutChanged);
}

/// Dock事件流管理器
class DockEventStreamController {
  final StreamController<DockEvent> _streamController;
  final String id;

  DockEventStreamController({required this.id})
    : _streamController = StreamController<DockEvent>.broadcast();

  Stream<DockEvent> get stream => _streamController.stream;

  void emit(DockEvent event) {
    if (!_streamController.isClosed) {
      _streamController.add(event);
    }
  }

  void dispose() {
    _streamController.close();
  }

  bool get isClosed => _streamController.isClosed;
}
