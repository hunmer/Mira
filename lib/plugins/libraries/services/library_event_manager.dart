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
  late EventDebouncer _changedStream;
  bool _isInitialized = false;

  /// 获取库更新事件流
  Stream<EventArgs> get libraryUpdateStream => _changedStream.stream;

  /// 初始化事件管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    _changedStream = EventDebouncer(duration: Duration(seconds: 1)); // 广播更新节流

    // 订阅各种事件
    final events = ['file::changed', 'tags::updated', 'folder::updated'];
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

  /// 添加自定义事件监听器
  StreamSubscription<EventArgs> addListener(
    void Function(EventArgs args) onEvent,
  ) {
    return _changedStream.stream.listen(onEvent);
  }

  /// 释放资源
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _isInitialized = false;
  }
}
