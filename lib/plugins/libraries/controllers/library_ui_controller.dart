import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/widgets/folder_tree_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_dock_item.dart';
import 'package:mira/plugins/libraries/widgets/library_list_view.dart';
import 'package:mira/widgets/checkable_treeview/treeview.dart';
import 'package:mira/widgets/tree_view.dart';

class LibraryUIController {
  final LibrariesPlugin _plugin;

  LibraryUIController(this._plugin);

  Future<List<LibraryFolder>> showFolderSelector(
    Library library,
    BuildContext context, {
    List<int>? selectedFileIds,
  }) async {
    final folders =
        await _plugin.libraryController
            .getLibraryInst(library.id)!
            .getAllFolders();
    final result = await showDialog<List<TreeItem>>(
      context: context,
      builder:
          (context) => AsyncTreeViewDialog(
            title:
                selectedFileIds != null && selectedFileIds.isNotEmpty
                    ? '为 ${selectedFileIds.length} 个文件选择文件夹'
                    : '选择文件夹',
            library: library,
            selected: null,
            type: 'folders',
            selectionMode: TreeSelectionMode.multiple,
            items: folders.map((f) => TreeItem.fromMap(f)).toList(),
          ),
    );
    if (result == null) return [];
    return result.map((item) => LibraryFolder.fromMap(item.toMap())).toList();
  }

  Future<List<LibraryTag>> showTagSelector(
    Library library,
    BuildContext context, {
    TreeSelectionMode? selectionMode,
    List<int>? selectedFileIds,
  }) async {
    final tags =
        await _plugin.libraryController
            .getLibraryInst(library.id)!
            .getAllTags();
    final result = await showDialog<List<TreeItem>>(
      context: context,
      builder:
          (context) => AsyncTreeViewDialog(
            title:
                selectedFileIds != null && selectedFileIds.isNotEmpty
                    ? '为 ${selectedFileIds.length} 个文件选择标签'
                    : '选择标签',
            library: library,
            selectionMode: selectionMode ?? TreeSelectionMode.single,
            selected: null,
            type: 'tags',
            items: tags.map((f) => TreeItem.fromMap(f)).toList(),
          ),
    );
    if (result == null) return [];
    return result.map((item) => LibraryTag.fromMap(item.toMap())).toList();
  }

  Future<void> openLibrary(BuildContext context) async {
    final libraries = _plugin.dataController.libraries;
    final itemCount = libraries.length;
    if (itemCount == 1) {
      LibraryDockItem.addTab(libraries.first);
      return;
    }
    final selectedLibrary = await showDialog<Library>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Library'),
            content: SizedBox(
              width: double.maxFinite,
              child: LibraryListView(
                onSelected: (library) {
                  Navigator.pop(context, library);
                },
              ),
            ),
          ),
    );
    if (selectedLibrary != null) {
      LibraryDockItem.addTab(selectedLibrary);
    }
  }
}
