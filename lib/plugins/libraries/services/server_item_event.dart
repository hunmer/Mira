import 'package:mira/core/event/event.dart';

/// 自定义事件参数
class ItemEventArgs extends EventArgs {
  final Map<String, dynamic> item;

  ItemEventArgs(this.item, [String eventName = '']) : super(eventName);
}
