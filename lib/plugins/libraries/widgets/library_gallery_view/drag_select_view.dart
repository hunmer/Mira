import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:waterfall_flow/waterfall_flow.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/library_item.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_file_context_menu.dart'
    as library_file_context_menu;
import 'package:mira/plugins/libraries/controllers/library_data_interface.dart';
import 'selectable_item.dart';

/// 定义视图类型枚举
enum DragSelectViewType {
  grid,
  waterfall,
  // 未来可以添加其他类型，如 list, mosaic 等
}

/// 自定义滚动物理配置，允许滚轮滚动但禁用拖拽滚动
class DesktopScrollPhysics extends ScrollPhysics {
  const DesktopScrollPhysics({super.parent});

  @override
  DesktopScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return DesktopScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    // 只允许通过滚轮等非拖拽方式进行滚动
    return true;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // 禁用惯性滚动
    return null;
  }

  @override
  double get dragStartDistanceMotionThreshold => double.infinity;
}

/// 统一的拖拽选择视图组件
class DragSelectView extends StatefulWidget {
  final DragSelectViewType viewType;
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
  final Function(LibraryFile) onToggleSelected;
  final Function(Set<int>)? onSelectionChanged;

  const DragSelectView({
    super.key,
    this.viewType = DragSelectViewType.grid,
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
    required this.onToggleSelected,
    this.scrollController,
    this.onSelectionChanged,
  });

  @override
  State<DragSelectView> createState() => _DragSelectViewState();
}

class _DragSelectViewState extends State<DragSelectView> {
  late DragSelectGridViewController _controller;
  late ScrollController _scrollController;
  late LibraryDataInterface? _libraryController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _controller = DragSelectGridViewController();
    _controller.addListener(_onSelectionChanged);
    _libraryController = widget.plugin.libraryController.getLibraryInst(
      widget.library.id,
    );

