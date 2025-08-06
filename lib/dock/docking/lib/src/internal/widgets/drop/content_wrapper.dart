import 'drop_anchor_widget.dart';
import '../../../layout/docking_layout.dart';
import '../../../layout/drop_position.dart';
import '../../../on_item_position_changed.dart';
import 'package:flutter/material.dart';

abstract class ContentWrapperBase extends StatelessWidget {
  const ContentWrapperBase({
    super.key,
    required this.layout,
    required this.listener,
    required this.child,
  });

  final DockingLayout layout;
  final Widget child;
  final DropWidgetListener listener;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        List<Widget> children = [Positioned.fill(child: child)];

        // percentage of width reserved for detecting center area
        const double centerWidthRatio = 50;
        // reserved width to detect center area
        final double centerWidth =
            centerWidthRatio * constraints.maxWidth / 100;
        // reserved width to detect left and right areas
        final double horizontalEdgeWidth =
            (constraints.maxWidth - centerWidth) / 2;
        // height reserved for detecting the top and bottom areas
        final double verticalEdgeHeight = constraints.maxHeight / 2;

        children.add(
          Positioned(
            width: horizontalEdgeWidth,
            bottom: 0,
            top: 0,
            left: 0,
            child: buildDropAnchor(DropPosition.left),
          ),
        );

        children.add(
          Positioned(
            width: horizontalEdgeWidth,
            bottom: 0,
            top: 0,
            right: 0,
            child: buildDropAnchor(DropPosition.right),
          ),
        );

        children.add(
          Positioned(
            height: verticalEdgeHeight,
            top: 0,
            left: horizontalEdgeWidth,
            right: horizontalEdgeWidth,
            child: buildDropAnchor(DropPosition.top),
          ),
        );

        children.add(
          Positioned(
            height: verticalEdgeHeight,
            bottom: 0,
            left: horizontalEdgeWidth,
            right: horizontalEdgeWidth,
            child: buildDropAnchor(DropPosition.bottom),
          ),
        );

        return Stack(children: children);
      },
    );
  }

  DropAnchorBaseWidget buildDropAnchor(DropPosition dropPosition);
}

class ItemContentWrapper extends ContentWrapperBase {
  const ItemContentWrapper({
    super.key,
    required super.layout,
    required super.listener,
    required DockingItem dockingItem,
    this.onItemPositionChanged,
    required super.child,
  }) : _dockingItem = dockingItem;

  final DockingItem _dockingItem;
  final OnItemPositionChanged? onItemPositionChanged;

  @override
  DropAnchorBaseWidget buildDropAnchor(DropPosition dropPosition) {
    return ItemDropAnchorWidget(
      layout: layout,
      listener: listener,
      dropPosition: dropPosition,
      dockingItem: _dockingItem,
      onItemPositionChanged: onItemPositionChanged,
    );
  }
}

class TabsContentWrapper extends ContentWrapperBase {
  const TabsContentWrapper({
    super.key,
    required super.layout,
    required super.listener,
    required DockingTabs dockingTabs,
    this.onItemPositionChanged,
    required super.child,
  }) : _dockingTabs = dockingTabs;

  final DockingTabs _dockingTabs;
  final OnItemPositionChanged? onItemPositionChanged;

  @override
  DropAnchorBaseWidget buildDropAnchor(DropPosition dropPosition) {
    return TabsDropAnchorWidget(
      layout: layout,
      listener: listener,
      dropPosition: dropPosition,
      dockingTabs: _dockingTabs,
      onItemPositionChanged: onItemPositionChanged,
    );
  }
}
