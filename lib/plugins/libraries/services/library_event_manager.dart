import 'dart:async';

import 'package:mira/core/event/event_debounce.dart';
import 'package:mira/core/event/event_manager.dart';

// 导出相关类型供外部使用
export 'package:mira/core/event/event_manager.dart' show EventArgs;
export 'package:mira/core/event/event_args.dart' show MapEventArgs;

class LibraryEventManager {
  static LibraryEventManager? _instance;
  static LibraryEventManager get instance {
    _instance ??= LibraryEventManager._internal();
    return _instance!;
  }

  LibraryEventManager._internal();

  final List<StreamSubscription> _subscriptions = [];
  final Map<String, EventDebouncer> _typeDebouncers = {};
  late EventDebouncer _changedStream;
  bool _isInitialized = false;

  // 事件类型别名映射
  static const Map<String, List<String>> _eventTypeMap = {
    'library_update': ['file::changed', 'tab::doUpdate'],
    'tags_update': ['tags::updated'],
    'folder_update': ['folder::updated'],
  };

  /// 获取库更新事件流
  Stream<EventArgs> get libraryUpdateStream => _changedStream.stream;

  /// 初始化事件管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    _changedStream = EventDebouncer(duration: Duration(seconds: 1)); // 广播更新节流

    // 订阅各种事件
    final events = [
      'file::changed',
      'tags::updated',
      'folder::updated',
      'tab::doUpdate',
    ];
    for (final event in events) {
      EventManager.instance.subscribe(
        event,
        (args) => _changedStream.onCall(args),
      );
    }

    _isInitialized = true;
  }

  // 公告方法
  void broadcast(String eventName, EventArgs args) {
    EventManager.instance.broadcast(eventName, args);
  }

  /// 添加自定义事件监听器（原有方法，监听所有事件）
  StreamSubscription<EventArgs> addListener(
    void Function(EventArgs args) onEvent,
  ) {
    return _changedStream.stream.listen(onEvent);
  }

  /// 添加指定类型的事件监听器
  StreamSubscription<EventArgs> addListenerByType(
    String eventType,
    void Function(EventArgs args) onEvent,
  ) {
    // 获取事件类型对应的具体事件列表
    final events = _eventTypeMap[eventType];
    if (events == null) {
      throw ArgumentError(
        'Unknown event type: $eventType. Available types: ${_eventTypeMap.keys.join(', ')}',
      );
    }

    // 如果该类型的 debouncer 不存在，创建一个新的
    if (!_typeDebouncers.containsKey(eventType)) {
      final typeDebouncer = EventDebouncer(duration: Duration(seconds: 1));
      _typeDebouncers[eventType] = typeDebouncer;

      // 订阅对应的事件
      for (final event in events) {
        EventManager.instance.subscribe(
          event,
          (args) => typeDebouncer.onCall(args),
        );
      }
    }

    // 返回对这个类型事件流的监听
    return _typeDebouncers[eventType]!.stream.listen(onEvent);
  }

  /// 获取可用的事件类型
  static List<String> get availableEventTypes => _eventTypeMap.keys.toList();

  /// 获取指定事件类型包含的具体事件
  static List<String>? getEventsForType(String eventType) {
    return _eventTypeMap[eventType];
  }

  /// 释放资源
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // 清理类型 debouncers
    for (final debouncer in _typeDebouncers.values) {
      // EventDebouncer 可能需要清理方法，如果有的话
    }
    _typeDebouncers.clear();

    _isInitialized = false;
  }
}
