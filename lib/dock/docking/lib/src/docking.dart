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

  DeviceScreenType? _currentDeviceType(BuildContext context) {
    final bp = widget.breakpoints;
    if (bp == null) return null;
    final width = MediaQuery.of(context).size.width;
    if (width >= bp.desktop) return DeviceScreenType.desktop;
    if (width >= bp.tablet) return DeviceScreenType.tablet;
    if (width >= bp.watch) return DeviceScreenType.mobile;
    return DeviceScreenType.watch;
  }

  bool _isVisibleForDevice(DockingItem item, DeviceScreenType? type) {
    if (type == null) return true; // no breakpoints configured
    if (item.showAtDevices == null || item.showAtDevices!.isEmpty) return true;

    if (item.visibilityMode == DeviceVisibilityMode.exactDevices) {
      return item.showAtDevices!.contains(type);
    }

    // specifiedAndLarger
    if (item.showAtDevices!.contains(type)) return true;
    const deviceHierarchy = [
      DeviceScreenType.watch,
      DeviceScreenType.mobile,
      DeviceScreenType.tablet,
      DeviceScreenType.desktop,
    ];
    final currentIndex = deviceHierarchy.indexOf(type);
    for (final specified in item.showAtDevices!) {
      if (deviceHierarchy.indexOf(specified) <= currentIndex) return true;
    }
    return false;
  }

  /// 递归检查一个区域是否有可显示的内容
  bool _hasVisibleContentWithType(DockingArea area, DeviceScreenType? type) {
    if (area is DockingItem) {
      return _isVisibleForDevice(area, type);
    } else if (area is DockingTabs) {
      // 检查标签组中是否有任何可显示的标签页
      for (int i = 0; i < area.childrenCount; i++) {
        final child = area.childAt(i);
        if (_isVisibleForDevice(child, type)) return true;
      }
      return false;
    } else if (area is DockingParentArea) {
      // 检查是否有任何子项是可显示的
      for (int i = 0; i < area.childrenCount; i++) {
        if (_hasVisibleContentWithType(area.childAt(i), type)) return true;
      }
      return false;
    }
    return true; // 对于未知类型，默认显示
  }

  /// Compares two area lists by identity and order.
  bool _areasIdenticalOrder(List<Area> a, List<DockingArea> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  Widget _row(BuildContext context, DockingRow row) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = _currentDeviceType(context);
        List<Widget> children = [];
        List<DockingArea> visibleAreas = [];

        row.forEach((child) {
          if (_hasVisibleContentWithType(child, deviceType)) {
            children.add(_buildArea(context, child));
            visibleAreas.add(child);
          }
        });

        if (children.isEmpty) {
          return const SizedBox.shrink();
        }

        // Update controller areas to only include visible areas (compare by identity, not only length)
        final currentAreas = row.controller.areas.toList();
        if (!_areasIdenticalOrder(currentAreas, visibleAreas)) {
          row.controller.areas = visibleAreas.cast<Area>().toList();
        }

        return MultiSplitView(
          key: row.key,
          axis: Axis.horizontal,
          controller: row.controller,
          antiAliasingWorkaround: widget.antiAliasingWorkaround,
          onWeightChange: _forceRebuild,
          children: children,
        );
      },
    );
  }

  Widget _column(BuildContext context, DockingColumn column) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = _currentDeviceType(context);
        List<Widget> children = [];
        List<DockingArea> visibleAreas = [];

        column.forEach((child) {
          if (_hasVisibleContentWithType(child, deviceType)) {
            children.add(_buildArea(context, child));
            visibleAreas.add(child);
          }
        });

        if (children.isEmpty) {
          return const SizedBox.shrink();
        }

        // Update controller areas to only include visible areas (compare by identity, not only length)
        final currentAreas = column.controller.areas.toList();
        if (!_areasIdenticalOrder(currentAreas, visibleAreas)) {
          column.controller.areas = visibleAreas.cast<Area>().toList();
        }

        return MultiSplitView(
          key: column.key,
          axis: Axis.vertical,
          controller: column.controller,
          antiAliasingWorkaround: widget.antiAliasingWorkaround,
          onWeightChange: _forceRebuild,
          children: children,
        );
      },
    );
  }

  // Backward-compatible width-based helper delegating to device-type logic
  bool _visibleForWidth(double width, DockingItem item) {
    return _isVisibleForDevice(item, _currentDeviceType(context));
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
      return LayoutBuilder(
        builder: (context, constraints) {
          // 先整体判断此 Tabs 是否还有可见内容
          if (!_hasVisibleContentWithType(area, _currentDeviceType(context))) {
            return const SizedBox.shrink();
          }
          if (area.childrenCount == 1) {
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
            breakpoints: widget.breakpoints,
          );
        },
      );
    }
    throw UnimplementedError('Unrecognized runtimeType: ${area.runtimeType}');
  }

  void _forceRebuild() {
    setState(() {
      // just rebuild
    });
  }
}
