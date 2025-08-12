import 'dart:async';

import 'package:mira/core/event/event_args.dart';
import 'package:mira/core/event/event_debounce.dart';
import 'package:mira/core/event/event_manager.dart';

// 导出相关类型供外部使用
export 'package:mira/core/event/event_manager.dart';
export 'package:mira/core/event/event_args.dart' show MapEventArgs;

/// 回调信息类
class _CallbackInfo {
  final int id;
  final void Function(EventArgs) callback;
  bool isPaused;

  _CallbackInfo({
    required this.id,
    required this.callback,
    // ignore: unused_element_parameter
    this.isPaused = false,
  });
}

/// 自定义的 StreamSubscription 实现，用于管理回调的移除
class _CallbackSubscription implements StreamSubscription<EventArgs> {
  final String eventType;
  final int callbackId;
  final LibraryEventManager manager;
  bool _isCancelled = false;

  _CallbackSubscription({
    required this.eventType,
    required this.callbackId,
    required this.manager,
  });

  @override
  Future<void> cancel() async {
    if (!_isCancelled) {
      _isCancelled = true;
      manager._removeCallback(eventType, callbackId);
    }
  }

  @override
  void onData(void Function(EventArgs data)? handleData) {
    // 这个方法在我们的实现中不需要
  }

  @override
  void onDone(void Function()? handleDone) {
    // 这个方法在我们的实现中不需要
  }

  @override
  void onError(Function? handleError) {
    // 这个方法在我们的实现中不需要
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    manager._pauseCallback(eventType, callbackId);
    if (resumeSignal != null) {
      resumeSignal.then((_) => resume());
    }
  }

  @override
  void resume() {
    manager._resumeCallback(eventType, callbackId);
  }

  @override
  bool get isPaused {
    final callbacks = manager._typeCallbacks[eventType];
    if (callbacks != null) {
      for (final info in callbacks) {
        if (info.id == callbackId) {
          return info.isPaused;
        }
      }
    }
    return false;
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    throw UnimplementedError('asFuture is not supported');
  }
}

class LibraryEventManager {
  static LibraryEventManager? _instance;
  static LibraryEventManager get instance {
    _instance ??= LibraryEventManager._internal();
    return _instance!;
  }

  LibraryEventManager._internal();

  final List<StreamSubscription> _subscriptions = [];
  final Map<String, EventDebouncer> _typeDebouncers = {};
  final Map<String, List<_CallbackInfo>> _typeCallbacks = {};
  final Map<String, StreamSubscription> _typeSubscriptions = {};
  late EventDebouncer _changedStream;
  bool _isInitialized = false;
  int _nextCallbackId = 0;

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

    // 如果该类型的回调列表不存在，创建一个新的
    if (!_typeCallbacks.containsKey(eventType)) {
      _typeCallbacks[eventType] = [];

      // 创建 debouncer 和单一的 stream 监听器
      final typeDebouncer = EventDebouncer(duration: Duration(seconds: 1));
      _typeDebouncers[eventType] = typeDebouncer;

      // 创建单一的 stream 监听器，调用所有回调
      _typeSubscriptions[eventType] = typeDebouncer.stream.listen((args) {
        final callbacks = _typeCallbacks[eventType];
        if (callbacks != null) {
          for (final callbackInfo in List.from(callbacks)) {
            if (!callbackInfo.isPaused) {
              try {
                callbackInfo.callback(args);
              } catch (e) {
                print('Error in event callback for $eventType: $e');
              }
            }
          }
        }
      });

      // 订阅对应的事件
      for (final event in events) {
        EventManager.instance.subscribe(
          event,
          (args) => typeDebouncer.onCall(args),
        );
      }
    }

    // 创建回调信息并添加到列表中
    final callbackId = _nextCallbackId++;
    final callbackInfo = _CallbackInfo(id: callbackId, callback: onEvent);
    _typeCallbacks[eventType]!.add(callbackInfo);

    // 返回一个自定义的 StreamSubscription，用于移除回调
    return _CallbackSubscription(
      eventType: eventType,
      callbackId: callbackId,
      manager: this,
    );
  }

  /// 移除指定类型的回调
  void _removeCallback(String eventType, int callbackId) {
    final callbacks = _typeCallbacks[eventType];
    if (callbacks != null) {
      callbacks.removeWhere((info) => info.id == callbackId);

      // 如果没有更多回调，清理资源
      if (callbacks.isEmpty) {
        _typeSubscriptions[eventType]?.cancel();
        _typeSubscriptions.remove(eventType);
        _typeDebouncers.remove(eventType);
        _typeCallbacks.remove(eventType);
      }
    }
  }

  /// 暂停指定的回调
  void _pauseCallback(String eventType, int callbackId) {
    final callbacks = _typeCallbacks[eventType];
    if (callbacks != null) {
      for (final info in callbacks) {
        if (info.id == callbackId) {
          info.isPaused = true;
          break;
        }
      }
    }
  }

  /// 恢复指定的回调
  void _resumeCallback(String eventType, int callbackId) {
    final callbacks = _typeCallbacks[eventType];
    if (callbacks != null) {
      for (final info in callbacks) {
        if (info.id == callbackId) {
          info.isPaused = false;
          break;
        }
      }
    }
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

    // 清理类型订阅
    for (final subscription in _typeSubscriptions.values) {
      subscription.cancel();
    }
    _typeSubscriptions.clear();

    // 清理回调列表
    _typeCallbacks.clear();

    // 清理类型 debouncers
    _typeDebouncers.clear();

    _isInitialized = false;
  }
}
