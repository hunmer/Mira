import 'package:mira/tabbed/tabbed_view/lib/src/tab_data.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabbed_view_controller.dart';

class DraggableData {
  DraggableData(this.controller, this.tabData);

  final TabbedViewController controller;
  final TabData tabData;
}
