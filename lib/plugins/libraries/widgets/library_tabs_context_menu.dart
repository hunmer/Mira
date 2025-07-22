import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import '../models/library.dart';

void show({
  required BuildContext context,
  required Offset position,
  required Library library,
  required bool isPinned,
  required Function(bool) togglePin,
  required VoidCallback onCloseTab,
}) {
  final entries = <ContextMenuEntry>[
    MenuItem(
      label: isPinned ? '取消固定' : '固定',
      icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
      onSelected: () => togglePin(!isPinned),
    ),
    MenuItem(label: '关闭', icon: Icons.close, onSelected: onCloseTab),
  ];

  final menu = ContextMenu(
    entries: entries,
    position: position,
    padding: const EdgeInsets.all(8.0),
  );

  showContextMenu(context, contextMenu: menu);
}
