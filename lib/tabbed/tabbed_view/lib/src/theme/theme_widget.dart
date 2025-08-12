import 'package:flutter/widgets.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabbed_view.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/theme/tabbed_view_theme_data.dart';

/// Applies a [TabbedView] theme to descendant widgets.
/// See also:
///
///  * [TabbedViewThemeData], which describes the actual configuration of a theme.
class TabbedViewTheme extends StatelessWidget {
  /// Applies the given theme [data] to [child].
  ///
  /// The [data] and [child] arguments must not be null.
  const TabbedViewTheme({super.key, required this.child, required this.data});

  /// Specifies the theme for descendant widgets.
  final TabbedViewThemeData data;

  /// The widget below this widget in the tree.
  final Widget child;

  static final TabbedViewThemeData _defaultTheme =
      TabbedViewThemeData.classic();

  /// The data from the closest [TabbedViewTheme] instance that encloses the given
  /// context.
  static TabbedViewThemeData of(BuildContext context) {
    final _InheritedTheme? inheritedTheme =
        context.dependOnInheritedWidgetOfExactType<_InheritedTheme>();
    final TabbedViewThemeData data =
        inheritedTheme?.theme.data ?? _defaultTheme;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTheme(theme: this, child: child);
  }
}

class _InheritedTheme extends InheritedWidget {
  const _InheritedTheme({required this.theme, required super.child});

  final TabbedViewTheme theme;

  @override
  bool updateShouldNotify(_InheritedTheme old) => theme.data != old.theme.data;
}
