import 'package:mira/tabbed/tabbed_view/lib/src/draggable_config.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tab_data.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabbed_view_controller.dart';

/// Defines the configuration of a [Draggable] in its construction.
typedef OnDraggableBuild =
    DraggableConfig Function(
      TabbedViewController controller,
      int tabIndex,
      TabData tab,
    );
