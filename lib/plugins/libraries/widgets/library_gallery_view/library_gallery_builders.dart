import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';
import 'package:number_pagination/number_pagination.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_app_bar.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_body.dart';
import 'package:mira/plugins/libraries/widgets/library_sidebar_view.dart';
import 'library_gallery_events.dart';
import 'library_gallery_state.dart';
import 'area_selection_overlay.dart';
import 'selectable_gallery_grid.dart';

/// 图库视图的UI构建器类
class LibraryGalleryBuilders {
  final LibraryGalleryState state;
  final LibraryGalleryEvents events;
  final LibrariesPlugin plugin;
  final Library library;
  final String tabId;
  final BuildContext context;
  final VoidCallback? onShowDropDialog;
  final Function(LibraryFile)? onFileOpen;

  LibraryGalleryBuilders({
    required this.state,
    required this.events,
    required this.plugin,
    required this.library,
    required this.tabId,
    required this.context,
    this.onShowDropDialog,
    this.onFileOpen,
  });

  /// 构建响应式布局
  Widget buildResponsiveLayout(
    SizingInformation sizingInformation,
    bool isRecycleBin,
  ) {
    switch (sizingInformation.deviceScreenType) {
      case DeviceScreenType.mobile:
        return buildMainContent(
          isRecycleBin,
          sizingInformation.screenSize.width,
        );

      case DeviceScreenType.tablet:
        return Row(
          children: [
            Flexible(
              flex: 1,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: buildSidebarSection(
                    sizingInformation.screenSize.width,
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 6,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: buildMainContent(
                    isRecycleBin,
                    sizingInformation.screenSize.width,
                  ),
                ),
              ),
            ),
          ],
        );

      case DeviceScreenType.desktop:
        return Row(
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(6),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: buildQuickActions(),
              ),
            ),
            Flexible(
              flex: 1,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: buildSidebarSection(
                    sizingInformation.screenSize.width,
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 6,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: buildMainContent(
                    isRecycleBin,
                    sizingInformation.screenSize.width,
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 1,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: buildMoreDetailsPage(),
                ),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(6),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: buildAppBarActions(),
              ),
            ),
          ],
        );

      case DeviceScreenType.watch:
      default:
        return buildMainContent(
          isRecycleBin,
          sizingInformation.screenSize.width,
        );
    }
  }

  /// 构建应用栏操作
  Widget buildAppBarActions() {
    return LibraryGalleryAppBar(
      title: library.name,
      getItems: () => state.items.value,
      getSelected: () => state.selectedFileIds.value,
      isSelectionMode: state.isSelectionModeNotifier.value,
      onToggleSelection:
          (bool enable) => state.isSelectionModeNotifier.value = enable,
      isRecycleBin: state.tabData!.isRecycleBin,
      onSelectionChanged: (Set<int> selected) {
        state.selectedFileIds.value = selected;
      },
      filterOptions: Map<String, dynamic>.from(
        state.filterOptionsNotifier.value,
      ),
      onFilterChanged: (Map<String, dynamic> filterOptions) {
        if (filterOptions != null &&
            state.filterOptionsNotifier.value != filterOptions) {
          state.filterOptionsNotifier.value = filterOptions;
          state.tabManager.updateFilter(tabId, filterOptions);
        }
      },
      onUpload: onShowDropDialog ?? () {},
      uploadProgress: state.uploadProgressNotifier.value,
      displayFields: Set<String>.from(state.displayFieldsNotifier.value),
      onDisplayFieldsChanged: (Set<String> fields) {
        state.displayFieldsNotifier.value = fields;
        state.tabManager.setStoreValue(tabId, 'displayFields', fields);
      },
      imagesPerRow: state.imagesPerRowNotifier.value,
      onImagesPerRowChanged: (count) {
        state.imagesPerRowNotifier.value = count;
        state.tabManager.setStoreValue(tabId, 'imagesPerRow', count);
      },
      onRefresh: events.refresh,
      sortOptions: state.sortOptionsNotifier.value,
      onSortChanged: (sortOptions) {
        if (sortOptions != null &&
            state.sortOptionsNotifier.value != sortOptions) {
          state.sortOptionsNotifier.value = sortOptions;
          state.tabManager.setStoreValue(tabId, 'sortOptions', sortOptions);
          events.loadFiles();
        }
      },
    );
  }

  /// 构建快捷操作栏
  Widget buildQuickActions() {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Tooltip(
            message: '显示/隐藏侧边栏',
            child: IconButton(
              icon: Icon(Icons.menu),
              onPressed: events.toggleSidebar,
            ),
          ),
          Tooltip(
            message: '文件夹列表',
            child: IconButton(
              icon: Icon(Icons.folder),
              onPressed: () async {
                final result = await plugin.libraryUIController
                    .showFolderSelector(library, context);
                if (result != null && result.isNotEmpty) {}
              },
            ),
          ),
          Tooltip(
            message: '标签列表',
            child: IconButton(
              icon: Icon(Icons.label),
              onPressed: () async {
                final result = await plugin.libraryUIController.showTagSelector(
                  library,
                  context,
                );
                if (result != null && result.isNotEmpty) {}
              },
            ),
          ),
          Tooltip(
            message: '收藏',
            child: IconButton(icon: Icon(Icons.favorite), onPressed: () {}),
          ),
          Tooltip(
            message: '回收站',
            child: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                state.tabManager.addTab(
                  library,
                  isRecycleBin: true,
                  title: '回收站',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建侧边栏部分
  Widget buildSidebarSection(double screenWidth) {
    return MultiValueListenableBuilder(
      valueListenables: [
        state.tags,
        state.folders,
        state.filterOptionsNotifier,
      ],
      builder: (context, values, _) {
        final tags = values[0] as List<LibraryTag>;
        final folders = values[1] as List<LibraryFolder>;
        final filterOptions = values[2] as Map<String, dynamic>;

        return LibrarySidebarView(
          plugin: plugin,
          library: library,
          tabId: tabId,
          tags: tags,
          tagsSelected: List<String>.from(filterOptions['tags'] ?? []),
          folders: folders,
          folderSelected:
              filterOptions['folder'] is String
                  ? [filterOptions['folder']]
                  : [],
        );
      },
    );
  }

  /// 构建主内容区域
  Widget buildMainContent(bool isRecycleBin, double screenWidth) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    sizingInformation.deviceScreenType ==
                            DeviceScreenType.desktop
                        ? _buildDesktopGalleryWithAreaSelection(
                          events.onFileSelectedWithKeyboard,
                        )
                        : buildGalleryBody(events.onFileSelected),
                    ValueListenableBuilder(
                      valueListenable: state.isItemsLoadingNotifier,
                      builder: (context, isLoading, _) {
                        return isLoading
                            ? Center(child: CircularProgressIndicator())
                            : SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              buildPagination(),
            ],
          ),
        );
      },
    );
  }

  /// 构建图库主体
  Widget buildGalleryBody(Function(LibraryFile) onFileSelected) {
    return MultiValueListenableBuilder(
      valueListenables: [
        state.items,
        state.isSelectionModeNotifier,
        state.selectedFileIds,
        state.displayFieldsNotifier,
        state.imagesPerRowNotifier,
      ],
      builder: (context, values, _) {
        return GestureDetector(
          // 双击清除所有选中
          onDoubleTap: () {
            state.selectedFileIds.value = {};
            state.isSelectionModeNotifier.value = false;
          },
          child: LibraryGalleryBody(
            plugin: plugin,
            library: library,
            isRecycleBin: state.tabData!.isRecycleBin,
            displayFields: values[3] as Set<String>,
            items: values[0] as List<LibraryFile>,
            isSelectionMode: values[1] as bool,
            selectedFileIds: values[2] as Set<int>,
            onFileSelected: onFileSelected,
            onFileOpen: onFileOpen ?? (file) {},
            imagesPerRow: values[4] as int,
            scrollController: state.scrollController,
          ),
        );
      },
    );
  }

  /// 构建支持范围选择的图库主体（桌面端专用）
  Widget buildGalleryBodyWithAreaSelection(
    Function(LibraryFile) onFileSelected,
  ) {
    return MultiValueListenableBuilder(
      valueListenables: [
        state.items,
        state.isSelectionModeNotifier,
        state.selectedFileIds,
        state.displayFieldsNotifier,
        state.imagesPerRowNotifier,
      ],
      builder: (context, values, _) {
        final GlobalKey<SelectableGalleryGridState> gridKey = GlobalKey();
        final GlobalKey<AreaSelectionOverlayState> overlayKey = GlobalKey();

        return Stack(
          children: [
            // 图库网格组件 - 包含控制按钮
            SelectableGalleryGrid(
              key: gridKey,
              plugin: plugin,
              library: library,
              isRecycleBin: state.tabData!.isRecycleBin,
              displayFields: values[3] as Set<String>,
              items: values[0] as List<LibraryFile>,
              isSelectionMode: values[1] as bool,
              selectedFileIds: values[2] as Set<int>,
              onFileSelected: onFileSelected,
              onFileOpen: onFileOpen ?? (file) {},
              imagesPerRow: values[4] as int,
              scrollController: state.scrollController,
              onSelectionChanged: (selectedIds) {
                state.selectedFileIds.value = selectedIds;
              },
              areaSelectionController: null, // 不再使用控制器
              onStartAreaSelection: () {
                // 启动区域选择模式
                overlayKey.currentState?.startSelectionMode();
              },
              onEndAreaSelection: () {
                // 结束区域选择模式
                overlayKey.currentState?.endSelectionMode();
              },
            ),
            // 区域选择覆盖层 - 作为平行组件，仅提供交互层和视觉反馈
            AreaSelectionOverlay(
              key: overlayKey,
              enabled: true,
              scrollController: state.scrollController, // 直接传递ScrollController
              onSelectionStart: (startPosition) {
                // 开始选择时的处理
                state.isSelectionModeNotifier.value = true;
              },
              onAreaSelectionUpdate: (selectionArea) {
                gridKey.currentState?.handleAreaSelectionUpdate(selectionArea);
              },
              onClearSelection: () {
                gridKey.currentState?.clearAllSelection();
                state.isSelectionModeNotifier.value = false;
              },
              onSelectionStateChanged: (isActive) {
                if (isActive) {
                  state.isSelectionModeNotifier.value = true;
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// 构建支持范围选择的桌面端图库
  Widget _buildDesktopGalleryWithAreaSelection(
    Function(LibraryFile) onFileSelected,
  ) {
    return KeyboardListener(
      focusNode: state.keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        // 按住 Ctrl + Shift + A 启动区域选择
        if (event is KeyDownEvent) {
          final isCtrlPressed =
              event.logicalKey == LogicalKeyboardKey.controlLeft ||
              event.logicalKey == LogicalKeyboardKey.controlRight;
          final isShiftPressed =
              event.logicalKey == LogicalKeyboardKey.shiftLeft ||
              event.logicalKey == LogicalKeyboardKey.shiftRight;
          final isAPressed = event.logicalKey == LogicalKeyboardKey.keyA;

          // 检查组合键
          if ((isCtrlPressed || HardwareKeyboard.instance.isControlPressed) &&
              (isShiftPressed || HardwareKeyboard.instance.isShiftPressed) &&
              isAPressed) {
            // 触发区域选择模式
            state.isSelectionModeNotifier.value = true;
            // 这里需要一个全局的控制器引用，我们稍后会添加
          }

          // Esc 键退出选择模式
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            state.isSelectionModeNotifier.value = false;
            state.selectedFileIds.value = {};
          }
        }
      },
      child: buildGalleryBodyWithAreaSelection(onFileSelected),
    );
  }

  /// 构建分页组件
  Widget buildPagination() {
    return ValueListenableBuilder<int>(
      valueListenable: state.totalItemsNotifier,
      builder: (context, totalItems, _) {
        final paginationOptions = state.paginationOptionsNotifier.value;
        final totalPages = (totalItems / paginationOptions['perPage']).ceil();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: NumberPagination(
            currentPage: paginationOptions['page'],
            totalPages: totalPages,
            onPageChanged: events.toPage,
            visiblePagesCount: MediaQuery.of(context).size.width ~/ 200 + 2,
            buttonRadius: 10.0,
            buttonElevation: 1.0,
            controlButtonSize: Size(34, 34),
            numberButtonSize: Size(34, 34),
            selectedButtonColor: Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }

  /// 构建详情页面
  Widget buildMoreDetailsPage() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tooltip(
                message: '文件信息',
                child: Tab(icon: Icon(Icons.info_outline)),
              ),
              Tooltip(
                message: '选中文件列表',
                child: Tab(icon: Icon(Icons.list_alt)),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ValueListenableBuilder<LibraryFile?>(
                  valueListenable: state.selectedFileNotifier,
                  builder: (context, selectedFile, _) {
                    return selectedFile != null
                        ? LibraryFileInformationView(
                          plugin: plugin,
                          library: library,
                          file: selectedFile,
                        )
                        : const Center(child: Text('请选择一个文件查看详情'));
                  },
                ),
                ValueListenableBuilder<Set<int>>(
                  valueListenable: state.selectedFileIds,
                  builder: (context, selectedIds, _) {
                    final selectedFiles =
                        state.items.value
                            .where((file) => selectedIds.contains(file.id))
                            .toList();
                    if (selectedFiles.isEmpty) {
                      return const Center(child: Text('未选中文件'));
                    }
                    return ListView.builder(
                      itemCount: selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = selectedFiles[index];
                        return ListTile(
                          leading: Icon(Icons.insert_drive_file),
                          title: Text(file.name),
                          subtitle: Text('ID: ${file.id}'),
                          onTap: () {
                            state.selectedFileNotifier.value = file;
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
