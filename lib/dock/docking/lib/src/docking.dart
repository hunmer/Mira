import 'package:mira/dock/docking/lib/src/on_tab_layout_changed.dart';
import 'package:mira/dock/docking/lib/src/on_tab_move.dart';
import 'package:mira/dock/docking/lib/src/on_item_position_changed.dart';

import 'docking_buttons_builder.dart';
import 'drag_over_position.dart';
import 'internal/widgets/docking_item_widget.dart';
import 'internal/widgets/docking_tabs_widget.dart';
import 'layout/docking_layout.dart';
import 'on_item_close.dart';
import 'on_item_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mira/multi_split_view/lib/multi_split_view.dart';
import 'package:responsive_builder/responsive_builder.dart';

/// The docking widget.
class Docking extends StatefulWidget {
  const Docking({
    super.key,
    this.layout,
    this.onItemSelection,
    this.onItemClose,
    this.onTabMove,
    this.onTabLayoutChanged,
    this.onItemPositionChanged,
    this.itemCloseInterceptor,
    this.dockingButtonsBuilder,
    this.maximizableItem = true,
    this.maximizableTab = true,
    this.maximizableTabsArea = true,
    this.antiAliasingWorkaround = true,
    this.draggable = true,
    this.breakpoints,
  });

  final DockingLayout? layout;
  final OnItemSelection? onItemSelection;
  final OnItemClose? onItemClose;
  final OnTabMove? onTabMove;
  final OnTabLayoutChanged? onTabLayoutChanged;
  final OnItemPositionChanged? onItemPositionChanged;

  final ItemCloseInterceptor? itemCloseInterceptor;
  final DockingButtonsBuilder? dockingButtonsBuilder;
  final bool maximizableItem;
  final bool maximizableTab;
  final bool maximizableTabsArea;
  final bool antiAliasingWorkaround;
  final bool draggable;

  /// Optional responsive breakpoints. When set, DockingItems declare
  /// where they should be visible via DockingItem.showAtDevices.
  final ScreenBreakpoints? breakpoints;

  @override
  State<StatefulWidget> createState() => _DockingState();
}

/// The [Docking] state.
class _DockingState extends State<Docking> {
  final DragOverPosition _dragOverPosition = DragOverPosition();

  @override
  void initState() {
    super.initState();
    _dragOverPosition.addListener(_forceRebuild);
    widget.layout?.addListener(_forceRebuild);
  }

  @override
  void dispose() {
    super.dispose();
    _dragOverPosition.removeListener(_forceRebuild);
    widget.layout?.removeListener(_forceRebuild);
  }

