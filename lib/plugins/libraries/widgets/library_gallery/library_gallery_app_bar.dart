import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:mira/plugins/libraries/l10n/libraries_localizations.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/widgets/file_filter_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_sort_dialog.dart';

class LibraryGalleryAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  bool isSelectionMode;
  final Set<int> selected;
  final bool isRecycleBin;
  final List<LibraryFile> Function() getItems;
  final Set<int> Function() getSelected;
  final Map<String, dynamic> filterOptions;
  final Function(Set<int>) onSelectionChanged;
  final Function(Map<String, dynamic>) onFilterChanged;
  final Function(bool) onToggleSelection;
  final VoidCallback onUpload;
  final double uploadProgress;
  final Set<String> displayFields;
  final Function(Set<String>) onDisplayFieldsChanged;
  final int imagesPerRow;
  final ValueChanged<int> onImagesPerRowChanged;
  final VoidCallback onRefresh;
  final Map<String, dynamic> sortOptions;
  final ValueChanged<Map<String, dynamic>> onSortChanged;

  LibraryGalleryAppBar({
    required this.title,
    this.isSelectionMode = false,
    this.selected = const <int>{},
    required this.getItems,
    required this.getSelected,
    required this.filterOptions,
    required this.isRecycleBin,
    required this.onSelectionChanged,
    required this.onFilterChanged,
    required this.onToggleSelection,
    required this.onUpload,
    required this.uploadProgress,
    required this.displayFields,
    required this.onDisplayFieldsChanged,
    required this.imagesPerRow,
    required this.sortOptions,
    required this.onImagesPerRowChanged,
    required this.onRefresh,
    required this.onSortChanged,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<LibraryGalleryAppBar> createState() => _LibraryGalleryAppBarState();
}

class _LibraryGalleryAppBarState extends State<LibraryGalleryAppBar> {
  late final ValueNotifier<int> _imageRows;
  late final ValueNotifier<Set<String>> _fields;
  late final ValueNotifier<Map<String, dynamic>> _filterOptions;

  @override
  void initState() {
    super.initState();
    _imageRows = ValueNotifier(widget.imagesPerRow);
    _fields = ValueNotifier(widget.displayFields);
    _filterOptions = ValueNotifier(widget.filterOptions);
  }

  @override
  void dispose() {
    _imageRows.dispose();
    _fields.dispose();
    _filterOptions.dispose();
    super.dispose();
  }

  void _toggleSelectAll() {
    widget.onSelectionChanged(
      widget.getSelected().isEmpty
          ? widget.getItems().map((f) => f.id).toSet()
          : <int>{},
    );
  }

  void _exitSelectionMode() {
    widget.onToggleSelection(false);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LibrariesLocalizations.of(context);
    if (localizations == null) return Container();

    return SizedBox(
      width: 60,
      child: Column(
        children:
            widget.isSelectionMode
                ? [
                  Tooltip(
                    message: '全选',
                    child: IconButton(
                      icon: const Icon(Icons.select_all),
                      onPressed: _toggleSelectAll,
                    ),
                  ),
                  // 反选
                  Tooltip(
                    message: '反选',
                    child: IconButton(
                      icon: const Icon(Icons.check_box),
                      onPressed: () {
                        setState(() {
                          final allIds =
                              widget.getItems().map((f) => f.id).toSet();
                          widget.onSelectionChanged(
                            allIds.difference(widget.getSelected()).toSet(),
                          );
                        });
                      },
                    ),
                  ),
                  // 清空选择
                  Tooltip(
                    message: '清空选择',
                    child: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.onSelectionChanged(<int>{});
                      },
                    ),
                  ),
                  // 退出选择模式
                  Tooltip(
                    message: '退出选择模式',
                    child: IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      onPressed: () {
                        setState(() {
                          widget.isSelectionMode = false;
                        });
                        _exitSelectionMode();
                      },
                    ),
                  ),
                ]
                : [
                  Stack(
                    children: [
                      Tooltip(
                        message: '过滤',
                        child: IconButton(
                          icon: const Icon(Icons.filter_alt),
                          onPressed: () async {
                            final filterOptions =
                                await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder:
                                      (context) => FileFilterDialog(
                                        filterOptions: _filterOptions.value,
                                      ),
                                );
                            if (filterOptions != null) {
                              _filterOptions.value = filterOptions;
                              widget.onFilterChanged(filterOptions);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Tooltip(
                    message: '排序',
                    child: IconButton(
                      icon: Icon(Icons.filter_list),
                      onPressed: () async {
                        widget.onSortChanged(
                          await showDialog(
                            context: context,
                            builder:
                                (context) => LibrarySortDialog(
                                  initialSortOptions: widget.sortOptions,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                  Tooltip(
                    message: '选择模式',
                    child: IconButton(
                      icon: Icon(Icons.check_box),
                      onPressed: () {
                        setState(() {
                          widget.isSelectionMode = !widget.isSelectionMode;
                        });
                        widget.onToggleSelection(widget.isSelectionMode);
                      },
                    ),
                  ),
                  if (!widget.isRecycleBin)
                    Stack(
                      children: [
                        Tooltip(
                          message: '上传文件',
                          child: IconButton(
                            icon: Icon(Icons.file_upload),
                            onPressed: widget.onUpload,
                          ),
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
                  Tooltip(
                    message: '网格视图设置',
                    child: IconButton(
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
                                        '每行图片数量: ${_imageRows.value == 0 ? "自动" : _imageRows.value}',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                    ),
                                    FlutterSlider(
                                      values: [_imageRows.value.toDouble()],
                                      max: 20,
                                      min: 0,
                                      onDragging: (
                                        handlerIndex,
                                        lowerValue,
                                        upperValue,
                                      ) {
                                        final count = lowerValue.toInt();
                                        _imageRows.value = count;
                                        widget.onImagesPerRowChanged(count);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                        );
                      },
                    ),
                  ),
                  Tooltip(
                    message: '刷新',
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: widget.onRefresh,
                    ),
                  ),
                  Tooltip(
                    message: '显示字段设置',
                    child: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: [
                                      for (final field in [
                                        'title',
                                        'rating',
                                        'notes',
                                        'createdAt',
                                        'tags',
                                        'folder',
                                        'size',
                                      ])
                                        StatefulBuilder(
                                          builder: (context, setState) {
                                            return CheckboxListTile(
                                              title: Text(field),
                                              value: _fields.value.contains(
                                                field,
                                              ),
                                              onChanged: (checked) {
                                                setState(() {
                                                  if (checked!) {
                                                    _fields.value.add(field);
                                                  } else {
                                                    _fields.value.remove(field);
                                                  }
                                                  widget.onDisplayFieldsChanged(
                                                    Set<String>.from(
                                                      _fields.value,
                                                    ),
                                                  );
                                                });
                                              },
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                        );
                      },
                    ),
                  ),
                ],
      ),
    );
  }
}
