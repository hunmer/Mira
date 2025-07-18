import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/widgets/async_tree_view_dialog.dart';
import 'package:mira/widgets/tree_view.dart';

class LibraryUIController {
  final LibrariesPlugin _plugin;

  LibraryUIController(this._plugin);

  Future<List<LibraryFolder>> showFolderSelector(BuildContext context) async {
    final folders = await _plugin.libraryController.getFolders();
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder:
          (context) => AsyncTreeViewDialog(
            title: '选择文件夹',
            selected: null,
            type: 'folders',
            items: folders.map((f) => TreeItem.fromMap(f)).toList(),
          ),
    );
    if (result == null) return [];
    return result.map((item) => LibraryFolder.fromMap(item)).toList();
  }

  Future<List<LibraryTag>> showTagSelector(BuildContext context) async {
    final tags = await _plugin.libraryController.getTags();
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder:
          (context) => AsyncTreeViewDialog(
            title: '选择标签',
            selected: null,
            type: 'tags',
            items: tags.map((f) => TreeItem.fromMap(f)).toList(),
          ),
    );
    if (result == null) return [];
    return result.map((item) => LibraryTag.fromMap(item)).toList();
  }
}
