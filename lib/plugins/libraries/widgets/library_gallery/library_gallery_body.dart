import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/controllers/library_data_interface.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_file_context_menu.dart'
    as LibraryFileContextMenu;
import 'package:mira/plugins/libraries/widgets/library_item.dart';

class LibraryGalleryBody extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final Map<String, dynamic> filterOptions;
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
    required this.filterOptions,
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
    final isMobile = Platform.isAndroid || Platform.isIOS;
    return ValueListenableBuilder<List<LibraryFile>>(
      valueListenable: _filesNotifier,
      builder: (context, files, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = 150.0;
            final spacing = 8.0;
            final crossAxisCount = widget.imagesPerRow;

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
                final itemKey = GlobalKey();
                return LibraryItem(
                  key: itemKey, // 使用GlobalKey获取组件位置
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
                  onTap:
                      () =>
                          isMobile
                              ? widget.onFileOpen(file)
                              : widget.onFileSelected(file),
                  onDoubleTap:
                      () =>
                          isMobile
                              ? widget.onFileSelected(file)
                              : widget.onFileOpen(file),
                  onLongPress: () {
                    LibraryFileContextMenu.show(
                      context: context,
                      plugin: widget.plugin,
                      file: file,
                      library: widget.library,
                      tabKey: itemKey,
                      onDelete: () => _libraryController.deleteFile(file.id),
                      onShowInfo:
                          () => showModalBottomSheet(
                            context: context,
                            builder:
                                (context) =>
                                    LibraryFileInformationView(file: file),
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
      },
    );
  }
}
