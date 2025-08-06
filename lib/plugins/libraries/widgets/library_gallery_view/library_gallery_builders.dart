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
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
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
  late BuildContext context;

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
    this.context = context;
    // 为不同设备类型创建不同的 Docking 布局
    final layoutData = _createLayoutDataForDevice(
      sizingInformation.deviceScreenType,
    );

    return _buildDockingLayout(
      context,
      layoutData,
      isRecycleBin,
      sizingInformation.screenSize.width,
    );
  }

  /// 为不同设备创建布局数据
  Map<String, dynamic> _createLayoutDataForDevice(DeviceScreenType deviceType) {
    switch (deviceType) {
      case DeviceScreenType.mobile:
        return {
          'type': 'item',
          'id': 'main_content',
          'name': 'Library Content',
          'closable': false,
          'maximizable': false,
          'keepAlive': true,
        };

      case DeviceScreenType.tablet:
        return {
          'type': 'row',
          'items': [
            {
              'id': 'sidebar',
              'name': 'Sidebar',
              'type': 'item',
              'closable': false,
              'maximizable': false,
              'keepAlive': true,
              'weight': 0.15,
              'minimalSize': 250.0,
            },
            {
              'id': 'main_content',
              'name': 'Library Content',
              'type': 'item',
              'closable': false,
              'maximizable': true,
              'keepAlive': true,
              'weight': 0.85,
            },
          ],
        };

      case DeviceScreenType.desktop:
        return {
          'type': 'row',
          'items': [
            {
              'id': 'quick_actions',
              'name': 'Quick Actions',
              'type': 'item',
              'closable': false,
              'maximizable': false,
              'keepAlive': true,
              'size': 60.0,
            },
            {
              'id': 'sidebar',
              'name': 'Sidebar',
              'type': 'item',
              'closable': false,
              'maximizable': false,
              'keepAlive': true,
              'weight': 0.15,
              'minimalSize': 250.0,
            },
            {
              'id': 'main_content',
              'name': 'Library Content',
              'type': 'item',
              'closable': false,
              'maximizable': true,
              'keepAlive': true,
              'weight': 0.6,
            },
            {
              'id': 'details',
              'name': 'Details',
              'type': 'item',
              'closable': true,
              'maximizable': false,
              'keepAlive': true,
              'weight': 0.2,
              'minimalSize': 300.0,
            },
            {
              'id': 'app_bar_actions',
              'name': 'Actions',
              'type': 'item',
              'closable': false,
              'maximizable': false,
              'keepAlive': true,
              'size': 60.0,
            },
          ],
        };

      case DeviceScreenType.watch:
      default:
        return {
          'type': 'item',
          'id': 'main_content',
          'name': 'Library Content',
          'closable': false,
          'maximizable': false,
          'keepAlive': true,
        };
    }
  }

  /// 构建 Docking 布局
  Widget _buildDockingLayout(
    BuildContext context,
    Map<String, dynamic> layoutData,
    bool isRecycleBin,
    double screenWidth,
  ) {
    final dockingLayout = DockingLayout(
      root: _buildAreaFromData(layoutData, isRecycleBin, screenWidth),
    );

    return Docking(
      layout: dockingLayout,
      onItemSelection: (DockingItem item) {
        // 处理项目选择
        print('Selected docking item: ${item.name}');
      },
      onItemClose: (DockingItem item) {
        // 处理项目关闭
        print('Closed docking item: ${item.name}');
      },
      itemCloseInterceptor: (DockingItem item) {
        // 某些面板不允许关闭
        final nonClosableItems = [
          'main_content',
          'sidebar',
          'quick_actions',
          'app_bar_actions',
        ];
        return !nonClosableItems.contains(item.id);
      },
    );
  }

  /// 从数据构建 Docking 区域
  DockingArea _buildAreaFromData(
    Map<String, dynamic> data,
    bool isRecycleBin,
    double screenWidth,
  ) {
    final type = data['type'] as String;

    if (type == 'row') {
      final items = data['items'] as List<dynamic>;
      final areas =
          items
              .map(
                (item) => _buildAreaFromData(
                  item as Map<String, dynamic>,
                  isRecycleBin,
                  screenWidth,
                ),
              )
              .toList();
      return DockingRow(areas);
    } else if (type == 'column') {
      final items = data['items'] as List<dynamic>;
      final areas =
          items
              .map(
                (item) => _buildAreaFromData(
                  item as Map<String, dynamic>,
                  isRecycleBin,
                  screenWidth,
                ),
              )
              .toList();
      return DockingColumn(areas);
    } else if (type == 'tabs') {
      final items = data['items'] as List<dynamic>;
      final dockingItems =
          items
              .map(
                (item) => _buildAreaFromData(
                  item as Map<String, dynamic>,
                  isRecycleBin,
                  screenWidth,
                ),
              )
              .whereType<DockingItem>()
              .toList();
      return DockingTabs(dockingItems);
    } else {
      // type == 'item'
      return _buildDockingItem(data, isRecycleBin, screenWidth);
    }
  }

  /// 构建单个 DockingItem
  DockingItem _buildDockingItem(
    Map<String, dynamic> data,
    bool isRecycleBin,
    double screenWidth,
  ) {
    final id = data['id'] as String;
    final name = data['name'] as String;
    final closable = data['closable'] as bool? ?? true;
    final maximizable = data['maximizable'] as bool? ?? true;
    final keepAlive = data['keepAlive'] as bool? ?? false;
    final weight = data['weight'] as double?;
    final size = data['size'] as double?;
    final minimalSize = data['minimalSize'] as double?;

    return DockingItem(
      id: id,
      name: name,
      closable: closable,
      maximizable: maximizable,
      keepAlive: keepAlive,
      weight: weight,
      size: size,
      minimalSize: minimalSize,
      widget: _buildItemContent(id, isRecycleBin, screenWidth),
    );
  }

  /// 构建项目内容
  Widget _buildItemContent(
    String itemId,
    bool isRecycleBin,
    double screenWidth,
  ) {
    switch (itemId) {
      case 'quick_actions':
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: buildQuickActionsPanel(),
          ),
        );

      case 'sidebar':
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: buildSidebarSection(screenWidth),
          ),
        );

      case 'main_content':
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: buildMainContent(isRecycleBin, screenWidth),
          ),
        );

      case 'details':
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: buildMoreDetailsPage(),
          ),
        );

      case 'app_bar_actions':
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: buildAppBarActions(),
          ),
        );

      default:
        return Card(
          elevation: 4,
          margin: const EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Center(child: Text('Unknown panel: $itemId')),
          ),
        );
    }
  }

  /// 构建快速操作面板
  Widget buildQuickActionsPanel() {
    return Column(
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
    );
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
