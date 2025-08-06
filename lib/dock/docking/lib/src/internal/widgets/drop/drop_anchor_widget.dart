import '../../debug.dart';
import '../../../layout/docking_layout.dart';
import '../../../layout/drop_position.dart';
import '../../../on_item_position_changed.dart';
import 'package:flutter/material.dart';

import 'package:tabbed_view/tabbed_view.dart';

typedef DropWidgetListener = void Function(DropPosition? dropPosition);

abstract class DropAnchorBaseWidget extends StatelessWidget {
  const DropAnchorBaseWidget({
    super.key,
    required this.layout,
    required this.dropPosition,
    required this.listener,
  });

  final DockingLayout layout;
  final DropPosition dropPosition;
  final DropWidgetListener listener;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.translucent,
      onExit: (e) => listener(null),
      child: DragTarget<DraggableData>(
        builder: _buildDropWidget,
        onWillAcceptWithDetails: (DragTargetDetails<DraggableData> details) {
          final DraggableData draggableData = details.data;
          final TabData draggedTabData = draggableData.tabData;
          final DockingItem? draggedItem = draggedTabData.value;
          if (draggedItem != null) {
            bool willAccept = onWillAccept(draggedItem);
            if (willAccept) {
              listener(dropPosition);
            } else {
              listener(null);
            }
            return willAccept;
          } else {
            listener(null);
          }
          return false;
        },
        onAcceptWithDetails: (DragTargetDetails<DraggableData> details) {
          final DraggableData draggableData = details.data;
          final TabData tabData = draggableData.tabData;
          final DockingItem draggableItem = tabData.value;
          onAccept(draggableItem);
        },
      ),
    );
  }

  bool onWillAccept(DockingItem draggedItem);

  void onAccept(DockingItem draggedItem);

  Widget _buildDropWidget(
    BuildContext context,
    List<DraggableData?> candidateTabData,
    List<dynamic> rejectedData,
  ) {
    if (DockingDebug.dropAreaVisible) {
      Color color = Colors.deepOrange;
      if (dropPosition == DropPosition.top) {
        color = Colors.blue;
      } else if (dropPosition == DropPosition.bottom) {
        color = Colors.green;
      } else if (dropPosition == DropPosition.left) {
        color = Colors.purple;
      }
      return Placeholder(color: color);
    }
    return Container();
  }
}

class ItemDropAnchorWidget extends DropAnchorBaseWidget {
  const ItemDropAnchorWidget({
    super.key,
    required super.layout,
    required super.dropPosition,
    required super.listener,
    required DockingItem dockingItem,
    this.onItemPositionChanged,
  }) : _dockingItem = dockingItem;

  final DockingItem _dockingItem;
  final OnItemPositionChanged? onItemPositionChanged;

  @override
  void onAccept(DockingItem draggedItem) {
    layout.moveItem(
      draggedItem: draggedItem,
      targetArea: _dockingItem,
      dropPosition: dropPosition,
    );

    // 触发onItemPositionChanged回调
    if (onItemPositionChanged != null) {
      onItemPositionChanged!(
        draggedItem: draggedItem,
        targetArea: _dockingItem,
        dropPosition: dropPosition,
      );
    }
  }

  @override
  bool onWillAccept(DockingItem draggedItem) {
    return _dockingItem != draggedItem;
  }
}

class TabsDropAnchorWidget extends DropAnchorBaseWidget {
  const TabsDropAnchorWidget({
    super.key,
    required super.layout,
    required super.dropPosition,
    required super.listener,
    required DockingTabs dockingTabs,
    this.onItemPositionChanged,
  }) : _dockingTabs = dockingTabs;

  final DockingTabs _dockingTabs;
  final OnItemPositionChanged? onItemPositionChanged;

  @override
  void onAccept(DockingItem draggedItem) {
    layout.moveItem(
      draggedItem: draggedItem,
      targetArea: _dockingTabs,
      dropPosition: dropPosition,
    );

    // 触发onItemPositionChanged回调
    if (onItemPositionChanged != null) {
      onItemPositionChanged!(
        draggedItem: draggedItem,
        targetArea: _dockingTabs,
        dropPosition: dropPosition,
      );
    }
  }

  @override
  bool onWillAccept(DockingItem draggedItem) {
    return true;
  }
}
