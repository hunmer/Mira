import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/internal/tabbed_view_provider.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tab_button.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabbed_view_menu_item.dart';

/// Widget for tab buttons. Used for any tab button such as the close button.
class TabButtonWidget extends StatefulWidget {
  const TabButtonWidget({
    super.key,
    required this.provider,
    required this.button,
    required this.enabled,
    required this.iconSize,
    required this.normalColor,
    required this.hoverColor,
    required this.disabledColor,
    this.themePadding,
    this.normalBackground,
    this.hoverBackground,
    this.disabledBackground,
  });

  final TabbedViewProvider provider;
  final TabButton button;
  final double iconSize;
  final Color normalColor;
  final Color hoverColor;
  final Color disabledColor;
  final EdgeInsetsGeometry? themePadding;
  final bool enabled;
  final BoxDecoration? normalBackground;
  final BoxDecoration? hoverBackground;
  final BoxDecoration? disabledBackground;

  @override
  State<StatefulWidget> createState() => TabButtonWidgetState();
}

/// The [TabButtonWidget] state.
class TabButtonWidgetState extends State<TabButtonWidget> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    Color color;
    BoxDecoration? background;

    bool hasEvent =
        widget.button.onPressed != null || widget.button.menuBuilder != null;
    bool isDisabled = hasEvent == false || widget.enabled == false;
    if (isDisabled) {
      color =
          widget.button.disabledColor != null
              ? widget.button.disabledColor!
              : widget.disabledColor;
      background =
          widget.button.disabledBackground ?? widget.disabledBackground;
    } else if (_hover) {
      color =
          widget.button.hoverColor != null
              ? widget.button.hoverColor!
              : widget.hoverColor;
      background = widget.button.hoverBackground ?? widget.hoverBackground;
    } else {
      color =
          widget.button.color != null
              ? widget.button.color!
              : widget.normalColor;
      background = widget.button.background ?? widget.normalBackground;
    }

    Widget icon = widget.button.icon.buildIcon(color, widget.iconSize);

    EdgeInsetsGeometry? padding = widget.button.padding ?? widget.themePadding;
    if (padding != null || background != null) {
      icon = Container(padding: padding, decoration: background, child: icon);
    }

    if (isDisabled) {
      return icon;
    }

    VoidCallback? onPressed = widget.button.onPressed;
    if (widget.button.menuBuilder != null) {
      onPressed = () {
        if (widget.provider.menuItems.isEmpty) {
          List<TabbedViewMenuItem> menuItems = widget.button.menuBuilder!(
            context,
          );
          if (menuItems.isNotEmpty) {
            widget.provider.menuItemsUpdater(menuItems);
          }
        } else {
          widget.provider.menuItemsUpdater([]);
        }
      };
    }

    if (widget.button.toolTip != null) {
      icon = Tooltip(
        message: widget.button.toolTip!,
        waitDuration: Duration(milliseconds: 500),
        child: icon,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(onTap: onPressed, child: icon),
    );
  }

  void _onEnter(PointerEnterEvent event) {
    setState(() {
      _hover = true;
    });
  }

  void _onExit(PointerExitEvent event) {
    setState(() {
      _hover = false;
    });
  }
}
