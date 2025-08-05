import 'package:mira/dock/docking/lib/src/on_tab_layout_changed.dart';
import 'package:mira/dock/docking/lib/src/on_tab_move.dart';
import 'package:mira/dock/docking/lib/src/on_item_position_changed.dart';

import '../../docking_buttons_builder.dart';
import '../../drag_over_position.dart';
import 'draggable_config_mixin.dart';
import 'drop/content_wrapper.dart';
import 'drop/drop_feedback_widget.dart';
import '../../layout/docking_layout.dart';
import '../../layout/drop_position.dart';
import '../../on_item_close.dart';
import '../../on_item_selection.dart';
import '../../theme/docking_theme.dart';
import '../../theme/docking_theme_data.dart';
import 'package:flutter/material.dart';

import 'package:tabbed_view/tabbed_view.dart';

/// Represents a widget for [DockingItem].

class DockingItemWidget extends StatefulWidget {
  DockingItemWidget({
    Key? key,
    required this.layout,
    required this.dragOverPosition,
    required this.item,
    this.onItemSelection,
    this.onItemClose,
    this.onTabMove,
    this.onTabLayoutChanged,
    this.onItemPositionChanged,
    this.itemCloseInterceptor,
    this.dockingButtonsBuilder,
    required this.maximizable,
    required this.draggable,
  }) : super(key: key);

  final DockingLayout layout;
  final DockingItem item;
  final OnItemSelection? onItemSelection;
  final OnItemClose? onItemClose;
  final OnTabMove? onTabMove;
  final OnTabLayoutChanged? onTabLayoutChanged;
  final OnItemPositionChanged? onItemPositionChanged;

  final ItemCloseInterceptor? itemCloseInterceptor;
  final DockingButtonsBuilder? dockingButtonsBuilder;
  final bool maximizable;
  final DragOverPosition dragOverPosition;
  final bool draggable;

  @override
  State<StatefulWidget> createState() => DockingItemWidgetState();
}

class DockingItemWidgetState extends State<DockingItemWidget>
    with DraggableConfigMixin {
  DropPosition? _activeDropPosition;

  @override
  Widget build(BuildContext context) {
    String name = widget.item.name != null ? widget.item.name! : '';
    Widget content = widget.item.widget;
    if (widget.item.globalKey != null) {
      content = KeyedSubtree(child: content, key: widget.item.globalKey);
    }
    List<TabButton>? buttons;
    if (widget.item.buttons != null && widget.item.buttons!.isNotEmpty) {
      buttons = [];
      buttons.addAll(widget.item.buttons!);
    }
    final bool maximizable =
        widget.item.maximizable != null
            ? widget.item.maximizable!
            : widget.maximizable;
    if (maximizable) {
      if (buttons == null) {
        buttons = [];
      }
      DockingThemeData data = DockingTheme.of(context);

      if (widget.layout.maximizedArea != null &&
          widget.layout.maximizedArea == widget.item) {
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
            onPressed: () => widget.layout.maximizeDockingItem(widget.item),
          ),
        );
      }
    }

    List<TabData> tabs = [
      TabData(
        value: widget.item,
        text: name,
        content: content,
        closable: widget.item.closable,
        leading: widget.item.leading,
        buttons: buttons,
        draggable: widget.draggable,
      ),
    ];
    TabbedViewController controller = TabbedViewController(tabs);

    OnTabSelection? onTabSelection;
    if (widget.onItemSelection != null) {
      onTabSelection = (int? index) {
        if (index != null) {
          widget.onItemSelection!(widget.item);
        }
      };
    }

    Widget tabbedView = TabbedView(
      tabsAreaButtonsBuilder: _tabsAreaButtonsBuilder,
      onTabSelection: onTabSelection,
      tabCloseInterceptor: _tabCloseInterceptor,
      onTabClose: _onTabClose,
      controller: controller,
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
      contentBuilder:
          (context, tabIndex) => ItemContentWrapper(
            listener: _updateActiveDropPosition,
            layout: widget.layout,
            dockingItem: widget.item,
            onItemPositionChanged: widget.onItemPositionChanged,
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

  // tab拖拽事件（非内容）
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

    if (dockingItem != widget.item) {
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

          // 添加到目标layout的目标item
          widget.layout.addItemOn(
            newItem: newItem,
            targetArea: widget.item,
            dropIndex: newIndex,
          );

          // 标记跨layout拖动已完成，这样源layout会在拖动结束时移除原item
          DraggableConfigMixin.markCrossLayoutDropCompleted();

          if (widget.onTabLayoutChanged != null) {
            widget.onTabLayoutChanged!(
              oldItem: dockingItem,
              newItem: newItem,
              targetArea: widget.item,
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
          targetArea: widget.item,
          dropIndex: newIndex,
        );
        if (widget.onTabMove != null) {
          widget.onTabMove!(
            draggedItem: dockingItem,
            targetArea: widget.item,
            dropIndex: newIndex,
          );
        }
        return true;
      }
    }
    return true;
  }

  void _updateActiveDropPosition(DropPosition? dropPosition) {
    if (_activeDropPosition != dropPosition) {
      setState(() {
        _activeDropPosition = dropPosition;
      });
    }
  }

  List<TabButton> _tabsAreaButtonsBuilder(BuildContext context, int tabsCount) {
    if (widget.dockingButtonsBuilder != null) {
      return widget.dockingButtonsBuilder!(context, null, widget.item);
    }
    return [];
  }

  bool _tabCloseInterceptor(int tabIndex) {
    if (widget.itemCloseInterceptor != null) {
      return widget.itemCloseInterceptor!(widget.item);
    }
    return true;
  }

  void _onTabClose(int tabIndex, TabData tabData) {
    widget.layout.removeItem(item: widget.item);
    if (widget.onItemClose != null) {
      widget.onItemClose!(widget.item);
    }
  }
}
