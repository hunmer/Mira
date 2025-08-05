import 'package:flutter/material.dart';
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
import 'package:mira/plugins/libraries/widgets/library_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/selected_files_page.dart';
import 'library_gallery_events.dart';
import 'library_gallery_state.dart';
import 'drag_select_view.dart';

/// 图库视图的UI构建器类
class LibraryGalleryBuilders {
  final LibraryGalleryState state;
  final LibraryGalleryEvents events;
  final LibrariesPlugin plugin;
  final Library library;
  final String tabId;
  final VoidCallback? onShowDropDialog;
  final Function(LibraryFile) onFileOpen;
  final Function(LibraryFile) onFileSelected;
  final Function(LibraryFile) onToggleSelected;

  LibraryGalleryBuilders({
    required this.state,
    required this.events,
    required this.plugin,
    required this.library,
    required this.tabId,
    this.onShowDropDialog,
    required this.onFileOpen,
    required this.onFileSelected,
    required this.onToggleSelected,
  });

  /// 构建响应式布局
  Widget buildResponsiveLayout(
    BuildContext context,
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
                child: buildQuickActions(context),
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
              flex: 2,
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
      viewType: state.viewTypeNotifier.value,
      onViewTypeChanged: (DragSelectViewType viewType) {
        state.viewTypeNotifier.value = viewType;
        state.tabManager.setStoreValue(tabId, 'viewType', viewType.index);
      },
    );
  }

  /// 构建快捷操作栏
  Widget buildQuickActions(BuildContext context) {
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
                    buildGalleryBodyWithDragSelect(),
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

  Widget buildGalleryBodyWithDragSelect() {
    return MultiValueListenableBuilder(
      valueListenables: [
        state.items,
        state.isSelectionModeNotifier,
        state.selectedFileIds,
        state.displayFieldsNotifier,
        state.imagesPerRowNotifier,
        state.viewTypeNotifier,
      ],
      builder: (context, values, _) {
        return GestureDetector(
          // 双击清除所有选中
          onDoubleTap: () {
            state.selectedFileIds.value = {};
            state.isSelectionModeNotifier.value = false;
          },
          child: DragSelectView(
            plugin: plugin,
            library: library,
            viewType: values[5] as DragSelectViewType,
            isRecycleBin: state.tabData!.isRecycleBin,
            displayFields: values[3] as Set<String>,
            items: values[0] as List<LibraryFile>,
            isSelectionMode: values[1] as bool,
            selectedFileIds: values[2] as Set<int>,
            onFileSelected: onFileSelected,
            onToggleSelected: onToggleSelected,
            onFileOpen: onFileOpen,
            imagesPerRow: values[4] as int,
            scrollController: state.scrollController,
            onSelectionChanged: (selectedIds) {
              state.selectedFileIds.value = selectedIds;
            },
          ),
        );
      },
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
                    return Column(
                      children: [
                        Expanded(
                          child: SelectedFilesPage(
                            plugin: plugin,
                            library: library,
                            selectedFiles: selectedFiles,
                            galleryState: state,
                            onSelectionChanged: (selectedIds) {
                              state.selectedFileIds.value = selectedIds;
                            },
                          ),
                        ),
                      ],
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
