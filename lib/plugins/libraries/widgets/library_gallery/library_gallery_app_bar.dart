import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:mira/plugins/libraries/l10n/libraries_localizations.dart';

class LibraryGalleryAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final bool isSelectionMode;
  final bool isRecycleBin;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onExitSelection;
  final VoidCallback onFilter;
  final VoidCallback onEnterSelection;
  final VoidCallback onUpload;
  final double uploadProgress;
  final Set<String> displayFields;
  final ValueChanged<Set<String>> onDisplayFieldsChanged;
  final int imagesPerRow;
  final ValueChanged<int> onImagesPerRowChanged;
  final VoidCallback onRefresh;
  final VoidCallback toggleSidebar;

  const LibraryGalleryAppBar({
    required this.title,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.isRecycleBin,
    required this.onSelectAll,
    required this.onExitSelection,
    required this.onFilter,
    required this.onEnterSelection,
    required this.onUpload,
    required this.uploadProgress,
    required this.displayFields,
    required this.onDisplayFieldsChanged,
    required this.imagesPerRow,
    required this.onImagesPerRowChanged,
    required this.onRefresh,
    required this.toggleSidebar,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<LibraryGalleryAppBar> createState() => _LibraryGalleryAppBarState();
}

class _LibraryGalleryAppBarState extends State<LibraryGalleryAppBar> {
  late final ValueNotifier<int> _imageRows;

  @override
  void initState() {
    super.initState();
    _imageRows = ValueNotifier(widget.imagesPerRow);
  }

  @override
  void dispose() {
    _imageRows.dispose();
    super.dispose();
  }

  void _handleImagesPerRowChange(int count) {
    _imageRows.value = count;
    widget.onImagesPerRowChanged(count);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LibrariesLocalizations.of(context);
    if (localizations == null) return Container();

    return ValueListenableBuilder(
      valueListenable: _imageRows,
      builder: (context, imageRows, _) {
        return AppBar(
          title: Text(
            widget.isSelectionMode
                ? '已选择 ${widget.selectedCount} 项'
                : widget.title,
          ),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: widget.toggleSidebar,
          ),
          actions:
              widget.isSelectionMode
                  ? [
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      onPressed: widget.onSelectAll,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onExitSelection,
                    ),
                  ]
                  : [
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: widget.onFilter,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_box),
                      onPressed: widget.onEnterSelection,
                    ),
                    if (!widget.isRecycleBin)
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(Icons.file_upload),
                            onPressed: widget.onUpload,
                          ),
                          if (widget.uploadProgress > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child:
                                    widget.uploadProgress == 1
                                        ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.green,
                                        )
                                        : Text(
                                          '${widget.uploadProgress * 100}%',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                              ),
                            ),
                        ],
                      ),
                    IconButton(
                      icon: const Icon(Icons.grid_view),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder:
                              (context) => Container(
                                padding: const EdgeInsets.all(16),
                                height: 250,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        '每行图片数量: ${imageRows == 0 ? "自动" : imageRows}',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                    ),
                                    FlutterSlider(
                                      values: [
                                        imageRows == 0
                                            ? 3.0
                                            : imageRows.toDouble(),
                                      ],
                                      max: 20,
                                      min: 0,
                                      onDragging: (
                                        handlerIndex,
                                        lowerValue,
                                        upperValue,
                                      ) {
                                        _handleImagesPerRowChange(
                                          lowerValue.toInt(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: widget.onRefresh,
                    ),
                  ],
        );
      },
    );
  }
}
