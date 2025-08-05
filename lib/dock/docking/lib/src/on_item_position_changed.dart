import 'layout/docking_layout.dart';
import 'layout/drop_position.dart';

/// Event that will be triggered when a [DockingItem] position changed via content area drag.
typedef OnItemPositionChanged =
    void Function({
      required DockingItem draggedItem,
      required DropArea targetArea,
      required DropPosition dropPosition,
    });

/// Intercepts a [DockingItem] position changed event to indicates whether it can be changed.
typedef ItemPositionChangedInterceptor = bool Function(DockingItem item);
