import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_body.dart';
import 'area_selection_overlay.dart';

/// 简化的图库组件，专门用于处理区域选择通知
class SelectableGalleryGrid extends StatefulWidget {
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
  final Function(Set<int>)? onSelectionChanged;
  final AreaSelectionOverlayController? areaSelectionController;
  final VoidCallback? onStartAreaSelection; // 新增回调
  final VoidCallback? onEndAreaSelection; // 新增回调

  const SelectableGalleryGrid({
    Key? key,
    required this.plugin,
    required this.library,
    required this.items,
    required this.isSelectionMode,
    required this.isRecycleBin,
    required this.selectedFileIds,
    required this.displayFields,
    required this.onFileSelected,
    required this.onFileOpen,
    required this.imagesPerRow,
    this.scrollController,
    this.onSelectionChanged,
    this.areaSelectionController,
    this.onStartAreaSelection,
    this.onEndAreaSelection,
  }) : super(key: key);

  @override
  State<SelectableGalleryGrid> createState() => SelectableGalleryGridState();
}

class SelectableGalleryGridState extends State<SelectableGalleryGrid> {
  final Map<int, GlobalKey> _itemKeys = {};
  final Map<int, Rect> _itemRects = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _initializeKeys();

    // 监听滚动事件，滚动时更新所有项目的位置
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void didUpdateWidget(SelectableGalleryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _initializeKeys();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _initializeKeys() {
    _itemKeys.clear();
    _itemRects.clear();
    for (int i = 0; i < widget.items.length; i++) {
      _itemKeys[i] = GlobalKey();
    }
  }

  void _onScrollChanged() {
    // 滚动时更新所有项目位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAllItemRects();
    });
  }

  void _updateAllItemRects() {
    if (!mounted) return;

    final RenderBox? containerBox = context.findRenderObject() as RenderBox?;
    if (containerBox == null) return;

    for (int i = 0; i < widget.items.length; i++) {
      _updateItemRect(i, containerBox);
    }
  }

  void _updateItemRect(int index, RenderBox containerBox) {
    final key = _itemKeys[index];
    if (key?.currentContext != null) {
      final RenderBox renderBox =
          key!.currentContext!.findRenderObject() as RenderBox;

      try {
        final Offset position = renderBox.localToGlobal(
          Offset.zero,
          ancestor: containerBox,
        );
        final size = renderBox.size;
        _itemRects[index] = Rect.fromLTWH(
          position.dx,
          position.dy,
          size.width,
          size.height,
        );
      } catch (e) {
        // 如果获取位置失败，清除该项目的缓存位置
        _itemRects.remove(index);
      }
    }
  }

  /// 处理区域选择更新
  void handleAreaSelectionUpdate(Rect selectionArea) {
    if (!mounted) return;

    // 确保所有项目位置都是最新的
    _updateAllItemRects();

    final currentSelection = Set<int>.from(widget.selectedFileIds);

    for (int i = 0; i < widget.items.length; i++) {
      final itemRect = _itemRects[i];
      if (itemRect != null) {
        final file = widget.items[i];
        if (selectionArea.overlaps(itemRect)) {
          currentSelection.add(file.id);
        }
      }
    }

    // 通知外部选择状态变化
    widget.onSelectionChanged?.call(currentSelection);
  }

  /// 处理滚动请求
  void handleScrollRequest(double deltaY) {
    if (!mounted) return;

    final newOffset = (_scrollController.offset + deltaY).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(newOffset);
  }

  /// 清除所有选择
  void clearAllSelection() {
    widget.onSelectionChanged?.call({});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Column(
            children: [
              // 区域选择控制按钮 - 仅在桌面端显示
              if (widget.onStartAreaSelection != null &&
                  widget.onEndAreaSelection != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: '开始区域选择 (拖拽选择多个文件)',
                        child: ElevatedButton.icon(
                          onPressed: widget.onStartAreaSelection,
                          icon: const Icon(Icons.select_all, size: 16),
                          label: const Text('区域选择'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: '清除所有选择',
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onEndAreaSelection?.call();
                            clearAllSelection();
                          },
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('清除'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // // 主要内容
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = 2.0;
                    final crossAxisCount =
                        widget.imagesPerRow > 0
                            ? widget.imagesPerRow
                            : (constraints.maxWidth / 150).floor();

                    // 确保在构建完成后更新所有项目位置
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _updateAllItemRects();
                    });

                    return GridView.builder(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 0.8,
                      ),
                      padding: const EdgeInsets.all(2.0),
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final file = widget.items[index];

                        return Container(
                          key: _itemKeys[index],
                          child: LibraryGalleryBody(
                            plugin: widget.plugin,
                            library: widget.library,
                            isRecycleBin: widget.isRecycleBin,
                            displayFields: widget.displayFields,
                            items: [file],
                            isSelectionMode: widget.isSelectionMode,
                            selectedFileIds: widget.selectedFileIds,
                            onFileSelected: widget.onFileSelected,
                            onFileOpen: widget.onFileOpen,
                            imagesPerRow: 1,
                            scrollController: null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
