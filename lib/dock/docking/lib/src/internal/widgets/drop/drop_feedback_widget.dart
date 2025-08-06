// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../layout/drop_position.dart';

class DropFeedbackWidget extends StatelessWidget {
  final Widget child;
  final DropPosition? dropPosition;

  const DropFeedbackWidget({super.key, this.dropPosition, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _CustomPainter(dropPosition),
      child: child,
    );
  }
}

class _CustomPainter extends CustomPainter {
  _CustomPainter(this.dropPosition);

  final DropPosition? dropPosition;

  @override
  void paint(Canvas canvas, Size size) {
    if (dropPosition != null) {
      Paint paint =
          Paint()
            ..color = Colors.black.withOpacity(.5)
            ..style = PaintingStyle.fill;
      late Rect rect;
      if (dropPosition == DropPosition.top) {
        rect = Rect.fromLTWH(0, 0, size.width, size.height / 2);
      } else if (dropPosition == DropPosition.bottom) {
        rect = Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2);
      } else if (dropPosition == DropPosition.left) {
        rect = Rect.fromLTWH(0, 0, size.width / 2, size.height);
      } else if (dropPosition == DropPosition.right) {
        rect = Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
      } else {
        throw StateError('Unexpected drop position: $dropPosition');
      }
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CustomPainter oldDelegate) =>
      dropPosition != oldDelegate.dropPosition;
}
