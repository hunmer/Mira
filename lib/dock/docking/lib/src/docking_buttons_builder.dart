import 'package:tabbed_view/tabbed_view.dart';
import 'package:flutter/widgets.dart';
import 'layout/docking_layout.dart';

/// Buttons builder for [DockingItem] and [DockingTabs].
typedef DockingButtonsBuilder =
    List<TabButton> Function(
      BuildContext context,
      DockingTabs? dockingTabs,
      DockingItem? dockingItem,
    );
