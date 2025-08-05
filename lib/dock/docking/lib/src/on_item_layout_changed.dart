import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import 'layout/docking_layout.dart';

/// Event that will be triggered after a [DockingItem] layout changed.
typedef OnItemLayoutChanged =
    void Function({
      required DockingItem oldItem,
      required DockingItem newItem,
      required DropArea targetArea,
      DropPosition? newIndex,
      int? dropIndex,
    });

/// Intercepts a [DockingItem] layout changed event to indicates whether it can be changed.
typedef ItemLayoutChangedInterceptor = bool Function(DockingItem item);
