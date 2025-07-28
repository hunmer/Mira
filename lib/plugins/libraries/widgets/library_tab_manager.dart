import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mira/core/event/event_args.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:uuid/uuid.dart';
import '../models/library.dart';

class LibraryTabData {
  final String id;
  final Library library;
  final bool isPinned;
  final bool isRecycleBin;
  bool isActive;
  bool needUpdate;
  String title;
  final DateTime createDate;
  Map<String, dynamic> pageOptions;
  final Map<String, dynamic> filter;
  final Set<String> displayFields;

  LibraryTabData({
    this.title = '',
    this.isActive = false,
    this.needUpdate = false,
    required this.id,
    required this.library,
    this.isPinned = false,
    this.isRecycleBin = false,
    required this.createDate,
    this.pageOptions = const {'page': 1, 'perPage': 1000},
    this.filter = const {},
    this.displayFields = const {},
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
      pageOptions: Map<String, dynamic>.from(map['pageOptions'] as Map),
      filter: Map<String, dynamic>.from(map['filter'] as Map),
      displayFields: Set<String>.from(map['displayFields'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'library': library,
      'isActive': isActive,
      'isPinned': isPinned,
      'isRecycleBin': isRecycleBin,
      'create_date': createDate.toIso8601String(),
      'pageOptions': pageOptions,
      'filter': filter,
      'displayFields': displayFields.toList(),
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
    Map<String, dynamic>? pageOptions,
    Map<String, dynamic>? filter,
    Set<String>? displayFields,
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
      pageOptions: pageOptions ?? this.pageOptions,
      filter: filter ?? this.filter,
      displayFields: displayFields ?? this.displayFields,
    );
  }
}

class LibraryTabManager {
  final List<LibraryTabData> tabDatas = [];
  final ValueNotifier<int> currentIndex;
  late final LibrariesPlugin plugin;
  final StreamController<Map<String, dynamic>> onTabEventStream =
      StreamController.broadcast();
  late final bool autoSave;
  bool _isLoaded = false;
  List<String> getTabIds() => tabDatas.map((item) => item.id).toList();
  Future<bool> get isLoaded async {
    await loadfromjson();
    return _isLoaded;
  }

  LibraryTabManager(this.currentIndex, {this.autoSave = true}) {
    plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
  }

  Future<void> init() async {
    await loadfromjson();
  }

  // savetoJson
  Future<void> savetoJson() async {
    await plugin.storage.writeJson('tabs.json', tabDatas);
  }

  // readfromjson
  Future<void> readfromjson() async {
    final data = await plugin.storage.readJson('tabs.json') ?? [];
    print('load data ${data.length}');
    tabDatas.clear();
    for (var item in data) {
      if (item is Map<String, dynamic>) {
        // 重置
        item['filter'] = {};
        item['displayFields'] = [];
        item['pageOptions'] = {'page': 1, 'perPage': 1000};
        final tabData = LibraryTabData.fromMap(item);
        tabDatas.add(tabData);
      }
    }
    _isLoaded = true;
  }

  // loadfromjson
  Future<void> loadfromjson() async {
    if (!_isLoaded && autoSave) await readfromjson();
  }

  // 添加tab
  void addTab(Library library, {bool isRecycleBin = false}) {
    tabDatas.add(
      LibraryTabData(
        id: Uuid().v4(),
        library: library,
        isRecycleBin: isRecycleBin,
        createDate: DateTime.now(),
        displayFields: {
          'title',
          'rating',
          'notes',
          'createdAt',
          'tags',
          'folder',
          'size',
        },
      ),
    );
    trySaveTabs();
    currentIndex.value = tabDatas.length - 1;
    onTabEvent('add', currentIndex.value);
  }

  Future<void> trySaveTabs() async {
    if (autoSave) {
      await savetoJson();
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
        if (currentIndex.value == index) {
          newIndex = index == 0 ? len - 1 : index - 1;
        }
        break;
    }
    onTabEventStream.add({'event': event, 'index': index, 'tabId': tabId});
  }

  void closeTab(String tabId) {
    final index = getTabIds().indexOf(tabId);
    if (index != -1) {
      closeTabIndex(index);
    }
  }

  void setValue(String tabId, String key, dynamic value) {
    final index = getTabIds().indexOf(tabId);
    final tabData = tabDatas[index];
    LibraryTabData newData;
    if (tabData != null) {
      switch (key) {
        case 'filter':
          newData = tabData.copyWith(filter: value as Map<String, dynamic>);
          break;
        case 'displayFields':
          newData = tabData.copyWith(displayFields: value as Set<String>);
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

  // updateTab
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
      updateTab(tabId);
      setValue(tabId, 'needUpdate', false);
    }
  }

  void closeAllTabs() {
    tabDatas.clear();
    onTabEventStream.add({'event': 'clear'});
    trySaveTabs();
    currentIndex.value = 0;
  }

  void dispose() {
    currentIndex.dispose();
  }

  updateFilter(String tabId, Map<String, dynamic> filter) {
    final tabData = getTabData(tabId);
    if (tabData != null && tabId != null) {
      // 合并过滤器
      final newFilter = {...tabData.filter, ...filter};
      setValue(tabId, 'filter', newFilter);
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

  setLibraryFilter(String tabId, Map<String, dynamic> filter) {}

  Map<String, dynamic> getLibraryFilter(String tabId) {
    final tabData = getTabData(tabId);
    if (tabData != null) {
      return tabData.filter;
    } else {
      return {};
    }
  }

  LibraryTabData? getTabData(String tabId) {
    return tabDatas.firstWhereOrNull((element) => element.id == tabId);
  }

  Set<String> getLibraryDisplayFields(String tabId) {
    final tabData = getTabData(tabId);
    if (tabData != null) {
      return tabData.displayFields;
    } else {
      return {};
    }
  }

  setLibraryDisplayFields(String tabId, Set<String> fields) {
    setValue(tabId, 'displayFields', fields);
  }

  Map<String, dynamic> getPageOptions(String tabId) {
    final tabData = getTabData(tabId);
    if (tabData != null) {
      return tabData.pageOptions;
    } else {
      return {'page': 1, 'perPage': 100};
    }
  }

  String? getCurrentTabId() {
    final tabIds = getTabIds();
    final index = currentIndex.value;
    return tabIds.isNotEmpty && index < tabIds.length && index != -1
        ? tabIds[index]
        : null;
  }

  setTabActive(String tabId) {
    if (currentIndex.value != -1) {
      onTabEvent('unactive', currentIndex.value);
    }
    final index = getTabIds().indexOf(tabId);
    if (index != -1) {
      currentIndex.value = index;
      onTabEvent('active', index);
    }
  }

  setActive(int index) {
    final tabData = tabDatas.elementAt(index);
    setTabActive(tabData.id);
  }
}
