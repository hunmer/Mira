import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';

class LibraryGalleryItemActions extends StatelessWidget {
  final LibrariesPlugin plugin;
  final LibraryFile file;
  final Library library;
  final VoidCallback onDelete;

  const LibraryGalleryItemActions({
    required this.plugin,
    required this.file,
    required this.library,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.folder),
          title: const Text('设置文件夹'),
          onTap: () async {
            Navigator.pop(context);
            final result = await plugin.libraryUIController.showFolderSelector(
              library,
              context,
            );
            if (result != null && result.isNotEmpty) {
              await plugin.libraryController
                  .getLibraryInst(library)!
                  .setFileFolders(file.id, result.first.id);
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.tag),
          title: const Text('设置标签'),
          onTap: () async {
            Navigator.pop(context);
            final result = await plugin.libraryUIController.showTagSelector(
              library,
              context,
            );
            if (result != null && result.isNotEmpty) {
              await plugin.libraryController
                  .getLibraryInst(library)!
                  .setFileTags(file.id, result.map((item) => item.id).toList());
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('详细信息'),
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LibraryFileInformationView(file: file),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text('删除'),
          onTap: () {
            Navigator.pop(context);
            onDelete();
          },
        ),
      ],
    );
  }
}
