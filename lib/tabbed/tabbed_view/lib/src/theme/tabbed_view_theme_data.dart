import 'package:flutter/material.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/icon_provider.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/content_area_theme_data.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/default_themes/classic_theme.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/default_themes/dark_theme.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/default_themes/minimalist_theme.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/default_themes/mobile_theme.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/menu_theme_data.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/tab_theme_data.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/tabs_area_theme_data.dart';

/// The [TabbedView] theme.
/// Defines the configuration of the overall visual [Theme] for a widget subtree within the app.
class TabbedViewThemeData {
  TabbedViewThemeData({
    TabsAreaThemeData? tabsArea,
    TabThemeData? tab,
    ContentAreaThemeData? contentArea,
    TabbedViewMenuThemeData? menu,
  }) : this.tab = tab != null ? tab : TabThemeData(),
       this.tabsArea = tabsArea != null ? tabsArea : TabsAreaThemeData(),
       this.contentArea =
           contentArea != null ? contentArea : ContentAreaThemeData(),
       this.menu = menu != null ? menu : TabbedViewMenuThemeData();

  TabsAreaThemeData tabsArea;
  TabThemeData tab;
  ContentAreaThemeData contentArea;
  TabbedViewMenuThemeData menu;

  /// Sets the Material Design icons.
  void materialDesignIcons() {
    this.tabsArea.menuIcon = IconProvider.data(Icons.arrow_drop_down);
    this.tab.closeIcon = IconProvider.data(Icons.close);
  }

  /// Builds the predefined dark theme.
  factory TabbedViewThemeData.dark({
    MaterialColor colorSet = Colors.grey,
    double fontSize = 13,
  }) {
    return DarkTheme.build(colorSet: colorSet, fontSize: 13);
  }

  /// Builds the predefined classic theme.
  factory TabbedViewThemeData.classic({
    MaterialColor colorSet = Colors.grey,
    double fontSize = 13,
    Color borderColor = Colors.black,
  }) {
    return ClassicTheme.build(
      colorSet: colorSet,
      fontSize: fontSize,
      borderColor: borderColor,
    );
  }

  /// Builds the predefined mobile theme.
  factory TabbedViewThemeData.mobile({
    MaterialColor colorSet = Colors.grey,
    Color accentColor = Colors.blue,
    double fontSize = 13,
  }) {
    return MobileTheme.build(
      colorSet: colorSet,
      accentColor: accentColor,
      fontSize: fontSize,
    );
  }

  /// Builds the predefined minimalist theme.
  factory TabbedViewThemeData.minimalist({
    MaterialColor colorSet = Colors.grey,
  }) {
    return MinimalistTheme.build(colorSet: colorSet);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TabbedViewThemeData &&
          runtimeType == other.runtimeType &&
          tabsArea == other.tabsArea &&
          tab == other.tab &&
          contentArea == other.contentArea &&
          menu == other.menu;

  @override
  int get hashCode =>
      tabsArea.hashCode ^ tab.hashCode ^ contentArea.hashCode ^ menu.hashCode;
}
