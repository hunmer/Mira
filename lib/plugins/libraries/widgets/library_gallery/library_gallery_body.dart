import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/controllers/library_data_interface.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_file_context_menu.dart'
    // ignore: library_prefixes
    as LibraryFileContextMenu;
import 'package:mira/plugins/libraries/widgets/library_item.dart';

class LibraryGalleryBody extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final ValueNotifier<List<LibraryFile>> items;
  final bool isSelectionMode;
  final Set<int> selectedFileIds;
  final Set<String> displayFields;
  final Function(LibraryFile) onFileSelected;
  final Function(LibraryFile) onFileOpen;
  final int imagesPerRow;

  const LibraryGalleryBody({
    required this.plugin,
    required this.displayFields,
    required this.library,
    required this.items,
    required this.isSelectionMode,
    required this.selectedFileIds,
    required this.onFileSelected,
    required this.onFileOpen,
    required this.imagesPerRow,
    super.key,
  });

  @override
  State<LibraryGalleryBody> createState() => _LibraryGalleryBodyState();
}

class _LibraryGalleryBodyState extends State<LibraryGalleryBody> {
  late LibraryDataInterface _libraryController;
  @override
  void initState() {
    super.initState();
    _libraryController =
        widget.plugin.libraryController.getLibraryInst(widget.library)!;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8.0;
        final crossAxisCount =
            widget.imagesPerRow > 0
                ? widget.imagesPerRow
                : (constraints.maxWidth / 150).floor();

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.8,
          ),
          itemCount: widget.items.value.length,
          itemBuilder: (context, index) {
            final file = widget.items.value[index];
            return LibraryItem(
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
              displayFields: widget.displayFields,
              onTap: () {
                final file = widget.items.value[index];
                isMobile
                    ? widget.onFileOpen(file)
                    : widget.onFileSelected(file);
              },
              onDoubleTap: () {
                final file = widget.items.value[index];
                isMobile
                    ? widget.onFileSelected(file)
                    : widget.onFileOpen(file);
              },
              onLongPress: (details) {
                final file = widget.items.value[index];
                LibraryFileContextMenu.show(
                  context: context,
                  plugin: widget.plugin,
                  file: file,
                  library: widget.library,
                  position: details.globalPosition,
                  onDelete: () => _libraryController.deleteFile(file.id),
                  onShowInfo:
                      () => showModalBottomSheet(
                        context: context,
                        builder:
                            (context) => LibraryFileInformationView(file: file),
                      ),
                  onSelectFolder: () async {
                    final result = await widget.plugin.libraryUIController
                        .showFolderSelector(widget.library, context);
                    if (result != null && result.isNotEmpty) {
                      await widget.plugin.libraryController
                          .getLibraryInst(widget.library)!
                          .setFileFolders(file.id, result.first.id);
                    }
                  },
                  onSelectTag: () async {
                    final result = await widget.plugin.libraryUIController
                        .showTagSelector(widget.library, context);
                    if (result != null && result.isNotEmpty) {
                      await widget.plugin.libraryController
                          .getLibraryInst(widget.library)!
                          .setFileTags(
                            file.id,
                            result.map((item) => item.id).toList(),
                          );
                    }
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
