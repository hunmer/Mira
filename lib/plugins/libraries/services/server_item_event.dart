import 'package:mira/core/event/event.dart';

/// 自定义事件参数
class serverEventArgs extends EventArgs {
  final Map<String, dynamic> item;

  serverEventArgs(this.item, [String eventName = '']) : super(eventName);

  // tojson
  Map<String, dynamic> toJson() => item;
}
