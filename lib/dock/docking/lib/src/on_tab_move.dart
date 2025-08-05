import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';
import 'layout/docking_layout.dart';

typedef OnTabMove =
    void Function({
      required DockingItem draggedItem,
      required DropArea targetArea,
      DropPosition? dropPosition,
      int? dropIndex,
    });
typedef TabMoveInterceptor =
    bool Function({
      required DockingItem draggedItem,
      required DropArea targetArea,
      DropPosition? dropPosition,
      int? dropIndex,
    });
