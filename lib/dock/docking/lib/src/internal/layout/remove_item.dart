import 'layout_modifier.dart';
import '../../layout/docking_layout.dart';

/// Removes [DockingItem] from this layout.

class RemoveItem extends LayoutModifier {
  RemoveItem({required this.itemToRemove});

  final DockingItem itemToRemove;

  @override
  void validate(DockingLayout layout, DockingArea area) {
    super.validate(layout, area);
    if (area.layoutId != layout.id) {
      throw ArgumentError(
        'DockingArea belongs to another layout. Keep the layout in the state of your StatefulWidget.',
      );
    }
  }

  @override
  DockingArea? newLayout(DockingLayout layout) {
    validate(layout, itemToRemove);
    if (layout.root != null) {
      return _buildLayout(layout.root!);
    }
    return null;
  }

  /// Builds a new root.
  DockingArea? _buildLayout(DockingArea area) {
    if (area is DockingItem) {
      DockingItem dockingItem = area;
      if (dockingItem == itemToRemove) {
        return null;
      }
      return dockingItem;
    } else if (area is DockingTabs) {
      DockingTabs dockingTabs = area;
      List<DockingItem> children = [];
      dockingTabs.forEach((child) {
        if (child != itemToRemove) {
          children.add(child);
        }
      });
      if (children.length == 1) {
        return children.first;
      }
      if (children.isEmpty) {
        return null;
      }
      DockingTabs newDockingTabs = DockingTabs(
        children,
        id: dockingTabs.id,
        maximized: dockingTabs.maximized,
        maximizable: dockingTabs.maximizable,
      );
      newDockingTabs.selectedIndex = dockingTabs.selectedIndex;
      return newDockingTabs;
    } else if (area is DockingParentArea) {
      List<DockingArea> children = [];
      area.forEach((child) {
        DockingArea? newChild = _buildLayout(child);
        if (newChild != null) {
          children.add(newChild);
        }
      });
      if (children.isEmpty) {
        return null;
      } else if (children.length == 1) {
        return children.first;
      }
      if (area is DockingRow) {
        return DockingRow(children, id: area.id);
      } else if (area is DockingColumn) {
        return DockingColumn(children, id: area.id);
      }
      throw ArgumentError(
        'DockingArea class not recognized: ${area.runtimeType}',
      );
    }
    throw ArgumentError(
      'DockingArea class not recognized: ${area.runtimeType}',
    );
  }
}
