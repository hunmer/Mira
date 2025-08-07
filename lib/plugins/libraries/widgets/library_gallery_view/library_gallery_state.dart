import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_data.dart';
import 'drag_select_view.dart';

/// 图库视图的状态管理类
class LibraryGalleryState {
  late final String tabId;
  late final String itemId;
  late LibraryTabData tabData;

  // 上传相关状态
  late UploadQueueService uploadQueue;
  final ValueNotifier<double> uploadProgressNotifier = ValueNotifier(0);
  StreamSubscription<Map<String, int>>? progressSubscription;

  // 选择模式相关状态
  final ValueNotifier<bool> isSelectionModeNotifier = ValueNotifier(false);
  final ValueNotifier<Set<int>> selectedFileIds = ValueNotifier({});
  int? lastSelectedIndex; // 用于Shift范围选择的最后选中文件索引

  // 范围选择相关状态
  final ValueNotifier<bool> isAreaSelectionActive = ValueNotifier(false);
  final ValueNotifier<Rect?> selectionArea = ValueNotifier(null);
  Offset? areaSelectionStartPoint;

  // 数据相关状态
  final ValueNotifier<int> totalItemsNotifier = ValueNotifier(0);
  final ValueNotifier<List<LibraryFile>> items = ValueNotifier([]);
  final ValueNotifier<bool> isItemsLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<List<LibraryFolder>> folders = ValueNotifier([]);
  final ValueNotifier<List<LibraryTag>> tags = ValueNotifier([]);

  // UI状态
  final ValueNotifier<bool> showSidebarNotifier = ValueNotifier(true);
  final ValueNotifier<LibraryFile?> selectedFileNotifier = ValueNotifier(null);

  // 控制器
  final ScrollController scrollController = ScrollController();
  final FocusNode keyboardFocusNode = FocusNode();

  // 配置选项
  final ValueNotifier<Set<String>> displayFieldsNotifier = ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> filterOptionsNotifier =
      ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> paginationOptionsNotifier =
      ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> sortOptionsNotifier = ValueNotifier(
    {'sort': 'id', 'order': 'desc'},
  );
  final ValueNotifier<int> imagesPerRowNotifier = ValueNotifier(
    0,
  ); // 每行显示图片自动调节
  final ValueNotifier<DragSelectViewType> viewTypeNotifier = ValueNotifier(
    DragSelectViewType.grid,
  ); // 视图类型：网格或瀑布流

  // 其他状态
  bool isFirstLoad = false;
  final List<String> eventSubscribes = [];

  LibraryGalleryState({required this.tabData}) {
    tabId = tabData.tabId;
    itemId = tabData.itemId;
    // 从tabData中恢复状态
    paginationOptionsNotifier.value = Map<String, dynamic>.from(
      _getStoredValue('paginationOptions', {'page': 1, 'perPage': 1000}),
    );

    displayFieldsNotifier.value = Set<String>.from(
      _getStoredValue('displayFields', <String>{}),
    );

    filterOptionsNotifier.value = Map<String, dynamic>.from(
      _getStoredValue('filter', {'name': '', 'tags': [], 'folder': ''}),
    );

    sortOptionsNotifier.value = Map<String, dynamic>.from(
      _getStoredValue('sortOptions', {'sort': 'imported_at', 'order': 'desc'}),
    );

    imagesPerRowNotifier.value = _getStoredValue('imagesPerRow', 0) as int;

    viewTypeNotifier.value =
        DragSelectViewType.values[_getStoredValue('viewType', 0) as int];

    // 监听选择模式状态变化，当退出选择模式时重置最后选中索引
    isSelectionModeNotifier.addListener(() {
      if (!isSelectionModeNotifier.value) {
        lastSelectedIndex = null;
        // 退出选择模式时也清除范围选择状态
        isAreaSelectionActive.value = false;
        selectionArea.value = null;
        areaSelectionStartPoint = null;
      }
    });
  }

  /// 从tabData.stored中获取存储的值
  dynamic _getStoredValue(String key, dynamic defaultValue) {
    return tabData.stored[key] ?? defaultValue;
  }

  /// 清理资源
  void dispose() {
    progressSubscription?.cancel();
    uploadQueue.dispose();
    scrollController.dispose();
    keyboardFocusNode.dispose();

    // 清理所有ValueNotifier
    uploadProgressNotifier.dispose();
    isSelectionModeNotifier.dispose();
    selectedFileIds.dispose();
    isAreaSelectionActive.dispose();
    selectionArea.dispose();
    totalItemsNotifier.dispose();
    items.dispose();
    isItemsLoadingNotifier.dispose();
    folders.dispose();
    tags.dispose();
    showSidebarNotifier.dispose();
    selectedFileNotifier.dispose();
    displayFieldsNotifier.dispose();
    filterOptionsNotifier.dispose();
    paginationOptionsNotifier.dispose();
    sortOptionsNotifier.dispose();
    imagesPerRowNotifier.dispose();
    viewTypeNotifier.dispose();
  }
}
