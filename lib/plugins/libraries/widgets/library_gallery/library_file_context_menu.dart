import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';

void show({
  required BuildContext context,
  required LibrariesPlugin plugin,
  required LibraryFile file,
  required Library library,
  required GlobalKey tabKey,
  required VoidCallback onDelete,
  required VoidCallback onSelectTag,
  required VoidCallback onSelectFolder,
  required VoidCallback onShowInfo,
}) {
  final renderBox = tabKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final offset = renderBox.localToGlobal(Offset.zero);
  final right = offset.dx + 20;
  final top = offset.dy + renderBox.size.height / 2;

  final entries = <ContextMenuEntry>[
    MenuItem(label: '设置标签', icon: Icons.tag, onSelected: onSelectTag),
    MenuItem(label: '选择文件夹', icon: Icons.folder, onSelected: onSelectFolder),
    MenuItem(label: '文件信息', icon: Icons.info, onSelected: onShowInfo),
    MenuItem(label: '删除', icon: Icons.delete, onSelected: onDelete),
    // 可以在这里添加更多菜单项
  ];

  final menu = ContextMenu(
    entries: entries,
    position: Offset(right, top),
    padding: const EdgeInsets.all(8.0),
  );

  showContextMenu(context, contextMenu: menu);
}
