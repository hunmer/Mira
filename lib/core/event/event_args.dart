/// 事件参数基类
class EventArgs {
  /// 事件名称
  String eventName;

  /// 事件发生时间
  final DateTime whenOccurred;

  /// 创建一个事件参数实例
  EventArgs([this.eventName = '']) : whenOccurred = DateTime.now();
}

/// 事件订阅句柄，用于标识和管理订阅
class EventSubscription {
  final String _id;
  final String eventName;
  final Function(EventArgs) handler;
  bool _isActive = true;

  EventSubscription(this._id, this.eventName, this.handler);

  String get id => _id;
  bool get isActive => _isActive;

  void cancel() {
    _isActive = false;
  }
}

/// 用于传递单个值的事件参数
class Value<T> extends EventArgs {
  final T value;

  Value(this.value, [String eventName = '']) : super(eventName);
}

/// 用于传递两个值的事件参数
class Values<T1, T2> extends EventArgs {
  final T1 value1;
  final T2 value2;

  Values(this.value1, this.value2, [String eventName = '']) : super(eventName);
}

/// 自定义事件参数示例 - 可以根据需要创建更多自定义事件参数类
class UpdateEvent extends EventArgs {
  final String version;
  final bool forceUpdate;
  final String? changelog;

  UpdateEvent({
    required this.version,
    this.forceUpdate = false,
    this.changelog,
    String eventName = '',
  }) : super(eventName);
}

class ListArgEvent extends EventArgs {
  final List<dynamic> item;
  ListArgEvent(this.item, [String eventName = '']) : super(eventName);
}

class MapEventArgs extends EventArgs {
  final Map<String, dynamic> item;
  MapEventArgs(this.item, [String eventName = '']) : super(eventName);
}
