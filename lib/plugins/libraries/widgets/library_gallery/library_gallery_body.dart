import 'package:flutter/material.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/controllers/library_data_controller.dart';
import 'package:mira/plugins/libraries/controllers/library_data_interface.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/library_item.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_item_actions.dart';

class LibraryGalleryBody extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final Map<String, dynamic> filterOptions;
  final bool isSelectionMode;
  final Set<int> selectedFileIds;
  final Function(LibraryFile) onFileSelected;
  final Function(LibraryFile) onFileOpen;

  const LibraryGalleryBody({
    required this.plugin,
    required this.library,
    required this.filterOptions,
    required this.isSelectionMode,
    required this.selectedFileIds,
    required this.onFileSelected,
    required this.onFileOpen,
    super.key,
  });

  @override
  State<LibraryGalleryBody> createState() => _LibraryGalleryBodyState();
}

class _LibraryGalleryBodyState extends State<LibraryGalleryBody> {
  late ValueNotifier<List<LibraryFile>> _filesNotifier;
  late LibraryDataInterface _libraryController;

  @override
  void initState() {
    super.initState();
    _libraryController =
        widget.plugin.libraryController.getLibraryInst(widget.library)!;
    _filesNotifier = ValueNotifier<List<LibraryFile>>([]);
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final files = await _libraryController.findFiles(
      query: widget.filterOptions,
    );
    if (mounted) {
      _filesNotifier.value = files;
    }
  }

  @override
  void dispose() {
    _filesNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LibraryFile>>(
      valueListenable: _filesNotifier,
      builder: (context, files, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = 150.0;
            final spacing = 8.0;
            final crossAxisCount =
                (constraints.maxWidth / (itemWidth + spacing)).floor();

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 0.8,
              ),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                return LibraryItem(
                  key: ValueKey(file.id), // 添加key避免不必要的重建
                  file: file,
                  getTagTilte:
                      (tagId) => widget.plugin.foldersTagsController
                          .getTagTitleById(widget.library.id, tagId),
                  getFolderTitle:
                      (folderId) => widget.plugin.foldersTagsController
                          .getFolderTitleById(widget.library.id, folderId),
                  isSelected:
                      widget.isSelectionMode &&
                      widget.selectedFileIds.contains(file.id),
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
                  onTap: () => widget.onFileSelected(file),
                  onDoubleTap: () => widget.onFileOpen(file),
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder:
                          (context) => LibraryGalleryItemActions(
                            plugin: widget.plugin,
                            file: file,
                            library: widget.library,
                            onDelete:
                                () => _libraryController.deleteFile(file.id),
                          ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
