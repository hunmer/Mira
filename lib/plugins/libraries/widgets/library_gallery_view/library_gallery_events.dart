import 'package:flutter/material.dart';
import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_data.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager_dock.dart';
import 'library_gallery_state.dart';

/// 图库视图的事件处理类
class LibraryGalleryEvents {
  final LibraryGalleryState state;
  final LibrariesPlugin plugin;
  final Library library;
  late final String tabId;
  late final String itemId;
  final LibraryTabData tabData;

  LibraryGalleryEvents({
    required this.state,
    required this.tabData,
    required this.plugin,
    required this.library,
  }) {
    tabId = tabData.tabId;
    itemId = tabData.itemId;
  }

  /// 初始化事件监听
  void initEvents() {
    state.eventSubscribes.addAll([
      EventManager.instance.subscribe(
        'thumbnail::generated',
        onThumbnailGenerated,
      ),
      EventManager.instance.subscribe('tab::doUpdate', (EventArgs args) {
        if (args is MapEventArgs) {
          if (args.item['tabId'] == tabId) {
            refresh();
            print('updated Tab $tabId');
          }
        }
      }),
      EventManager.instance.subscribe('filter::updated', onFilterUpdate),
      EventManager.instance.subscribe('sort::updated', onSortUpdate),
      EventManager.instance.subscribeOnce('library::connected', doFirstLoad),
    ]);
  }

  /// 缩略图生成事件处理
  void onThumbnailGenerated(EventArgs args) {
    if (args is! ServerEventArgs) return;
    // 处理缩略图生成事件
  }

  /// 过滤器更新事件处理
  void onFilterUpdate(EventArgs args) {
    if (args is MapEventArgs) {
      final eventTabId = args.item['tabId'];
      if (tabId == eventTabId) {
        // 重置页面
        state.paginationOptionsNotifier.value = {
          ...state.paginationOptionsNotifier.value,
          'page': 1,
        };
        state.filterOptionsNotifier.value = Map<String, dynamic>.from(
          args.item['filter'],
        );
        loadFiles();
      }
    }
  }

  /// 排序更新事件处理
  void onSortUpdate(EventArgs args) {
    if (args is MapEventArgs) {
      final eventTabId = args.item['tabId'];
      if (tabId == eventTabId) {
        state.sortOptionsNotifier.value = Map<String, dynamic>.from(
          args.item['sort'],
        );
        loadFiles();
      }
    }
  }

  /// 首次加载事件处理
  Future<void> doFirstLoad(EventArgs args) async {
    if (args is MapEventArgs && !state.isFirstLoad) {
      state.isFirstLoad = true;
      state.tags.value =
          (args.item['tags'] as List)
              .map((item) => LibraryTag.fromMap(item))
              .toList();
      state.folders.value =
          (args.item['folders'] as List)
              .map((item) => LibraryFolder.fromMap(item))
              .toList();
      await loadFiles();
    }
  }

  /// 文件选择事件处理
  void onFileSelected(LibraryFile file) {
    final fileId = file.id;
    final fileIndex = state.items.value.indexOf(file);
    final currentSelection = state.selectedFileIds.value;
    if (currentSelection.contains(fileId)) {
      currentSelection.remove(fileId);
    } else {
      currentSelection.add(fileId);
    }
    state.lastSelectedIndex = fileIndex;
    state.selectedFileIds.value = currentSelection;
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadFiles();
    await loadFoldersTags();
  }

  /// 加载文件夹和标签
  Future<void> loadFoldersTags() async {
    final inst = plugin.libraryController.getLibraryInst(library.id);
    if (inst != null) {
      state.tags.value =
          (await inst.getAllTags())
              .map((item) => LibraryTag.fromMap(item))
              .toList();
      state.folders.value =
          (await inst.getAllFolders())
              .map((item) => LibraryFolder.fromMap(item))
              .toList();
    }
  }

