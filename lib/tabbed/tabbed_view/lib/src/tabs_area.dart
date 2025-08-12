import 'package:flutter/material.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/internal/tabbed_view_provider.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/internal/tabs_area/hidden_tabs.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/internal/tabs_area/tabs_area_corner.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tab_status.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tab_widget.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabbed_view_controller.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabs_area_layout.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/tabbed_view_theme_data.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/tabs_area_theme_data.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/theme_widget.dart';

/// Widget for the tabs and buttons.
class TabsArea extends StatefulWidget {
  const TabsArea({super.key, required this.provider});

  final TabbedViewProvider provider;

  @override
  State<StatefulWidget> createState() => _TabsAreaState();
}

/// The [TabsArea] state.
class _TabsAreaState extends State<TabsArea> {
  int? _highlightedIndex;

  final HiddenTabs _hiddenTabs = HiddenTabs();

  @override
  Widget build(BuildContext context) {
    TabbedViewController controller = widget.provider.controller;
    TabbedViewThemeData theme = TabbedViewTheme.of(context);
    TabsAreaThemeData tabsAreaTheme = theme.tabsArea;
    List<Widget> children = [];
    for (int index = 0; index < controller.tabs.length; index++) {
      TabStatus status = _getStatusFor(index);
      children.add(
        TabWidget(
          key: controller.tabs[index].uniqueKey,
          index: index,
          status: status,
          provider: widget.provider,
          updateHighlightedIndex: _updateHighlightedIndex,
          onClose: _onTabClose,
        ),
      );
    }

    children.add(
      TabsAreaCorner(provider: widget.provider, hiddenTabs: _hiddenTabs),
    );

    Widget tabsAreaLayout = TabsAreaLayout(
      theme: theme,
      hiddenTabs: _hiddenTabs,
      selectedTabIndex: controller.selectedIndex,
      children: children,
    );
    tabsAreaLayout = ClipRect(child: tabsAreaLayout);

    Decoration? decoration;
    if (tabsAreaTheme.color != null || tabsAreaTheme.border != null) {
      decoration = BoxDecoration(
        color: tabsAreaTheme.color,
        border: tabsAreaTheme.border,
      );
    }
    return Container(decoration: decoration, child: tabsAreaLayout);
  }

  /// Gets the status of the tab for a given index.
  TabStatus _getStatusFor(int tabIndex) {
    TabbedViewController controller = widget.provider.controller;
    if (controller.tabs.isEmpty || tabIndex >= controller.tabs.length) {
      throw Exception('Invalid tab index: $tabIndex');
    }

    if (controller.selectedIndex != null &&
        controller.selectedIndex == tabIndex) {
      return TabStatus.selected;
    } else if (_highlightedIndex != null && _highlightedIndex == tabIndex) {
      return TabStatus.highlighted;
    }
    return TabStatus.normal;
  }

  void _updateHighlightedIndex(int? tabIndex) {
    if (_highlightedIndex != tabIndex) {
      setState(() {
        _highlightedIndex = tabIndex;
      });
    }
  }

  void _onTabClose() {
    setState(() {
      _highlightedIndex = null;
    });
  }
}
