import 'package:flutter/material.dart';
import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/services/library_event_manager.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_data.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager_dock.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'library_gallery_state.dart';

/// 图库视图的事件处理类
class LibraryGalleryEvents {
  final LibraryGalleryState state;
  final LibrariesPlugin plugin;
  final Library library;
  late final String tabId;
  late final String itemId;
  final LibraryTabData tabData;

  // 防抖相关
  late final BehaviorSubject<void> _loadFilesSubject;
  late final StreamSubscription _loadFilesSubscription;
  late final BehaviorSubject<void> _loadFoldersTagsSubject;
  late final StreamSubscription _loadFoldersTagsSubscription;
  late final StreamSubscription eventSubscription;
  late final StreamSubscription? tagsUpdateSubscription;
  late final StreamSubscription? folderUpdateSubscription;

  LibraryGalleryEvents({
    required this.state,
    required this.tabData,
    required this.plugin,
    required this.library,
  }) {
    tabId = tabData.tabId;

    // 初始化防抖 Subject
    _loadFilesSubject = BehaviorSubject<void>();
    _loadFoldersTagsSubject = BehaviorSubject<void>();

    // 文件加载防抖，200ms延迟（更短，因为用户操作频繁）
    _loadFilesSubscription = _loadFilesSubject
        .debounceTime(Duration(milliseconds: 200))
        .listen((_) => _doLoadFiles());

    // 文件夹和标签加载防抖，300ms延迟
    _loadFoldersTagsSubscription = _loadFoldersTagsSubject
        .debounceTime(Duration(milliseconds: 300))
        .listen((_) => _doLoadFoldersTags());
  }

