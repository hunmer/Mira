import 'dart:async';

/// Dock事件类型枚举
enum DockEventType {
  update,
  tabClosed,
  tabCreated,
  tabSelected,
  layoutChanged,
  allTabsCleared,
  tabPositionChanged,
  // 布局控制器事件
  layoutLoading,
  layoutLoaded,
  layoutSaved,
  layoutReset,
  presetSaved,
  presetLoaded,
  presetDeleted,
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
  final Map<String, dynamic> values;

  DockTabEvent({
    required super.type,
    required super.dockTabsId,
    required this.values,
  });

  // 便捷访问器
  String? get tabId => values['tabId'] as String?;
  String? get displayName => values['displayName'] as String?;
  String? get itemTitle => values['itemTitle'] as String?;
  String? get itemType => values['itemType'] as String?;
  Map<String, dynamic>? get data => values['data'] as Map<String, dynamic>?;
}

/// 布局变更事件
class DockLayoutEvent extends DockEvent {
  final String? tabId;
  final String? layoutData;

  DockLayoutEvent({required super.dockTabsId, this.tabId, this.layoutData})
    : super(type: DockEventType.layoutChanged);
}

/// 布局控制器事件
class DockLayoutControllerEvent extends DockEvent {
  final Map<String, dynamic> data;

  DockLayoutControllerEvent({
    required super.type,
    required super.dockTabsId,
    this.data = const {},
  });

  // 便捷访问器
  bool? get isLoading => data['isLoading'] as bool?;
  String? get layoutData => data['layoutData'] as String?;
  String? get presetId => data['presetId'] as String?;
  String? get presetName => data['presetName'] as String?;
  bool? get success => data['success'] as bool?;
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
