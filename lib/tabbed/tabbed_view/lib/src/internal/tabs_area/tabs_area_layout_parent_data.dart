import 'package:flutter/rendering.dart';

/// Parent data for [_TabsAreaLayoutRenderBox] class.
class TabsAreaLayoutParentData extends ContainerBoxParentData<RenderBox> {
  bool visible = false;
  bool selected = false;

  double leftBorderHeight = 0;
  double rightBorderHeight = 0;

  /// Resets all values.
  void reset() {
    visible = false;
    selected = false;

    leftBorderHeight = 0;
    rightBorderHeight = 0;
  }
}
