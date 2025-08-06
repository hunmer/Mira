import '../../drag_over_position.dart';
import '../../layout/docking_layout.dart';
import 'package:flutter/material.dart';

import 'package:tabbed_view/tabbed_view.dart';

/// Represents a draggable widget mixin.

mixin DraggableConfigMixin {
  // 静态变量跟踪当前拖动的item和其源layout
  static DockingItem? _currentDraggedItem;
  static DockingLayout? _currentDraggedItemLayout;
  static bool _crossLayoutDropCompleted = false;

  DraggableConfig buildDraggableConfig({
    required DragOverPosition dockingDrag,
    required TabData tabData,
    DockingLayout? sourceLayout,
  }) {
    DockingItem item = tabData.value;
    String name = item.name != null ? item.name! : '';

    return DraggableConfig(
      feedback: buildFeedback(name),
      dragAnchorStrategy:
          (
            Draggable<Object> draggable,
            BuildContext context,
            Offset position,
          ) => Offset(20, 20),
      onDragStarted: () {
        dockingDrag.enable = true;
        _currentDraggedItem = item;
        _currentDraggedItemLayout = sourceLayout;
        _crossLayoutDropCompleted = false;
      },
      onDragCompleted: () {
        dockingDrag.enable = false;
        // 如果是跨layout拖动且已完成放置，从源layout移除item
        if (_crossLayoutDropCompleted &&
            _currentDraggedItem != null &&
            _currentDraggedItemLayout != null) {
          try {
            _currentDraggedItemLayout!.removeItem(item: _currentDraggedItem!);
          } catch (e) {
            print('Failed to remove item from source layout: $e');
          }
        }
        // 清理静态变量
        _currentDraggedItem = null;
        _currentDraggedItemLayout = null;
        _crossLayoutDropCompleted = false;
      },
    );
  }

  // 标记跨layout拖动已完成
  static void markCrossLayoutDropCompleted() {
    _crossLayoutDropCompleted = true;
  }

  Widget buildFeedback(String name) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(),
          color: Colors.grey[300],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 0,
            minWidth: 30,
            maxHeight: double.infinity,
            maxWidth: 150.0,
          ),
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Text(name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
