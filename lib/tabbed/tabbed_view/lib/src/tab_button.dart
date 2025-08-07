import 'package:flutter/widgets.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/icon_provider.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabbed_view_menu_builder.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/tabbed_view_theme_constants.dart';

/// Configures a tab button.
class TabButton {
  TabButton({
    required this.icon,
    this.color,
    this.hoverColor,
    this.disabledColor,
    this.background,
    this.hoverBackground,
    this.disabledBackground,
    this.onPressed,
    this.menuBuilder,
    this.toolTip,
    this.padding,
    double? iconSize,
  }) : this.iconSize =
           iconSize == null
               ? iconSize
               : TabbedViewThemeConstants.normalize(iconSize);

  final IconProvider icon;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? hoverColor;
  final Color? disabledColor;
  final BoxDecoration? background;
  final BoxDecoration? hoverBackground;
  final BoxDecoration? disabledBackground;
  final VoidCallback? onPressed;
  final TabbedViewMenuBuilder? menuBuilder;
  final String? toolTip;
  final double? iconSize;
}
