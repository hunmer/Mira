import 'package:flutter/widgets.dart';
import 'package:mira/multi_split_view/lib/src/theme_data.dart';

/// Signature for when a weight area is changed.
typedef OnWeightChange = void Function();

typedef DividerBuilder =
    Widget Function(
      Axis axis,
      int index,
      bool resizable,
      bool dragging,
      bool highlighted,
      MultiSplitViewThemeData themeData,
    );
