import 'package:flutter/material.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/internal/tabbed_view_provider.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/internal/tabs_area/drop_tab_widget.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/internal/tabs_area/hidden_tabs.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/internal/tabs_area/tabs_area_buttons_widget.dart';

class TabsAreaCorner extends StatelessWidget {
  final TabbedViewProvider provider;
  final HiddenTabs hiddenTabs;

  const TabsAreaCorner({
    super.key,
    required this.provider,
    required this.hiddenTabs,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: hiddenTabs, builder: _builder);
  }

  Widget _builder(BuildContext context, Widget? child) {
    Widget corner = Container(
      padding: EdgeInsets.only(left: DropTabWidget.dropWidth),
      child: Row(
        children: [
          TabsAreaButtonsWidget(provider: provider, hiddenTabs: hiddenTabs),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
      ),
    );
    if (provider.controller.reorderEnable) {
      return DropTabWidget(
        provider: provider,
        newIndex: provider.controller.length,
        child: corner,
      );
    }
    return corner;
  }
}