  /// 初始化事件监听
  void initEvents() {
    // 监听库更新事件（包含 file::changed 和 tab::doUpdate）
    eventSubscription = LibraryEventManager.instance.addListenerByType(
      'library_update',
      (EventArgs args) {
        if (args is MapEventArgs) {
          final libraryId = args.item['libraryId'];
          if (libraryId == library.id) {
            refresh();
          }
        }
      },
    );

    // 可选：监听标签更新事件
    tagsUpdateSubscription = LibraryEventManager.instance.addListenerByType(
      'tags_update',
      (EventArgs args) {
        if (args is MapEventArgs) {
          final libraryId = args.item['libraryId'];
          if (libraryId == library.id) {
            loadFoldersTags(); // 重新加载标签
          }
        }
      },
    );

    // 可选：监听文件夹更新事件
    folderUpdateSubscription = LibraryEventManager.instance.addListenerByType(
      'folder_update',
      (EventArgs args) {
        if (args is MapEventArgs) {
          final libraryId = args.item['libraryId'];
          if (libraryId == library.id) {
            loadFoldersTags(); // 重新加载文件夹
          }
        }
      },
    );

    state.eventSubscribes.addAll([
      EventManager.instance.subscribe(
        'thumbnail::generated',
        onThumbnailGenerated,
      ),
      EventManager.instance.subscribe('tab::doUpdate', (EventArgs args) {
        if (args is MapEventArgs) {
          if (args.item['tabId'] == tabId && args.item['itemId'] == itemId) {
            refresh();
          }
        }
      }),
      // EventManager.instance.subscribe('filter::updated', onFilterUpdate),
      // EventManager.instance.subscribe('sort::updated', onSortUpdate),
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
      // 首次加载使用立即执行，不需要防抖
      await loadFilesImmediate();
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

  /// 刷新数据（不使用防抖，直接调用防抖版本的加载方法）
  Future<void> refresh() async {
    loadFiles();
    loadFoldersTags();
  }

  /// 立即刷新（不使用防抖）
  Future<void> refreshImmediate() async {
    await _doLoadFiles();
    await _doLoadFoldersTags();
  }

  /// 立即加载文件（不使用防抖）
  Future<void> loadFilesImmediate() async {
    await _doLoadFiles();
  }

  /// 加载文件夹和标签（带防抖）
  Future<void> loadFoldersTags() async {
    _loadFoldersTagsSubject.add(null);
  }

  /// 实际执行文件夹和标签加载的方法
  Future<void> _doLoadFoldersTags() async {
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

  /// 立即加载文件夹和标签（不使用防抖）
  Future<void> loadFoldersTagsImmediate() async {
    await _doLoadFoldersTags();
  }

  /// 加载文件列表（带防抖）
  Future<void> loadFiles() async {
    _loadFilesSubject.add(null);
  }

  /// 实际执行文件加载的方法
  Future<void> _doLoadFiles() async {
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
    // 分页操作使用立即加载，然后滚动到顶部
    loadFilesImmediate().then((_) {
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
    LibraryTabManager.setValue(tabId, 'sortOptions', newSortOptions);
    loadFiles();
  }

  /// 清理事件监听
  void dispose() {
    for (final key in state.eventSubscribes) {
      EventManager.instance.unsubscribe(key);
    }

    // 清理 LibraryEventManager 的订阅
    eventSubscription.cancel();
    tagsUpdateSubscription?.cancel();
    folderUpdateSubscription?.cancel();

    // 清理防抖相关资源
    _loadFilesSubscription.cancel();
    _loadFilesSubject.close();
    _loadFoldersTagsSubscription.cancel();
    _loadFoldersTagsSubject.close();
  }

  // ===== Values 更新逻辑 =====

  /// 设置值变化监听器
  void setupValueListeners(Map<String, ValueNotifier<dynamic>> values) {
    // 首先同步初始值
    _syncValuesToState(values);

    // 监听分页选项变化
    values['paginationOptions']?.addListener(() {
      state.paginationOptionsNotifier.value = Map<String, dynamic>.from(
        values['paginationOptions']!.value,
      );
      _updateStoredValue(
        'paginationOptions',
        values['paginationOptions']!.value,
      );
    });

    // 监听排序选项变化
    values['sortOptions']?.addListener(() {
      state.sortOptionsNotifier.value = Map<String, dynamic>.from(
        values['sortOptions']!.value,
      );
      _updateStoredValue('sortOptions', values['sortOptions']!.value);
    });

    // 监听每行图片数变化
    values['imagesPerRow']?.addListener(() {
      _updateStoredValue('imagesPerRow', values['imagesPerRow']!.value);
    });

    // 监听过滤器变化
    values['filter']?.addListener(() {
      state.filterOptionsNotifier.value = Map<String, dynamic>.from(
        values['filter']!.value,
      );
      _updateStoredValue('filter', values['filter']!.value);
    });

    // 监听显示字段变化
    values['displayFields']?.addListener(() {
      state.displayFieldsNotifier.value = Set<String>.from(
        values['displayFields']!.value,
      );
      _updateStoredValue('displayFields', values['displayFields']!.value);
    });

    // 监听需要更新状态变化
    values['needUpdate']?.addListener(() {
      tabData.needUpdate = values['needUpdate']!.value;
    });
  }

  /// 同步 dock values 到 state
  void _syncValuesToState(Map<String, ValueNotifier<dynamic>> values) {
    // 同步分页选项
    if (values['paginationOptions'] != null) {
      state.paginationOptionsNotifier.value = Map<String, dynamic>.from(
        values['paginationOptions']!.value,
      );
    }

    // 同步排序选项
    if (values['sortOptions'] != null) {
      state.sortOptionsNotifier.value = Map<String, dynamic>.from(
        values['sortOptions']!.value,
      );
    }

    // 同步过滤器选项
    if (values['filter'] != null) {
      state.filterOptionsNotifier.value = Map<String, dynamic>.from(
        values['filter']!.value,
      );
    }

    // 同步显示字段
    if (values['displayFields'] != null) {
      state.displayFieldsNotifier.value = Set<String>.from(
        values['displayFields']!.value,
      );
    }
  }

  /// 更新stored值并保存
  void _updateStoredValue(
    String key,
    dynamic value, {
    bool skipBroadcast = false,
  }) {
    tabData.stored[key] = value;

    // 只有在不跳过广播时才发送事件
    // 这避免了在响应外部更新时造成的循环调用
    if (!skipBroadcast) {
      // 这里会通过DockManager来保存数据
      // TODO: 数据保存到本地
      LibraryEventManager.instance.broadcast(
        'tab::doUpdate',
        MapEventArgs({'tabId': tabData.tabId}),
      );
    }
  }

  /// 初始化values
  static Map<String, ValueNotifier<dynamic>> initializeValues(
    LibraryTabData tabData,
    Map<String, ValueNotifier<dynamic>>? initialValues,
  ) {
    final values = initialValues ?? <String, ValueNotifier<dynamic>>{};

    // 从stored数据中初始化动态值
    final stored = tabData.stored;

    values['paginationOptions'] = ValueNotifier(
      stored['paginationOptions'] ?? {'page': 1, 'perPage': 1000},
    );
    values['sortOptions'] = ValueNotifier(
      stored['sortOptions'] ?? {'field': 'id', 'order': 'desc'},
    );
    values['imagesPerRow'] = ValueNotifier(stored['imagesPerRow'] ?? 0);
    values['filter'] = ValueNotifier(stored['filter'] ?? {});
    values['displayFields'] = ValueNotifier(
      stored['displayFields'] ?? ['title', 'notes', 'tags', 'folder', 'ext'],
    );
    values['needUpdate'] = ValueNotifier(tabData.needUpdate);

    return values;
  }

  /// 获取stored值
  T? getStoredValue<T>(String key, [T? defaultValue]) {
    final stored = tabData.stored;
    return stored[key] as T? ?? defaultValue;
  }

  /// 设置stored值
  void setStoredValue(
    String key,
    dynamic value,
    Map<String, ValueNotifier<dynamic>> values,
  ) {
    tabData.stored[key] = value;
  }

  /// 处理外部值更新（比如从UI组件直接更新dock values）
  /// 这个方法会同步值到state但不触发refresh，避免循环
  void handleExternalValueUpdate(
    String key,
    dynamic value,
    Map<String, ValueNotifier<dynamic>> values,
  ) {
    // 更新stored值
    _updateStoredValue(key, value, skipBroadcast: true);

    // 同步到state
    switch (key) {
      case 'paginationOptions':
        state.paginationOptionsNotifier.value = Map<String, dynamic>.from(
          value,
        );
        break;
      case 'sortOptions':
        state.sortOptionsNotifier.value = Map<String, dynamic>.from(value);
        break;
      case 'filter':
        state.filterOptionsNotifier.value = Map<String, dynamic>.from(value);
        break;
      case 'displayFields':
        state.displayFieldsNotifier.value = Set<String>.from(value);
        break;
    }

    // 立即触发数据加载，但不广播事件避免循环
    if (key == 'filter' || key == 'sortOptions' || key == 'paginationOptions') {
      loadFilesImmediate();
    }
  }
}
