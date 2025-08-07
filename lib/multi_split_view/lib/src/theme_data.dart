import 'package:mira/multi_split_view/lib/src/divider_painter.dart';
import 'package:mira/multi_split_view/lib/src/multi_split_view.dart';

/// The [MultiSplitView] theme.
/// Defines the configuration of the overall visual [MultiSplitViewTheme] for a widget subtree within the app.
class MultiSplitViewThemeData {
  static const double defaultDividerThickness = 10.0;

  /// Builds a theme data.
  /// The [dividerThickness] argument must also be positive.
  MultiSplitViewThemeData({
    this.dividerThickness = defaultDividerThickness,
    this.dividerPainter,
  }) {
    if (dividerThickness <= 0) {
      throw Exception('The thickness of the divider must be positive.');
    }
  }

  final double dividerThickness;

  /// Defines a divider painter. The default value is [NULL].
  final DividerPainter? dividerPainter;
}
