import 'drop_item.dart';
import '../../layout/docking_layout.dart';
import '../../layout/drop_position.dart';

/// Rearranges the layout given a new location for a [DockingItem].

class MoveItem extends DropItem {
  MoveItem({
    required DockingItem draggedItem,
    required DropArea targetArea,
    required DropPosition? dropPosition,
    required int? dropIndex,
  }) : super(
         dropItem: draggedItem,
         targetArea: targetArea,
         dropPosition: dropPosition,
         dropIndex: dropIndex,
       );

  @override
  void validate(DockingLayout layout, DockingArea area) {
    super.validate(layout, area);
    if (area.layoutId != layout.id) {
      throw ArgumentError(
        'DockingArea belongs to another layout. Keep the layout in the state of your StatefulWidget.',
      );
    }
  }
}
