import 'drop_item.dart';
import '../../layout/docking_layout.dart';

/// Rearranges the layout given a new location for a [DockingItem].

class MoveItem extends DropItem {
  MoveItem({
    required DockingItem draggedItem,
    required super.targetArea,
    required super.dropPosition,
    required super.dropIndex,
  }) : super(dropItem: draggedItem);

  @override
  void validate(DockingLayout layout, DockingArea area) {
    super.validate(layout, area);
    if (area.layoutId != layout.id) {}
  }
}
