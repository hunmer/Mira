import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mira/dock/dock_manager.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/core/event/event_args.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_data.dart';
import 'drag_select_view.dart';

/// Gallery状态管理 - 适配dock系统版本
class LibraryGalleryStateDock {
  // 文件列表和加载状态
  final ValueNotifier<List<LibraryFile>> filesNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isItemsLoadingNotifier = ValueNotifier(true);
  final ValueNotifier<List<LibraryFolder>> folders = ValueNotifier([]);
  final ValueNotifier<List<LibraryTag>> tags = ValueNotifier([]);

  // Tab数据
  String? tabId;
  LibraryTabData? tabData;

  // UI状态
  final ValueNotifier<bool> showSidebarNotifier = ValueNotifier(true);
  final ValueNotifier<LibraryFile?> selectedFileNotifier = ValueNotifier(null);

  // 控制器
  final ScrollController scrollController = ScrollController();
  final FocusNode keyboardFocusNode = FocusNode();

  // 配置选项 - 从dock系统获取
  final ValueNotifier<Set<String>> displayFieldsNotifier = ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> filterOptionsNotifier =
      ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> paginationOptionsNotifier =
      ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> sortOptionsNotifier = ValueNotifier(
    {'sort': 'id', 'order': 'desc'},
  );
  final ValueNotifier<int> imagesPerRowNotifier = ValueNotifier(0);
  final ValueNotifier<DragSelectViewType> viewTypeNotifier = ValueNotifier(
    DragSelectViewType.grid,
  );

  // 上传相关
  UploadQueueService? uploadQueue;
  StreamSubscription? progressSubscription;
  final ValueNotifier<double> uploadProgressNotifier = ValueNotifier(0.0);

  // 其他状态
  bool isFirstLoad = false;
  final List<String> eventSubscribes = [];

  /// 初始化状态 - 使用dock系统
  void initializeStateDock(String tabId, LibraryTabData tabData) {
    this.tabId = tabId;
    this.tabData = tabData;

    // 从dock系统恢复状态
    _loadStateFromDock();

    // 设置监听器来同步dock状态变化
    _setupDockStateListeners();
  }

  /// 从dock系统加载状态
  void _loadStateFromDock() {
    if (tabId == null) return;

    paginationOptionsNotifier.value = Map<String, dynamic>.from(
      DockManager.getLibraryTabStoredValue(
            tabId!,
            'paginationOptions',
            defaultValue: {'page': 1, 'perPage': 1000},
          ) ??
          {'page': 1, 'perPage': 1000},
    );

    displayFieldsNotifier.value = Set<String>.from(
      DockManager.getLibraryTabStoredValue<List<dynamic>>(
            tabId!,
            'displayFields',
            defaultValue: <String>[],
          ) ??
          <String>[],
    );

    sortOptionsNotifier.value = Map<String, dynamic>.from(
      DockManager.getLibraryTabStoredValue(
            tabId!,
            'sortOptions',
            defaultValue: {'field': 'id', 'order': 'desc'},
          ) ??
          {'field': 'id', 'order': 'desc'},
    );

    filterOptionsNotifier.value = Map<String, dynamic>.from(
      DockManager.getLibraryTabStoredValue(
            tabId!,
            'filter',
            defaultValue: <String, dynamic>{},
          ) ??
          <String, dynamic>{},
    );

    imagesPerRowNotifier.value =
        DockManager.getLibraryTabStoredValue<int>(
          tabId!,
          'imagesPerRow',
          defaultValue: 0,
        ) ??
        0;
  }

  /// 设置dock状态监听器
  void _setupDockStateListeners() {
    // 监听分页变化
    paginationOptionsNotifier.addListener(() {
      _saveToDock('paginationOptions', paginationOptionsNotifier.value);
    });

    // 监听排序变化
    sortOptionsNotifier.addListener(() {
      _saveToDock('sortOptions', sortOptionsNotifier.value);
      _broadcastSortUpdate();
    });

    // 监听过滤器变化
    filterOptionsNotifier.addListener(() {
      _saveToDock('filter', filterOptionsNotifier.value);
      _broadcastFilterUpdate();
    });

    // 监听显示字段变化
    displayFieldsNotifier.addListener(() {
      _saveToDock('displayFields', displayFieldsNotifier.value.toList());
    });

    // 监听每行图片数变化
    imagesPerRowNotifier.addListener(() {
      _saveToDock('imagesPerRow', imagesPerRowNotifier.value);
    });
  }

  /// 保存到dock系统
  void _saveToDock(String key, dynamic value) {
    if (tabId != null) {
      DockManager.updateLibraryTabStoredValue(tabId!, key, value);
    }
  }

  /// 广播排序更新
  void _broadcastSortUpdate() {
    if (tabData != null && tabId != null) {
      EventManager.instance.broadcast(
        'sort::updated',
        MapEventArgs({
          'library': tabData!.library,
          'tabId': tabId!,
          'sort': sortOptionsNotifier.value,
        }),
      );
    }
  }

  /// 广播过滤器更新
  void _broadcastFilterUpdate() {
    if (tabData != null && tabId != null) {
      EventManager.instance.broadcast(
        'filter::updated',
        MapEventArgs({
          'library': tabData!.library,
          'tabId': tabId!,
          'filter': filterOptionsNotifier.value,
        }),
      );
    }
  }

  /// 更新过滤器
  void updateFilter(Map<String, dynamic> filter) {
    final newFilter = {...filterOptionsNotifier.value, ...filter};
    filterOptionsNotifier.value = newFilter;

    // 重置分页到第一页
    final newPagination = Map<String, dynamic>.from(
      paginationOptionsNotifier.value,
    );
    newPagination['page'] = 1;
    paginationOptionsNotifier.value = newPagination;
  }

  /// 设置排序选项
  void setSortOptions(Map<String, dynamic> sortOptions) {
    sortOptionsNotifier.value = sortOptions;
  }

  /// 获取存储值
  T? getStoredValue<T>(String key, T? defaultValue) {
    if (tabId == null) return defaultValue;
    return DockManager.getLibraryTabStoredValue<T>(
      tabId!,
      key,
      defaultValue: defaultValue,
    );
  }

  /// 设置存储值
  void setStoredValue(String key, dynamic value) {
    _saveToDock(key, value);
  }

  /// 更新标签页
  void updateTab() {
    if (tabId != null) {
      EventManager.instance.broadcast(
        'tab::doUpdate',
        MapEventArgs({'tabId': tabId!}),
      );
    }
  }

  /// 尝试更新
  void tryUpdate() {
    final needUpdate = getStoredValue<bool>('needUpdate', false) ?? false;
    if (needUpdate) {
      setStoredValue('needUpdate', false);
      updateTab();
    }
  }

  /// 释放资源
  void dispose() {
    progressSubscription?.cancel();
    filesNotifier.dispose();
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
    uploadProgressNotifier.dispose();
    scrollController.dispose();
    keyboardFocusNode.dispose();
  }
}
