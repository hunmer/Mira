import '../../layout/docking_layout.dart';
import 'layout_modifier.dart';

/// Removes [DockingItem] by id from this layout.

class RemoveItemById extends LayoutModifier {
  RemoveItemById({required this.id});

  final dynamic id;

  @override
  DockingArea? newLayout(DockingLayout layout) {
    if (layout.root != null) {
      return _buildLayout(layout.root!);
    }
    return null;
  }

  /// Builds a new root.
  DockingArea? _buildLayout(DockingArea area) {
    if (area is DockingItem) {
      DockingItem dockingItem = area;
      if (dockingItem.id == id) {
        return null;
      }
      return dockingItem;
    } else if (area is DockingTabs) {
      DockingTabs dockingTabs = area;
      List<DockingItem> children = [];
      dockingTabs.forEach((child) {
        if (child.id != id) {
          children.add(child);
        }
      });
      if (children.length == 1) {
        return children.first;
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
