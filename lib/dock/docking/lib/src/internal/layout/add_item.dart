import 'drop_item.dart';
import '../../layout/docking_layout.dart';

/// Adds [DockingItem] to the layout.

class AddItem extends DropItem {
  AddItem({
    required DockingItem newItem,
    required super.targetArea,
    super.dropPosition,
    super.dropIndex,
  }) : super(dropItem: newItem);

  @override
  void validateDropItem(DockingLayout layout, DockingArea area) {
    super.validateDropItem(layout, area);
    if (area.layoutId != -1) {
      throw ArgumentError('DockingArea already belongs to some layout.');
    }
  }

  @override
  void validateTargetArea(DockingLayout layout, DockingArea area) {
    super.validateTargetArea(layout, area);
    if (area.layoutId != layout.id) {
      throw ArgumentError(
        'DockingArea belongs to another layout. Keep the layout in the state of your StatefulWidget.',
      );
    }
  }
}
