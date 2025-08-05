import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mira/core/event/event_args.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:uuid/uuid.dart';
import '../models/library.dart';
import 'i_library_tab_manager.dart';

class LibraryTabData {
  final String id;
  final Library library;
  final bool isPinned;
  final bool isRecycleBin;
  bool isActive;
  bool needUpdate;
  String title;
  final DateTime createDate;
  final Map<String, dynamic> stored;

  LibraryTabData({
    this.title = '',
    this.isActive = false,
    this.needUpdate = false,
    required this.id,
    required this.library,
    this.isPinned = false,
    this.isRecycleBin = false,
    required this.createDate,
    required this.stored,
  });

  factory LibraryTabData.fromMap(Map<String, dynamic> map) {
    return LibraryTabData(
      id: map['id'] as String,
      title: map['title'] as String,
      library: Library.fromMap(map['library']),
      isActive: map['isActive'] as bool? ?? false,
      isPinned: map['isPinned'] as bool? ?? false,
      isRecycleBin: map['isRecycleBin'] as bool? ?? false,
      createDate: DateTime.parse(map['create_date'] as String),
      stored: Map<String, dynamic>.from(map['stored'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'library': library.toJson(),
      'isActive': isActive,
      'isPinned': isPinned,
      'isRecycleBin': isRecycleBin,
      'create_date': createDate.toIso8601String(),
      'stored': convertSetsToLists(stored),
    };
  }

  LibraryTabData copyWith({
    String? id,
    String? title,
    Library? library,
    bool? needUpdate,
    bool? isActive,
    bool? isPinned,
    bool? isRecycleBin,
    DateTime? createDate,
    Map<String, dynamic>? stored,
  }) {
    return LibraryTabData(
      id: id ?? this.id,
      title: title ?? this.title,
      library: library ?? this.library,
      needUpdate: needUpdate ?? this.needUpdate,
      isPinned: isPinned ?? this.isPinned,
      isActive: isActive ?? this.isActive,
      isRecycleBin: isRecycleBin ?? this.isRecycleBin,
      createDate: createDate ?? this.createDate,
      stored: stored ?? this.stored,
    );
  }
}

class LibraryTabManager implements ILibraryTabManager {
  late TabController? tabController;
  final List<LibraryTabData> tabDatas = [];
  final ValueNotifier<int> currentIndex;
  late final LibrariesPlugin plugin;
  final StreamController<Map<String, dynamic>> onTabEventStream =
      StreamController.broadcast();
  late final bool _autoSave;
  bool _isLoaded = false;
  List<String> getTabIds() => tabDatas.map((item) => item.id).toList();

  Future<bool> get isLoaded async {
    if (!_isLoaded) {
      await loadfromjson();
    }
    return _isLoaded;
  }

  LibraryTabManager(this.currentIndex, {bool autoSave = true}) {
    _autoSave = autoSave;
    plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
  }

  Future<void> init() async {
    await loadfromjson();
  }

  Future<void> saveToJson() async {
    await plugin.storage.writeJson(
      'tabs',
      tabDatas.map((tab) => tab.toJson()).toList(),
    );
  }

  Future<void> readfromjson() async {
    final data = await plugin.storage.readJson('tabs') ?? [];
    print('load data ${data.length}');
    tabDatas.clear();
    for (var item in (data is Iterable ? data : [])) {
      if (item is Map<String, dynamic>) {
        tabDatas.add(LibraryTabData.fromMap(item));
      }
    }
    _isLoaded = true;
  }

  Future<void> restoreActiveTab() async {
    if (tabDatas.isEmpty) {
      return;
    }
    final activeTab = tabDatas.firstWhereOrNull((item) => item.isActive);
    if (activeTab != null) {
      setTabActive(index: tabDatas.indexOf(activeTab));
    }
  }

  Future<void> loadfromjson() async {
    if (_autoSave) await readfromjson();
  }

  // updateTitle
  void updateTitle(String tabId, String title) {
    final index = getTabIds().indexOf(tabId);
    if (index != -1) {
      tabDatas[index] = tabDatas[index].copyWith(title: title);
      trySaveTabs();
    }
  }

  // 添加tab
  void addTab(Library library, {String title = '', bool isRecycleBin = false}) {
    tabDatas.add(
      LibraryTabData(
        id: Uuid().v4(),
        library: library,
        title: title,
        isRecycleBin: isRecycleBin,
        createDate: DateTime.now(),
        stored: {
          'paginationOptions': {'page': 1, 'perPage': 1000},
          'sortOptions': {'field': 'id', 'order': 'desc'},
          'imagesPerRow': 0,
          'filter': {},
          'displayFields': [
            'title',
            'rating',
            'notes',
            'createdAt',
            'tags',
            'folder',
            'size',
            'ext',
          ],
        },
      ),
    );
    onTabEvent('add', tabDatas.length - 1);
    trySaveTabs();
  }

  void closeTab(String tabId) {
    final index = getTabIds().indexOf(tabId);
    if (index != -1) {
      closeTabIndex(index);
    }
  }

  Future<void> trySaveTabs() async {
    if (_autoSave) {
      await saveToJson();
    }
  }

  Future<void> closeTabIndex(int index) async {
    tabDatas.removeAt(index);
    await trySaveTabs();
    onTabEvent('close', index);
  }

  void onTabEvent(String event, int index) {
    final tabIds = getTabIds();
    final len = tabIds.length;
    final tabId = index >= 0 && index < tabIds.length ? tabIds[index] : null;
    int newIndex = -1;
    switch (event) {
      case 'close':
        if (getCurrentIndex() == index && len > 0) {
          newIndex = index == 0 ? len - 1 : index - 1;
        }
        break;
    }
    onTabEventStream.add({'event': event, 'index': index, 'tabId': tabId});
  }

  // getValue
  dynamic getValue(String tabId, String key, dynamic defaultValue) {
    final tabData = getTabData(tabId);
    if (tabData != null) {
      switch (key) {
        case 'stored':
          return tabData.stored;
      }
    } else {
      return defaultValue;
    }
  }

  // getStoredValue
  dynamic getStoredValue(String tabId, String key, dynamic defaultValue) {
    final value = getValue(tabId, 'stored', {});
    return value[key] ?? defaultValue;
  }

  // setStoreValue
  void setStoreValue(String tabId, String key, dynamic value) {
    final tabData = getTabData(tabId);
    if (tabData != null) {
      final stored = Map<String, dynamic>.from(tabData.stored);
      stored[key] = value;
      setValue(tabId, 'stored', stored);
    }
  }

  void setValue(String tabId, String key, dynamic value) {
    final index = getTabIds().indexOf(tabId);
    final tabData = tabDatas[index];
    LibraryTabData newData;
    if (tabData != null) {
      switch (key) {
        case 'stored':
          newData = tabData.copyWith(stored: value as Map<String, dynamic>);
          break;
        case 'needUpdate':
          newData = tabData.copyWith(needUpdate: value as bool);
          break;
        default:
          return;
      }
      tabDatas[index] = newData;
      trySaveTabs();
    }
  }

  void updateTab(String tabId) {
    print('update tabId $tabId');
    EventManager.instance.broadcast(
      'tab::doUpdate',
      MapEventArgs({'tabId': tabId}),
    );
  }

  void tryUpdate(String tabId) {
    final tabData = getTabData(tabId);
    if (tabData != null && tabData.needUpdate) {
      setValue(tabId, 'needUpdate', false);
      updateTab(tabId);
    }
  }

  void closeAllTabs() {
    tabDatas.clear();
    onTabEventStream.add({'event': 'clear'});
    trySaveTabs();
    setCurrentIndex(0);
  }

  updateFilter(String tabId, Map<String, dynamic> filter) {
    final tabData = getTabData(tabId);
    if (tabData != null && tabId != null) {
      // 合并过滤器
      final newFilter = {...getStoredValue(tabId, 'filter', {}), ...filter};
      tabData.stored['filter'] = newFilter;
      tabData.stored['paginationOptions']['page'] = 1;
      setValue(tabId, 'stored', tabData.stored);
      EventManager.instance.broadcast(
        'filter::updated',
        MapEventArgs({
          'library': tabData.library,
          'tabId': tabId,
          'filter': newFilter,
        }),
      );
    }
  }

  setSortOptions(String tabId, Map<String, dynamic> sortOptions) {
    final tabData = getTabData(tabId);
    if (tabData != null && tabId != null) {
      setStoreValue(tabId, 'sortOptions', sortOptions);
      EventManager.instance.broadcast(
        'sort::updated',
        MapEventArgs({
          'library': tabData.library,
          'tabId': tabId,
          'sort': sortOptions,
        }),
      );
    }
  }

  LibraryTabData? getTabData(String tabId) {
    return tabDatas.firstWhereOrNull((element) => element.id == tabId);
  }

  String? getCurrentTabId() {
    final tabIds = getTabIds();
    final index = getCurrentIndex();
    return tabIds.isNotEmpty && index < tabIds.length && index != -1
        ? tabIds[index]
        : null;
  }

  Future<void> setTabActive({int? index, String? tabId}) async {
    if (tabId != null) {
      setCurrentIndex(getTabIds().indexOf(tabId));
    } else if (index != null) {
      setCurrentIndex(index);
    }
  }

  setCurrentIndex(int index) {
    if (index < 0 || index >= tabDatas.length) {
      return;
    }
    tabController?.animateTo(index);
  }

  int getCurrentIndex() {
    return tabController?.index ?? 0;
  }

  Future<void> onTabActived({int? index, String? tabId}) async {
    if (tabId != null) {
      index = getTabIds().indexOf(tabId);
    }
    if (index == null || index >= tabDatas.length || index < 0) {
      return;
    }
    final lastIndex = getCurrentIndex();
    if (lastIndex != -1) {
      onTabEvent('unactive', lastIndex);
    }

    // 遍历所有tabData，将isActive设置为false
    for (final item in tabDatas) {
      item.isActive = false;
    }
    final tabData = tabDatas.elementAt(index);
    tabData.isActive = true;
    setCurrentIndex(index);
    onTabEvent('active', index);
    trySaveTabs();
  }

  void dispose() {
    currentIndex.dispose();
  }
}
