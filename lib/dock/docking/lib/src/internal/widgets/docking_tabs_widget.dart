import 'dart:math' as math;

import '../../docking_buttons_builder.dart';
import '../../drag_over_position.dart';
import 'draggable_config_mixin.dart';
import 'drop/content_wrapper.dart';
import 'drop/drop_feedback_widget.dart';
import '../../layout/docking_layout.dart';
import '../../layout/drop_position.dart';
import '../../on_item_close.dart';
import '../../on_item_selection.dart';
import '../../on_item_move.dart';
import '../../on_item_layout_changed.dart';
import '../../theme/docking_theme.dart';
import '../../theme/docking_theme_data.dart';
import 'package:flutter/material.dart';
import 'package:tabbed_view/tabbed_view.dart';

/// Represents a widget for [DockingTabs].
class DockingTabsWidget extends StatefulWidget {
  DockingTabsWidget({
    Key? key,
    required this.layout,
    required this.dragOverPosition,
    required this.dockingTabs,
    this.onItemSelection,
    this.onItemClose,
    this.onItemMove,
    this.onItemLayoutChanged,
    this.itemCloseInterceptor,
    this.dockingButtonsBuilder,
    required this.maximizableTab,
    required this.maximizableTabsArea,
    required this.draggable,
  }) : super(key: key);

  final DockingLayout layout;
  final DockingTabs dockingTabs;
  final OnItemSelection? onItemSelection;
  final OnItemClose? onItemClose;
  final OnItemMove? onItemMove;
  final OnItemLayoutChanged? onItemLayoutChanged;
  final ItemCloseInterceptor? itemCloseInterceptor;
  final DockingButtonsBuilder? dockingButtonsBuilder;
  final bool maximizableTab;
  final bool maximizableTabsArea;
  final DragOverPosition dragOverPosition;
  final bool draggable;

  @override
  State<StatefulWidget> createState() => DockingTabsWidgetState();
}