  /// 加载文件列表
  Future<void> loadFiles() async {
    state.isItemsLoadingNotifier.value = true;

    final filterOptions = state.filterOptionsNotifier.value;
    final paginationOptions = state.paginationOptionsNotifier.value;
    final sortOptions = state.sortOptionsNotifier.value;

    final query = {
      'recycled': state.tabData.isRecycleBin,
      'name': filterOptions['name'] ?? '',
      'tags': filterOptions['tags'] ?? [],
      'folder': filterOptions['folder'] ?? '',
      'offset': (paginationOptions['page']! - 1) * paginationOptions['perPage'],
      'limit': paginationOptions['perPage'],
      'sort': sortOptions['sort'] ?? 'imported_at',
      'order': sortOptions['order'] ?? 'desc',
    };

    try {
      final inst = plugin.libraryController.getLibraryInst(library.id);
      if (inst != null) {
        final result = await inst.findFiles(query: query);
        state.items.value = result['result'];
        state.totalItemsNotifier.value = result['total'] as int;
        print('Total Count: ${state.totalItemsNotifier.value}');
      }
    } catch (err) {
      state.items.value = [];
    } finally {
      state.isItemsLoadingNotifier.value = false;
    }
  }

  /// 切换侧边栏显示状态
  void toggleSidebar() {
    state.showSidebarNotifier.value = !state.showSidebarNotifier.value;
  }

  /// 跳转到指定页面
  void toPage(int page) {
    print('Page changed to: $page');
    state.paginationOptionsNotifier.value = {
      ...state.paginationOptionsNotifier.value,
      'page': page,
    };
    loadFiles().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state.scrollController.hasClients) {
          state.scrollController.jumpTo(0);
        }
      });
    });
  }

  /// 更新排序选项
  void updateSort(String sort, String order) {
    final newSortOptions = {'sort': sort, 'order': order};
    state.sortOptionsNotifier.value = newSortOptions;
    LibraryTabManager.setStoreValue(
      tabId,
      itemId,
      'sortOptions',
      newSortOptions,
    );
    loadFiles();
  }

  /// 开始范围选择
  void startAreaSelection(Offset startPoint) {
    state.areaSelectionStartPoint = startPoint;
    state.isAreaSelectionActive.value = true;
    state.isSelectionModeNotifier.value = true;
    state.selectionArea.value = Rect.fromPoints(startPoint, startPoint);
  }

  /// 更新范围选择区域
  void updateAreaSelection(Offset currentPoint) {
    if (state.areaSelectionStartPoint != null &&
        state.isAreaSelectionActive.value) {
      // 计算选择矩形，确保正确的左上角和右下角
      final startPoint = state.areaSelectionStartPoint!;
      final left =
          startPoint.dx < currentPoint.dx ? startPoint.dx : currentPoint.dx;
      final top =
          startPoint.dy < currentPoint.dy ? startPoint.dy : currentPoint.dy;
      final right =
          startPoint.dx > currentPoint.dx ? startPoint.dx : currentPoint.dx;
      final bottom =
          startPoint.dy > currentPoint.dy ? startPoint.dy : currentPoint.dy;

      final rect = Rect.fromLTRB(left, top, right, bottom);
      state.selectionArea.value = rect;

      // 实时更新选中的文件
      _updateSelectedFilesInArea(rect);
    }
  }

  /// 结束范围选择
  void endAreaSelection() {
    state.isAreaSelectionActive.value = false;
    state.selectionArea.value = null;
    state.areaSelectionStartPoint = null;
  }

  /// 取消范围选择
  void cancelAreaSelection() {
    state.isAreaSelectionActive.value = false;
    state.selectionArea.value = null;
    state.areaSelectionStartPoint = null;
    // 可选：清除已选中的文件
    // state.selectedFileIds.value = {};
  }

  /// 更新范围内选中的文件
  void _updateSelectedFilesInArea(Rect selectionRect) {
    // 这个方法需要在UI层调用，因为需要知道每个文件项的实际位置
    // 暂时留空，具体实现会在UI层处理
  }

  /// 处理范围选择中的文件项
  void handleFileInAreaSelection(
    LibraryFile file,
    Rect fileRect,
    Rect selectionRect,
  ) {
    final currentSelection = Set<int>.from(state.selectedFileIds.value);

    // 检查文件项的矩形区域是否与选择区域相交
    if (selectionRect.overlaps(fileRect)) {
      currentSelection.add(file.id);
    } else {
      // 如果不在选择区域内，但之前被选中，则移除
      // 注意：这里可能需要根据具体需求调整逻辑
      // currentSelection.remove(file.id);
    }

    state.selectedFileIds.value = currentSelection;
  }

  /// 清理事件监听
  void dispose() {
    for (final key in state.eventSubscribes) {
      EventManager.instance.unsubscribe(key);
    }
  }
}
