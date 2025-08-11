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
    this.autoBreakpoints = false,
    this.defaultLayout,
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

  /// When true, breakpoints are evaluated against the current Docking's own
  /// size (via LayoutBuilder constraints) instead of the global MediaQuery
  /// width. This makes nested Docking widgets responsive to their container
  /// size rather than the whole screen.
  final bool autoBreakpoints;

  /// Callback function to create default layout when all docking items are closed.
  /// Returns a DockingLayout with default items.
  final DockingLayout Function()? defaultLayout;

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
    DockingLayout? currentLayout = widget.layout;

    // 检查是否所有dockingitem都被关闭了
    if (currentLayout != null && !_hasAnyVisibleItems(currentLayout)) {
      if (widget.defaultLayout != null) {
        currentLayout = widget.defaultLayout!();
      }
    }

    // 如果currentLayout为null，使用一个默认的空布局
    if (currentLayout == null) {
      currentLayout = DockingLayout(); // 这会触发DockingLayout的默认创建
    }

    // Compute a single device type for the whole Docking instance
    return LayoutBuilder(
      builder: (context, constraints) {
        final DeviceScreenType? deviceType =
            widget.autoBreakpoints
                ? _deviceTypeForWidth(constraints.maxWidth)
                : _currentDeviceType(context);

        final layout = currentLayout!;
        if (layout.maximizedArea != null) {
          // Keep other areas alive but offstage
          final List<DockingArea> areas = layout.layoutAreas();
          final List<Widget> children = [];
          for (final area in areas) {
            if (area != layout.maximizedArea!) {
              if (area is DockingItem &&
                  area.globalKey != null &&
                  area.parent != layout.maximizedArea) {
                children.add(
                  ExcludeFocus(
                    child: Offstage(
                      child: _buildArea(context, area, deviceType),
                    ),
                  ),
                );
              }
            }
          }
          children.add(_buildArea(context, layout.maximizedArea!, deviceType));
          return Stack(children: children);
        }
        if (layout.root != null) {
          return _buildArea(context, layout.root!, deviceType);
        }
        return Container();
      },
    );
  }

  DeviceScreenType? _deviceTypeForWidth(double width) {
    final bp = widget.breakpoints;
    if (bp == null) return null;
    if (width >= bp.desktop) return DeviceScreenType.desktop;
    if (width >= bp.tablet) return DeviceScreenType.tablet;
    if (width >= bp.watch) return DeviceScreenType.mobile;
    return DeviceScreenType.watch;
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

  /// 检查布局中是否有任何可见的DockingItem
  bool _hasAnyVisibleItems(DockingLayout layout) {
    if (layout.root == null) return false;
    return _hasVisibleItems(layout.root!);
  }

  /// 递归检查区域中是否有可见的DockingItem
  bool _hasVisibleItems(DockingArea area) {
    if (area is DockingItem) {
      return true; // 有DockingItem就返回true
    } else if (area is DockingTabs) {
      return area.childrenCount > 0; // 有子项就返回true
    } else if (area is DockingParentArea) {
      for (int i = 0; i < area.childrenCount; i++) {
        if (_hasVisibleItems(area.childAt(i))) {
          return true;
        }
      }
    }
    return false;
  }

  /// 递归检查一个区域是否有可显示的内容（基于同一 deviceType）
  bool _hasVisibleContentWithType(DockingArea area, DeviceScreenType? type) {
    if (area is DockingItem) {
      return _isVisibleForDevice(area, type);
    } else if (area is DockingTabs) {
      for (int i = 0; i < area.childrenCount; i++) {
        final child = area.childAt(i);
        if (_isVisibleForDevice(child, type)) return true;
      }
      return false;
    } else if (area is DockingParentArea) {
      for (int i = 0; i < area.childrenCount; i++) {
        if (_hasVisibleContentWithType(area.childAt(i), type)) return true;
      }
      return false;
    }
    return true;
  }

  /// Compares two area lists by identity and order.
  bool _areasIdenticalOrder(List<Area> a, List<DockingArea> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  Widget _row(BuildContext context, DockingRow row, DeviceScreenType? type) {
    List<Widget> children = [];
    List<DockingArea> visibleAreas = [];

    row.forEach((child) {
      if (_hasVisibleContentWithType(child, type)) {
        children.add(_buildArea(context, child, type));
        visibleAreas.add(child);
      }
    });

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    // Update controller areas to only include visible areas (compare by identity)
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
  }

  Widget _column(
    BuildContext context,
    DockingColumn column,
    DeviceScreenType? type,
  ) {
    List<Widget> children = [];
    List<DockingArea> visibleAreas = [];

    column.forEach((child) {
      if (_hasVisibleContentWithType(child, type)) {
        children.add(_buildArea(context, child, type));
        visibleAreas.add(child);
      }
    });

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

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
  }

  Widget _buildArea(
    BuildContext context,
    DockingArea area,
    DeviceScreenType? type,
  ) {
    if (area is DockingItem) {
      // Visibility already decided by the same `type` used by parent
      if (!_isVisibleForDevice(area, type)) return const SizedBox.shrink();
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
    } else if (area is DockingRow) {
      return _row(context, area, type);
    } else if (area is DockingColumn) {
      return _column(context, area, type);
    } else if (area is DockingTabs) {
      // Hide whole tabs if nothing visible under same device type
      if (!_hasVisibleContentWithType(area, type)) {
        return const SizedBox.shrink();
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
        autoBreakpoints: widget.autoBreakpoints,
        deviceType: type,
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
