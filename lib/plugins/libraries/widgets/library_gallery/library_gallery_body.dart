import 'package:flutter/material.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/widgets/library_item.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_item_actions.dart';

class LibraryGalleryBody extends StatelessWidget {
  final LibrariesPlugin plugin;
  final Map<String, dynamic> filterOptions;
  final bool isSelectionMode;
  final Set<int> selectedFileIds;
  final Function(LibraryFile) onFileSelected;

  const LibraryGalleryBody({
    required this.plugin,
    required this.filterOptions,
    required this.isSelectionMode,
    required this.selectedFileIds,
    required this.onFileSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LibraryFile>>(
      future: plugin.libraryController.findFiles(query: filterOptions),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('加载文件失败: ${snapshot.error}'));
        }
        final files = snapshot.data ?? [];

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return LibraryItem(
              file: file,
              isSelected: isSelectionMode && selectedFileIds.contains(file.id),
              useThumbnail:
                  file.thumb != null ||
                  ['audio', 'video'].contains(getFileType(file.name)),
              displayFields: const {
                'title',
                'cover',
                'rating',
                'notes',
                'createdAt',
                'tags',
                'folder',
                'size',
              },
              onTap: () => onFileSelected(file),
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder:
                      (context) => LibraryGalleryItemActions(
                        plugin: plugin,
                        file: file,
                        onDelete:
                            () => plugin.libraryController.deleteFile(file.id),
                      ),
                );
              },
            );
          },
        );
      },
    );
  }
}