    // 初始化选中状态
    _updateControllerSelection();
  }

  @override
  void didUpdateWidget(DragSelectView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFileIds != widget.selectedFileIds) {
      _updateControllerSelection();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onSelectionChanged);
    _controller.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _updateControllerSelection() {
    // 将文件ID转换为索引
    final selectedIndices = <int>{};
    for (int i = 0; i < widget.items.length; i++) {
      if (widget.selectedFileIds.contains(widget.items[i].id)) {
        selectedIndices.add(i);
      }
    }
    _controller.value = Selection(selectedIndices);
  }

  void _onSelectionChanged() {
    // 将索引转换为文件ID
    final selectedFileIds = <int>{};
    for (int index in _controller.value.selectedIndexes) {
      if (index >= 0 && index < widget.items.length) {
        selectedFileIds.add(widget.items[index].id);
      }
    }
    widget.onSelectionChanged?.call(selectedFileIds);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.viewType) {
      case DragSelectViewType.grid:
        return _buildGridView();
      case DragSelectViewType.waterfall:
        return _buildWaterfallView();
    }
  }

  Widget _buildGridView() {
    // 计算网格代理
    final SliverGridDelegate gridDelegate =
        widget.imagesPerRow > 0
            ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.imagesPerRow,
              crossAxisSpacing: 2.0,
              mainAxisSpacing: 2.0,
              childAspectRatio: 0.8,
            )
            : SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150.0, // 固定宽度150像素
              crossAxisSpacing: 2.0,
              mainAxisSpacing: 2.0,
              childAspectRatio: 0.8,
            );

    return DragSelectGridView(
      gridController: _controller,
      scrollController: _scrollController,
      // 桌面端使用自定义滚动物理：允许滚轮滚动，禁用拖拽滚动
      physics:
          kIsWeb ||
                  defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.macOS ||
                  defaultTargetPlatform == TargetPlatform.linux
              ? const DesktopScrollPhysics()
              : const ClampingScrollPhysics(),
      itemCount: widget.items.length,
      itemBuilder: (context, index, selected) {
        final file = widget.items[index];
        return _buildSelectableItem(file, index, selected);
      },
      gridDelegate: gridDelegate,
      padding: const EdgeInsets.all(2.0),
    );
  }

  Widget _buildWaterfallView() {
    return WaterfallFlow.builder(
      controller: _scrollController,
      physics:
          kIsWeb ||
                  defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.macOS ||
                  defaultTargetPlatform == TargetPlatform.linux
              ? const DesktopScrollPhysics()
              : const ClampingScrollPhysics(),
      itemCount: widget.items.length,
      itemBuilder: (BuildContext context, int index) {
        final file = widget.items[index];
        final isSelected = widget.selectedFileIds.contains(file.id);
        return _buildSelectableWaterfallItem(file, index, isSelected);
      },
      gridDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.imagesPerRow > 0 ? widget.imagesPerRow : 3,
        crossAxisSpacing: 2.0,
        mainAxisSpacing: 2.0,
      ),
      padding: const EdgeInsets.all(2.0),
    );
  }

  /// 显示右键菜单
  void _showContextMenu(
    BuildContext context,
    LibraryFile file,
    Offset position,
  ) {
    library_file_context_menu.show(
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
          await _libraryController!.setFileTags(
            file.id,
            result.map((tag) => tag.id).toList(),
          );
        }
      },
    );
  }

  /// 构建可选择的项目组件
  Widget _buildSelectableItem(LibraryFile file, int index, bool selected) {
    return SelectableItem(
      index: index,
      selected: selected,
      child:
          kIsWeb
              ? Listener(
                onPointerDown: (event) {
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
                    if (!widget.isSelectionMode) {
                      widget.onFileSelected(file);
                    } else {
                      widget.onToggleSelected(file);
                    }
                  },
                  onDoubleTap: () => widget.onFileOpen(file),
                  onSecondaryTapDown: (TapDownDetails details) {
                    // web 平台的右键点击备用处理
                    _showContextMenu(context, file, details.globalPosition);
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: SizedBox(
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
                        useThumbnail: file.thumb != null,
                        displayFields: widget.displayFields,
                      ),
                    ),
                  ),
                ),
              )
              : LibraryItem(
                file: file,
                getTagTilte:
                    (tagId) => widget.plugin.foldersTagsController
                        .getTagTitleById(widget.library.id, tagId),
                getFolderTitle:
                    (folderId) => widget.plugin.foldersTagsController
                        .getFolderTitleById(widget.library.id, folderId),
                useThumbnail: file.thumb != null,
                displayFields: widget.displayFields,
                onTap: () {
                  if (!widget.isSelectionMode) {
                    widget.onFileSelected(file);
                  } else {
                    widget.onToggleSelected(file);
                  }
                },
                onDoubleTap: () => widget.onFileOpen(file),
                onLongPress: (details) {
                  if (details.globalPosition == null) {
                    return;
                  }
                  _showContextMenu(context, file, details.globalPosition!);
                },
              ),
    );
  }

  /// 构建瀑布流的可选择项目组件
  Widget _buildSelectableWaterfallItem(
    LibraryFile file,
    int index,
    bool selected,
  ) {
    // 为瀑布流项目生成随机高度（模拟真实瀑布流效果）
    final baseHeight = 200.0;
    final randomHeight = baseHeight + (index % 3) * 50.0; // 200-300的随机高度

    return GestureDetector(
      onTap: () {
        if (!widget.isSelectionMode) {
          widget.onFileSelected(file);
        } else {
          widget.onToggleSelected(file);
          // 手动触发选择状态更新
          final newSelected = Set<int>.from(widget.selectedFileIds);
          if (selected) {
            newSelected.remove(file.id);
          } else {
            newSelected.add(file.id);
          }
          widget.onSelectionChanged?.call(newSelected);
        }
      },
      onDoubleTap: () => widget.onFileOpen(file),
      onLongPress: () {
        // 长按进入选择模式并选中当前项
        if (!widget.isSelectionMode) {
          final newSelected = {file.id};
          widget.onSelectionChanged?.call(newSelected);
        }
      },
      onSecondaryTapDown: (TapDownDetails details) {
        _showContextMenu(context, file, details.globalPosition);
      },
      child: Container(
        height: randomHeight,
        decoration: BoxDecoration(
          border:
              selected
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child:
            kIsWeb
                ? Listener(
                  onPointerDown: (event) {
                    if (event.kind == PointerDeviceKind.mouse &&
                        event.buttons == kSecondaryMouseButton) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showContextMenu(context, file, event.position);
                      });
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: SizedBox(
                      height: randomHeight,
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
                        useThumbnail: file.thumb != null,
                        displayFields: widget.displayFields,
                      ),
                    ),
                  ),
                )
                : SizedBox(
                  height: randomHeight,
                  child: LibraryItem(
                    file: file,
                    getTagTilte:
                        (tagId) => widget.plugin.foldersTagsController
                            .getTagTitleById(widget.library.id, tagId),
                    getFolderTitle:
                        (folderId) => widget.plugin.foldersTagsController
                            .getFolderTitleById(widget.library.id, folderId),
                    useThumbnail: file.thumb != null,
                    displayFields: widget.displayFields,
                    onLongPress: (details) {
                      if (details.globalPosition != null) {
                        _showContextMenu(
                          context,
                          file,
                          details.globalPosition!,
                        );
                      }
                    },
                  ),
                ),
      ),
    );
  }
}
