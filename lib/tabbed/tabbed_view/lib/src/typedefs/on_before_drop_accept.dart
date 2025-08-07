import 'package:mira/tabbed/tabbed_view/lib/src/draggable_data.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabbed_view_controller.dart';

typedef OnBeforeDropAccept =
    bool Function(
      DraggableData source,
      TabbedViewController target,
      int newIndex,
    );
