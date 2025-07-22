import 'package:flutter/material.dart';
import 'package:mira/core/event/event_args.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:uuid/uuid.dart';
import '../models/library.dart';

class LibraryTabManager {
  final Map<String, dynamic> tabDatas = {};
  final ValueNotifier<int> currentIndex;
  late final LibrariesPlugin plugin;

  LibraryTabManager(this.currentIndex) {
    plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
  }

  void _handlePageChange() {
    // 保留方法但不再使用，因为我们现在使用IndexedStack
  }

  void addTab(Library library, {bool isRecycleBin = false}) {
    tabDatas[Uuid().v4()] = {
      'library': library,
      'isPinned': false,
      'isRecycleBin': isRecycleBin,
      'create_date': DateTime.now(),
      'pageOptions': {'page': 1, 'perPage': 20},
      'filter': {},
      'displayFields': <String>{
        'title',
        'rating',
        'notes',
        'createdAt',
        'tags',
        'folder',
        'size',
      },
    };
    currentIndex.value = tabDatas.length - 1;
  }

  void closeTabIndex(int index) {
    final tabData = getTabIds()[index];
    tabDatas.remove(tabData);
    onPageChange('close', index);
  }

  void onPageChange(String reason, int index) {
    final len = getTabIds().length;
    int newIndex = -1;
    switch (reason) {
      case 'close':
        if (currentIndex.value == index) {
          newIndex = index == 0 ? len - 1 : index - 1;
        }
        break;
    }
    if (newIndex != -1) {
      currentIndex.value = len - 1;
    }
  }

  void closeTab(String tabId) {
    final index = getTabIds().indexOf(tabId);
    if (index != -1) {
      closeTabIndex(index);
    }
  }

  Map<String, dynamic> map(Function callback) {
    return tabDatas.map((key, value) => callback(key, value));
  }

  void closeAllTabs() {
    tabDatas.clear();
    currentIndex.value = 0;
  }

  void dispose() {
    currentIndex.dispose();
  }

  updateCurrentFitler(Map<String, dynamic> filter) {
    final tabData = getCurrentData();
    if (tabData != null) {
      // 合并过滤器
      tabData['filter'] = {...?tabData['filter'], ...filter};
      EventManager.instance.broadcast(
        'library::filter_updated',
        MapEventArgs({
          'library': tabData['library'],
          'filter': tabData['filter'],
        }),
      );
    }
  }

  setLibraryFilter(String tabId, Map<String, dynamic> filter) {}

  Map<String, dynamic> getLibraryFilter(String tabId) {
    final tabData = tabDatas[tabId];
    if (tabData != null) {
      return Map<String, dynamic>.from(tabData['filter'] as Map);
    } else {
      return {};
    }
  }

  List<String> getTabIds() {
    return tabDatas.keys.toList();
  }

  Map<String, dynamic>? getTabData(String tabId) {
    final tabData = tabDatas[tabId];
    if (tabData != null) {
      return tabData;
    } else {
      return null;
    }
  }

  Set<String> getLibraryDisplayFields(String tabId) {
    final tabData = tabDatas[tabId];
    if (tabData != null) {
      return tabData['displayFields'];
    } else {
      return {};
    }
  }

  setLibraryDisplayFields(String tabId, Set<String> fields) {
    final tabData = tabDatas[tabId];
    if (tabData != null) {
      tabData['displayFields'] = fields;
    }
  }

  Map<String, dynamic> getPageOptions(String tabId) {
    final tabData = tabDatas[tabId];
    if (tabData != null) {
      return tabData['pageOptions'];
    } else {
      return {'page': 1, 'perPage': 20};
    }
  }

  String? getCurrentTabId() {
    final tabIds = getTabIds();
    return tabIds.isNotEmpty ? tabIds[currentIndex.value] : null;
  }

  setTabActive(String tabId) {
    final index = getTabIds().indexOf(tabId);
    if (index != -1) {
      currentIndex.value = index;
    }
  }

  dynamic getCurrentData() {
    return tabDatas[getCurrentTabId()];
  }

  Library? getCurrentLibrary() {
    final data = getCurrentData();
    if (data != null) {
      return data['library'];
    }
  }
}
