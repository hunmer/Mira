// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ColorPickerSection extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerSection({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 定义常用颜色列表
    final List<Color> commonColors = [
      Colors.grey,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.yellow,
      Colors.lime,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              commonColors.map((color) {
                final isSelected = selectedColor.value == color.value;
                return GestureDetector(
                  onTap: () => onColorChanged(color),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border:
                          isSelected
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                            : null,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
