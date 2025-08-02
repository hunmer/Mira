import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: library_prefixes
import 'package:mira/core/utils/utils.dart' as Utils;
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
  final List<LibraryFile> items;
  final bool isSelectionMode;
  final bool isRecycleBin;
  final Set<int> selectedFileIds;
  final Set<String> displayFields;
  final Function(LibraryFile) onFileSelected;
  final Function(LibraryFile) onFileOpen;
  final int imagesPerRow;
  final ScrollController? scrollController;

  const LibraryGalleryBody({
    required this.isRecycleBin,
    required this.plugin,
    required this.displayFields,
    required this.library,
    required this.items,
    required this.isSelectionMode,
    required this.selectedFileIds,
    required this.onFileSelected,
    required this.onFileOpen,
    required this.imagesPerRow,
    this.scrollController,
    super.key,
  });

  @override
  State<LibraryGalleryBody> createState() => _LibraryGalleryBodyState();
}

class _LibraryGalleryBodyState extends State<LibraryGalleryBody> {
  late LibraryDataInterface? _libraryController;

  @override
  void initState() {
    super.initState();
    _libraryController = widget.plugin.libraryController.getLibraryInst(
      widget.library.id,
    );
  }

  void _showContextMenu(
    BuildContext context,
    LibraryFile file,
    Offset position,
  ) {
    LibraryFileContextMenu.show(
      context: context,
      plugin: widget.plugin,
      file: file,
      library: widget.library,
      isRecycleBin: widget.isRecycleBin,
      position: position,
      onDelete:
          () => _libraryController!.deleteFile(
            file.id,
            moveToRecycleBin: !widget.isRecycleBin,
          ),
      onRecover: () => _libraryController!.recoverFile(file.id),
      onShowInfo:
          () => showModalBottomSheet(
            context: context,
            builder:
                (context) => LibraryFileInformationView(
                  plugin: widget.plugin,
                  library: widget.library,
                  file: file,
                ),
          ),
      onSelectFolder: () async {
        final result = await widget.plugin.libraryUIController
            .showFolderSelector(widget.library, context);
        if (result != null && result.isNotEmpty) {
          await widget.plugin.libraryController
              .getLibraryInst(widget.library.id)!
              .setFileFolders(file.id, result.first.id);
        }
      },
      onSelectTag: () async {
        final result = await widget.plugin.libraryUIController.showTagSelector(
          widget.library,
          context,
        );
        if (result != null && result.isNotEmpty) {
          await widget.plugin.libraryController
              .getLibraryInst(widget.library.id)!
              .setFileTags(file.id, result.map((item) => item.id).toList());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Utils.isDesktop();
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8.0;
        final crossAxisCount =
            widget.imagesPerRow > 0
                ? widget.imagesPerRow
                : (constraints.maxWidth / 150).floor();

        return ScrollConfiguration(
          behavior:
              isDesktop
                  ? const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.invertedStylus,
                    },
                  )
                  : const ScrollBehavior(),
          child: GridView.builder(
            controller: widget.scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.8,
            ),
            padding: const EdgeInsets.all(8.0),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final file = widget.items[index];

              // 对于 web 平台，我们需要自定义手势处理
              if (kIsWeb) {
                return Listener(
                  onPointerDown: (PointerDownEvent event) {
                    // 在Web平台上检测右键点击
                    if (event.kind == PointerDeviceKind.mouse &&
                        event.buttons == kSecondaryMouseButton) {
                      // 立即显示右键菜单
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showContextMenu(context, file, event.position);
                      });
                    }
                  },
                  child: GestureDetector(
                    onTap: () {
                      widget.onFileSelected(file);
                    },
                    onDoubleTap: () {
                      widget.onFileOpen(file);
                    },
                    onSecondaryTapDown: (TapDownDetails details) {
                      // web 平台的右键点击备用处理
                      _showContextMenu(context, file, details.globalPosition);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        // 确保点击区域覆盖整个项目
                        width: double.infinity,
                        height: double.infinity,
                        child: LibraryItem(
                          file: file,
                          getTagTilte:
                              (tagId) => widget.plugin.foldersTagsController
                                  .getTagTitleById(widget.library.id, tagId),
                          getFolderTitle:
                              (folderId) => widget.plugin.foldersTagsController
                                  .getFolderTitleById(
                                    widget.library.id,
                                    folderId,
                                  ),
                          isSelected:
                              widget.isSelectionMode &&
                              widget.selectedFileIds.contains(file.id),
                          useThumbnail: file.thumb != null,
                          displayFields: widget.displayFields,
                          onTap: null, // 由外层 GestureDetector 处理
                          onDoubleTap: null, // 由外层 GestureDetector 处理
                          onLongPress: (_) {}, // 在 web 上禁用，提供空回调
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                // 桌面平台使用原有的处理方式
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
                  useThumbnail: file.thumb != null,
                  displayFields: widget.displayFields,
                  onTap: () {
                    final file = widget.items[index];
                    widget.onFileSelected(file);
                  },
                  onDoubleTap: () {
                    final file = widget.items[index];
                    widget.onFileOpen(file);
                  },
                  onLongPress: (details) {
                    final file = widget.items[index];
                    if (details.globalPosition == null) {
                      return;
                    }
                    _showContextMenu(context, file, details.globalPosition!);
                  },
                );
              }
            },
          ),
        );
      },
    );
  }
}