  @override
  void didUpdateWidget(Docking oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout) {
      oldWidget.layout?.removeListener(_forceRebuild);
      widget.layout?.addListener(_forceRebuild);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.layout != null) {
      if (widget.layout!.maximizedArea != null) {
        List<DockingArea> areas = widget.layout!.layoutAreas();
        List<Widget> children = [];
        for (DockingArea area in areas) {
          if (area != widget.layout!.maximizedArea!) {
            if (area is DockingItem &&
                area.globalKey != null &&
                area.parent != widget.layout?.maximizedArea) {
              // keeping alive other areas
              children.add(
                ExcludeFocus(child: Offstage(child: _buildArea(context, area))),
              );
            }
          }
        }
        children.add(_buildArea(context, widget.layout!.maximizedArea!));
        return Stack(children: children);
      }
      if (widget.layout!.root != null) {
        return _buildArea(context, widget.layout!.root!);
      }
    }
    return Container();
  }

  bool _visibleForWidth(double width, DockingItem item) {
    if (widget.breakpoints == null) return true;
    if (item.showAtDevices == null || item.showAtDevices!.isEmpty) return true;
    final bp = widget.breakpoints!;
    final DeviceScreenType type;
    if (width >= bp.desktop) {
      type = DeviceScreenType.desktop;
    } else if (width >= bp.tablet) {
      type = DeviceScreenType.tablet;
    } else if (width >= bp.watch) {
      type = DeviceScreenType.mobile;
    } else {
      type = DeviceScreenType.watch;
    }
    return item.showAtDevices!.contains(type);
  }

  Widget _buildArea(BuildContext context, DockingArea area) {
    if (area is DockingItem) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final visible = _visibleForWidth(constraints.maxWidth, area);
          if (!visible) return const SizedBox.shrink();
          return DockingItemWidget(
            key: area.key,
            layout: widget.layout!,
            dragOverPosition: _dragOverPosition,
            draggable: widget.draggable,
            item: area,
            onItemSelection: widget.onItemSelection,
            itemCloseInterceptor: widget.itemCloseInterceptor,
            onTabMove: widget.onTabMove,
            onTabLayoutChanged: widget.onTabLayoutChanged,
            onItemClose: widget.onItemClose,
            onItemPositionChanged: widget.onItemPositionChanged,
            dockingButtonsBuilder: widget.dockingButtonsBuilder,
            maximizable: widget.maximizableItem,
          );
        },
      );
    } else if (area is DockingRow) {
      return _row(context, area);
    } else if (area is DockingColumn) {
      return _column(context, area);
    } else if (area is DockingTabs) {
      if (area.childrenCount == 1) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final DockingItem only = area.childAt(0);
            final visible = _visibleForWidth(constraints.maxWidth, only);
            if (!visible) return const SizedBox.shrink();
            return DockingItemWidget(
              key: area.key,
              layout: widget.layout!,
              dragOverPosition: _dragOverPosition,
              draggable: widget.draggable,
              item: only,
              onItemSelection: widget.onItemSelection,
              itemCloseInterceptor: widget.itemCloseInterceptor,
              onTabMove: widget.onTabMove,
              onTabLayoutChanged: widget.onTabLayoutChanged,
              onItemClose: widget.onItemClose,
              onItemPositionChanged: widget.onItemPositionChanged,
              dockingButtonsBuilder: widget.dockingButtonsBuilder,
              maximizable: widget.maximizableItem,
            );
          },
        );
      }
      return DockingTabsWidget(
        key: area.key,
        layout: widget.layout!,
        dragOverPosition: _dragOverPosition,
        draggable: widget.draggable,
        dockingTabs: area,
        onItemSelection: widget.onItemSelection,
        onItemClose: widget.onItemClose,
        onTabMove: widget.onTabMove,
        onTabLayoutChanged: widget.onTabLayoutChanged,
        onItemPositionChanged: widget.onItemPositionChanged,
        itemCloseInterceptor: widget.itemCloseInterceptor,
        dockingButtonsBuilder: widget.dockingButtonsBuilder,
        maximizableTab: widget.maximizableTab,
        maximizableTabsArea: widget.maximizableTabsArea,
      );
    }
    throw UnimplementedError('Unrecognized runtimeType: ${area.runtimeType}');
  }

  Widget _row(BuildContext context, DockingRow row) {
    List<Widget> children = [];
    row.forEach((child) {
      children.add(_buildArea(context, child));
    });

    return MultiSplitView(
      key: row.key,
      axis: Axis.horizontal,
      controller: row.controller,
      antiAliasingWorkaround: widget.antiAliasingWorkaround,
      onWeightChange: _forceRebuild,
      children: children,
    );
  }

  Widget _column(BuildContext context, DockingColumn column) {
    List<Widget> children = [];
    column.forEach((child) {
      children.add(_buildArea(context, child));
    });

    return MultiSplitView(
      key: column.key,
      axis: Axis.vertical,
      controller: column.controller,
      antiAliasingWorkaround: widget.antiAliasingWorkaround,
      onWeightChange: _forceRebuild,
      children: children,
    );
  }

  void _forceRebuild() {
    setState(() {
      // just rebuild
    });
  }
}
