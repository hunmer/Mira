import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';

import 'layout/docking_layout.dart';

/// Event that will be triggered after a [DockingItem] layout changed.
typedef OnTabLayoutChanged =
    void Function({
      required DockingItem oldItem,
      required DockingItem newItem,
      required DropArea targetArea,
      DropPosition? newIndex,
      int? dropIndex,
    });

/// Intercepts a [DockingItem] layout changed event to indicates whether it can be changed.
typedef TabLayoutChangedInterceptor = bool Function(DockingItem item);
