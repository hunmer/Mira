import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import 'layout/docking_layout.dart';

typedef OnItemMove =
    void Function({
      required DockingItem draggedItem,
      required DropArea targetArea,
      DropPosition? dropPosition,
      int? dropIndex,
    });
typedef ItemMoveInterceptor =
    bool Function({
      required DockingItem draggedItem,
      required DropArea targetArea,
      DropPosition? dropPosition,
      int? dropIndex,
    });
