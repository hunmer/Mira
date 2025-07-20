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
  required Offset position,
  required VoidCallback onDelete,
  required VoidCallback onSelectTag,
  required VoidCallback onSelectFolder,
  required VoidCallback onShowInfo,
}) {
  final entries = <ContextMenuEntry>[
    MenuItem(label: '设置标签', icon: Icons.tag, onSelected: onSelectTag),
    MenuItem(label: '选择文件夹', icon: Icons.folder, onSelected: onSelectFolder),
    MenuItem(label: '文件信息', icon: Icons.info, onSelected: onShowInfo),
    MenuItem(label: '删除', icon: Icons.delete, onSelected: onDelete),
  ];
  final menu = ContextMenu(
    entries: entries,
    position: position,
    padding: const EdgeInsets.all(8.0),
  );

  showContextMenu(context, contextMenu: menu);
}
