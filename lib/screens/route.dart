// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/widgets/library_list_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tabs_view.dart';
import 'package:mira/screens/settings_screen/settings_screen.dart';

class AppRoutes extends NavigatorObserver {
  // 判断是否可以返回上一级路由
  static bool canPop(BuildContext context) {
    final navigator = Navigator.of(context);
    // 如果当前路由是根路由(/)或者没有上一级路由，则不能返回
    return ModalRoute.of(context)?.settings.name != home && navigator.canPop();
  }

  // 路由路径常量
  static const String home = '/';
  static const String libraries = '/libraries';
  static const String settings = '/settings';
  static const String LibraryTabs = '/LibraryTabs';

  static Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
      transitionDuration: Duration(milliseconds: 0),
      reverseTransitionDuration: Duration(milliseconds: 0),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings route) {
    switch (route.name) {
      case LibraryTabs:
        return _createRoute(const LibraryTabsView());
      case libraries:
        return _createRoute(const LibraryListView());
      case settings:
        return _createRoute(const SettingsScreen());
      default:
        return _createRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${route.name}')),
          ),
        );
    }
  }

  static Map<String, WidgetBuilder> get routes => {
    libraries: (context) => const LibraryListView(),
    LibraryTabs: (context) => const LibraryTabsView(),
    settings: (context) => const SettingsScreen(),
  };

  static String get initialRoute => LibraryTabs;
}
