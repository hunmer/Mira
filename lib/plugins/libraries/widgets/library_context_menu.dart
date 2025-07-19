import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import '../models/library.dart';

class LibraryContextMenu {
  static void show({
    required BuildContext context,
    required GlobalKey tabKey,
    required Library library,
    required List<Library> initialLibraries,
    required VoidCallback onCloseTab,
  }) {
    final renderBox = tabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final right = offset.dx + renderBox.size.width / 2;
    final top = offset.dy + 20;

    final isPinned = initialLibraries.contains(library);

    final entries = <ContextMenuEntry>[
      MenuItem(
        label: isPinned ? '取消固定' : '固定',
        icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
        onSelected: () {
          if (isPinned) {
            initialLibraries.remove(library);
          } else {
            initialLibraries.add(library);
          }
        },
      ),
      MenuItem(label: '关闭', icon: Icons.close, onSelected: onCloseTab),
    ];

    final menu = ContextMenu(
      entries: entries,
      position: Offset(right, top),
      padding: const EdgeInsets.all(8.0),
    );

    showContextMenu(context, contextMenu: menu);
  }
}
