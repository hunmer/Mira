import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/widgets/folder_tree_dialog.dart';
import 'package:mira/widgets/tree_view.dart';

class LibraryUIController {
  final LibrariesPlugin _plugin;

  LibraryUIController(this._plugin);

  Future<List<LibraryFolder>> showFolderSelector(
    Library library,
    BuildContext context,
  ) async {
    final folders =
        await _plugin.libraryController.getLibraryInst(library)!.getFolders();
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder:
          (context) => AsyncTreeViewDialog(
            title: '选择文件夹',
            library: library,
            selected: null,
            type: 'folders',
            onSelectionChanged: (ids) => {},
            items: folders.map((f) => TreeItem.fromMap(f)).toList(),
          ),
    );
    if (result == null) return [];
    return result.map((item) => LibraryFolder.fromMap(item)).toList();
  }

  Future<List<LibraryTag>> showTagSelector(
    Library library,
    BuildContext context,
  ) async {
    final tags =
        await _plugin.libraryController.getLibraryInst(library)!.getTags();
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder:
          (context) => AsyncTreeViewDialog(
            title: '选择标签',
            library: library,
            selected: null,
            type: 'tags',
            onSelectionChanged: (ids) => {},
            items: tags.map((f) => TreeItem.fromMap(f)).toList(),
          ),
    );
    if (result == null) return [];
    return result.map((item) => LibraryTag.fromMap(item)).toList();
  }
}
