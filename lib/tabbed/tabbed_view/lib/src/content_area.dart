import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/internal/tabbed_view_provider.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tab_data.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabbed_view_controller.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabbed_view_menu_widget.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/content_area_theme_data.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/tabbed_view_theme_data.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/theme_widget.dart';

/// Container widget for the tab content and menu.
class ContentArea extends StatelessWidget {
  const ContentArea({
    super.key,
    required this.tabsAreaVisible,
    required this.provider,
  });

  final bool tabsAreaVisible;
  final TabbedViewProvider provider;

  @override
  Widget build(BuildContext context) {
    TabbedViewController controller = provider.controller;
    TabbedViewThemeData theme = TabbedViewTheme.of(context);
    ContentAreaThemeData contentAreaTheme = theme.contentArea;

    LayoutBuilder layoutBuilder = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        List<Widget> children = [];

        for (int i = 0; i < controller.tabs.length; i++) {
          TabData tab = controller.tabs[i];
          bool selectedTab =
              controller.selectedIndex != null && i == controller.selectedIndex;
          if (tab.keepAlive || selectedTab) {
            Widget? child;
            if (provider.contentBuilder != null) {
              child = provider.contentBuilder!(context, i);
            } else {
              child = tab.content;
            }
            if (child != null) {
              child = ExcludeFocus(excluding: !selectedTab, child: child);
            }
            if (tab.keepAlive) {
              child = Offstage(offstage: !selectedTab, child: child);
            }
            children.add(
              Positioned.fill(
                key: tab.key,
                child: Container(
                  padding: contentAreaTheme.padding,
                  child: child,
                ),
              ),
            );
          }
        }

        NotificationListenerCallback<SizeChangedLayoutNotification>?
        onSizeNotification;
        if (provider.menuItems.isNotEmpty) {
          children.add(
            Positioned.fill(child: _Glass(theme.menu.blur, provider)),
          );
          children.add(
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: LimitedBox(
                maxWidth: math.min(theme.menu.maxWidth, constraints.maxWidth),
                child: TabbedViewMenuWidget(provider: provider),
              ),
            ),
          );
          onSizeNotification = (n) {
            scheduleMicrotask(() {
              provider.menuItemsUpdater([]);
            });
            return true;
          };
        }
        Widget listener = NotificationListener<SizeChangedLayoutNotification>(
          onNotification: onSizeNotification,
          child: SizeChangedLayoutNotifier(child: Stack(children: children)),
        );
        return Container(
          decoration:
              tabsAreaVisible
                  ? contentAreaTheme.decoration
                  : contentAreaTheme.decorationNoTabsArea,
          child: listener,
        );
      },
    );
    if (provider.contentClip) {
      return ClipRect(child: layoutBuilder);
    }
    return layoutBuilder;
  }
}

class _Glass extends StatelessWidget {
  const _Glass(this.blur, this.provider);

  final bool blur;
  final TabbedViewProvider provider;

  @override
  Widget build(BuildContext context) {
    Widget? child;
    if (blur) {
      child = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(color: Colors.transparent),
      );
    }
    return ClipRect(
      child: GestureDetector(
        child: child,
        onTap: () => provider.menuItemsUpdater([]),
      ),
    );
  }
}