class DockingTabsWidgetState extends State<DockingTabsWidget>
    with DraggableConfigMixin {
  DropPosition? _activeDropPosition;

  @override
  Widget build(BuildContext context) {
    List<TabData> tabs = [];
    widget.dockingTabs.forEach((child) {
      Widget content = child.widget;
      if (child.globalKey != null) {
        content = KeyedSubtree(child: content, key: child.globalKey);
      }
      List<TabButton>? buttons;
      if (child.buttons != null && child.buttons!.isNotEmpty) {
        buttons = [];
        buttons.addAll(child.buttons!);
      }
      final bool maximizable =
          child.maximizable != null
              ? child.maximizable!
              : widget.maximizableTab;
      if (maximizable) {
        if (buttons == null) {
          buttons = [];
        }
        DockingThemeData data = DockingTheme.of(context);
        if (widget.layout.maximizedArea != null &&
            widget.layout.maximizedArea == child) {
          buttons.add(
            TabButton(
              icon: data.restoreIcon,
              onPressed: () => widget.layout.restore(),
            ),
          );
        } else {
          buttons.add(
            TabButton(
              icon: data.maximizeIcon,
              onPressed: () => widget.layout.maximizeDockingItem(child),
            ),
          );
        }
      }
      tabs.add(
        TabData(
          value: child,
          text: child.name != null ? child.name! : '',
          content: content,
          closable: child.closable,
          keepAlive: child.globalKey != null,
          leading: child.leading,
          buttons: buttons,
          draggable: widget.draggable,
        ),
      );
    });
    TabbedViewController controller = TabbedViewController(tabs);
    controller.selectedIndex = math.min(
      widget.dockingTabs.selectedIndex,
      tabs.length - 1,
    );

    Widget tabbedView = TabbedView(
      controller: controller,
      tabsAreaButtonsBuilder: _tabsAreaButtonsBuilder,
      onTabSelection: (int? index) {
        if (index != null) {
          widget.dockingTabs.selectedIndex = index;
          if (widget.onItemSelection != null) {
            widget.onItemSelection!(widget.dockingTabs.childAt(index));
          }
        }
      },
      tabCloseInterceptor: _tabCloseInterceptor,
      onDraggableBuild:
          widget.draggable
              ? (
                TabbedViewController controller,
                int tabIndex,
                TabData tabData,
              ) {
                return buildDraggableConfig(
                  dockingDrag: widget.dragOverPosition,
                  tabData: tabData,
                  sourceLayout: widget.layout,
                );
              }
              : null,
      onTabClose: _onTabClose,
      contentBuilder:
          (context, tabIndex) => TabsContentWrapper(
            listener: _updateActiveDropPosition,
            layout: widget.layout,
            dockingTabs: widget.dockingTabs,
            child: controller.tabs[tabIndex].content!,
          ),
      onBeforeDropAccept: widget.draggable ? _onBeforeDropAccept : null,
    );
    if (widget.draggable && widget.dragOverPosition.enable) {
      return DropFeedbackWidget(
        dropPosition: _activeDropPosition,
        child: tabbedView,
      );
    }
    return tabbedView;
  }

  void _updateActiveDropPosition(DropPosition? dropPosition) {
    if (_activeDropPosition != dropPosition) {
      setState(() {
        _activeDropPosition = dropPosition;
      });
    }
  }

  bool _onBeforeDropAccept(
    DraggableData source,
    TabbedViewController target,
    int newIndex,
  ) {
    // 检查是否为有效的DockingItem
    if (source.tabData.value == null) {
      return false;
    }

    DockingItem dockingItem = source.tabData.value;

    // 检查是否为跨layout拖动
    if (dockingItem.layoutId != widget.layout.id) {
      // 跨layout拖动：先创建副本添加到目标layout，然后标记拖动完成
      try {
        // 创建新的DockingItem副本
        DockingItem newItem = DockingItem(
          id: dockingItem.id,
          name: dockingItem.name,
          widget: dockingItem.widget,
          value: dockingItem.value,
          closable: dockingItem.closable,
          maximizable: dockingItem.maximizable,
          leading: dockingItem.leading,
          buttons: dockingItem.buttons,
          keepAlive: dockingItem.globalKey != null,
        );

        // 添加到目标layout
        widget.layout.addItemOn(
          newItem: newItem,
          targetArea: widget.dockingTabs,
          dropIndex: newIndex,
        );

        // 标记跨layout拖动已完成，这样源layout会在拖动结束时移除原item
        DraggableConfigMixin.markCrossLayoutDropCompleted();

        if (widget.onItemLayoutChanged != null) {
          widget.onItemLayoutChanged!(
            oldItem: dockingItem,
            newItem: newItem,
            targetArea: widget.dockingTabs,
            dropIndex: newIndex,
          );
        }

        return true;
      } catch (e) {
        // 如果跨layout拖动失败，返回false阻止拖动
        print('Cross-layout drag failed: $e');
        return false;
      }
    } else {
      // 同一layout内的拖动
      widget.layout.moveItem(
        draggedItem: dockingItem,
        targetArea: widget.dockingTabs,
        dropIndex: newIndex,
      );
      if (widget.onItemMove != null) {
        widget.onItemMove!(
          draggedItem: dockingItem,
          targetArea: widget.dockingTabs,
          dropIndex: newIndex,
        );
      }
      return true;
    }
  }

  List<TabButton> _tabsAreaButtonsBuilder(BuildContext context, int tabsCount) {
    List<TabButton> buttons = [];
    if (widget.dockingButtonsBuilder != null) {
      buttons.addAll(
        widget.dockingButtonsBuilder!(context, widget.dockingTabs, null),
      );
    }
    final bool maximizable =
        widget.dockingTabs.maximizable != null
            ? widget.dockingTabs.maximizable!
            : widget.maximizableTabsArea;
    if (maximizable) {
      DockingThemeData data = DockingTheme.of(context);
      if (widget.layout.maximizedArea != null &&
          widget.layout.maximizedArea == widget.dockingTabs) {
        buttons.add(
          TabButton(
            icon: data.restoreIcon,
            onPressed: () => widget.layout.restore(),
          ),
        );
      } else {
        buttons.add(
          TabButton(
            icon: data.maximizeIcon,
            onPressed:
                () => widget.layout.maximizeDockingTabs(widget.dockingTabs),
          ),
        );
      }
    }
    return buttons;
  }

  bool _tabCloseInterceptor(int tabIndex) {
    if (widget.itemCloseInterceptor != null) {
      return widget.itemCloseInterceptor!(widget.dockingTabs.childAt(tabIndex));
    }
    return true;
  }

  void _onTabClose(int tabIndex, TabData tabData) {
    DockingItem dockingItem = widget.dockingTabs.childAt(tabIndex);
    widget.layout.removeItem(item: dockingItem);
    if (widget.onItemClose != null) {
      widget.onItemClose!(dockingItem);
    }
  }
}
