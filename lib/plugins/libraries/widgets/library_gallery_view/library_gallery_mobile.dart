import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:mira/plugins/libraries/widgets/library_sidebar_view.dart';
import 'library_gallery_events.dart';
import 'library_gallery_state.dart';

/// 移动端特定的UI组件类
class LibraryGalleryMobile {
  final LibraryGalleryState state;
  final LibraryGalleryEvents events;
  final LibrariesPlugin plugin;
  final Library library;
  final String tabId;
  final VoidCallback? onShowDropDialog;

  LibraryGalleryMobile({
    required this.state,
    required this.events,
    required this.plugin,
    required this.library,
    required this.tabId,
    this.onShowDropDialog,
  });

  /// 处理移动端文件选择事件
  void onMobileFileSelected(LibraryFile file, BuildContext context) {
    events.onFileSelected(file);

    // 在移动端显示底部信息弹窗
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      showModalBottomSheet(
        context: context,
        builder:
            (context) => LibraryFileInformationView(
              plugin: plugin,
              library: library,
              file: file,
            ),
      );
    }
  }

  /// 构建移动端浮动操作按钮
  Widget buildMobileFloatingActions() {
    return FloatingActionButton(
      heroTag: "upload",
      onPressed: onShowDropDialog ?? () {},
      tooltip: '上传',
      child: Icon(Icons.add),
    );
  }

  /// 构建移动端顶部操作栏
  Widget buildMobileTopBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // 第一行：标题和基本操作
          Row(
            children: [
              Expanded(
                child: Text(
                  library.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: events.refresh,
                tooltip: '刷新',
              ),
              ValueListenableBuilder<bool>(
                valueListenable: state.isSelectionModeNotifier,
                builder: (context, isSelectionMode, _) {
                  return IconButton(
                    icon: Icon(isSelectionMode ? Icons.close : Icons.check_box),
                    onPressed:
                        () =>
                            state.isSelectionModeNotifier.value =
                                !isSelectionMode,
                    tooltip: isSelectionMode ? '退出选择' : '多选',
                  );
                },
              ),
            ],
          ),
          // 第二行：快捷操作图标
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => showMobileSidebarDialog(context),
                  tooltip: '侧边栏',
                ),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () => showMobileFilterDialog(context),
                  tooltip: '筛选',
                ),
                IconButton(
                  icon: Icon(Icons.folder),
                  onPressed: () async {
                    final result = await plugin.libraryUIController
                        .showFolderSelector(library, context);
                    if (result != null && result.isNotEmpty) {}
                  },
                  tooltip: '文件夹',
                ),
                IconButton(
                  icon: Icon(Icons.label),
                  onPressed: () async {
                    final result = await plugin.libraryUIController
                        .showTagSelector(library, context);
                    if (result != null && result.isNotEmpty) {}
                  },
                  tooltip: '标签',
                ),
                IconButton(
                  icon: Icon(Icons.favorite),
                  onPressed: () {},
                  tooltip: '收藏',
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    state.tabManager.addTab(
                      library,
                      isRecycleBin: true,
                      title: '回收站',
                    );
                  },
                  tooltip: '回收站',
                ),
                IconButton(
                  icon: Icon(Icons.sort),
                  onPressed: () => showMobileSortDialog(context),
                  tooltip: '排序',
                ),
                IconButton(
                  icon: Icon(Icons.view_module),
                  onPressed: () => showMobileDisplayDialog(context),
                  tooltip: '显示选项',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示移动设备的侧边栏对话框
  void showMobileSidebarDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: EdgeInsets.all(16),
                  child: MultiValueListenableBuilder(
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
                        tagsSelected: List<String>.from(
                          filterOptions['tags'] ?? [],
                        ),
                        folders: folders,
                        folderSelected:
                            filterOptions['folder'] is String
                                ? [filterOptions['folder']]
                                : [],
                      );
                    },
                  ),
                ),
          ),
    );
  }

  /// 显示移动设备的简化筛选对话框
  void showMobileFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('筛选选项', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: '文件名',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    final currentFilter = Map<String, dynamic>.from(
                      state.filterOptionsNotifier.value,
                    );
                    currentFilter['name'] = value;
                    state.filterOptionsNotifier.value = currentFilter;
                    state.tabManager.updateFilter(tabId, currentFilter);
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showMobileSidebarDialog(context);
                        },
                        icon: Icon(Icons.label),
                        label: Text('标签筛选'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 清除筛选
                          final defaultFilter = {
                            'name': '',
                            'tags': [],
                            'folder': '',
                          };
                          state.filterOptionsNotifier.value = defaultFilter;
                          state.tabManager.updateFilter(tabId, defaultFilter);
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.clear),
                        label: Text('清除'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  /// 显示移动设备的排序对话框
  void showMobileSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(16),
            child: ValueListenableBuilder<Map<String, dynamic>>(
              valueListenable: state.sortOptionsNotifier,
              builder: (context, sortOptions, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('排序选项', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('按名称'),
                      leading: Radio<String>(
                        value: 'name',
                        groupValue: sortOptions['sort'],
                        onChanged:
                            (value) =>
                                events.updateSort(value!, sortOptions['order']),
                      ),
                    ),
                    ListTile(
                      title: Text('按导入时间'),
                      leading: Radio<String>(
                        value: 'imported_at',
                        groupValue: sortOptions['sort'],
                        onChanged:
                            (value) =>
                                events.updateSort(value!, sortOptions['order']),
                      ),
                    ),
                    ListTile(
                      title: Text('按大小'),
                      leading: Radio<String>(
                        value: 'size',
                        groupValue: sortOptions['sort'],
                        onChanged:
                            (value) =>
                                events.updateSort(value!, sortOptions['order']),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => events.updateSort(
                                  sortOptions['sort'],
                                  'asc',
                                ),
                            icon: Icon(Icons.arrow_upward),
                            label: Text('升序'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  sortOptions['order'] == 'asc'
                                      ? Theme.of(context).primaryColor
                                      : null,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => events.updateSort(
                                  sortOptions['sort'],
                                  'desc',
                                ),
                            icon: Icon(Icons.arrow_downward),
                            label: Text('降序'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  sortOptions['order'] == 'desc'
                                      ? Theme.of(context).primaryColor
                                      : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  /// 显示移动设备的显示选项对话框
  void showMobileDisplayDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(16),
            child: ValueListenableBuilder<int>(
              valueListenable: state.imagesPerRowNotifier,
              builder: (context, imagesPerRow, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('显示选项', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 16),
                    Text('每行图片数量'),
                    Slider(
                      value: imagesPerRow == 0 ? 3 : imagesPerRow.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      label: imagesPerRow == 0 ? '自动' : imagesPerRow.toString(),
                      onChanged: (value) {
                        state.imagesPerRowNotifier.value = value.round();
                        state.tabManager.setStoreValue(
                          tabId,
                          'imagesPerRow',
                          value.round(),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('确定'),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }
}
