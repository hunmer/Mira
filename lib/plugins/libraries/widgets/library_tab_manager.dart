import 'dart:async';

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
  // onTabUpdate stream
  final StreamController<Map<String, dynamic>> onTabEventStream =
      StreamController.broadcast();
  List<String> getTabIds() => tabDatas.keys.toList();

  LibraryTabManager(this.currentIndex) {
    plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
  }

  // 添加tab
  void addTab(Library library, {bool isRecycleBin = false}) {
    tabDatas[Uuid().v4()] = {
      'library': library,
      'isPinned': false,
      'isRecycleBin': isRecycleBin,
      'create_date': DateTime.now(),
      'pageOptions': {'page': 1, 'perPage': 100},
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
    onTabEvent('add', currentIndex.value);
  }

  void closeTabIndex(int index) {
    final tabData = getTabIds()[index];
    tabDatas.remove(tabData);
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
    final tabData = getTabData(tabId);
    if (tabData != null) {
      tabData[key] = value;
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
    final tabData = getTabData(tabId) ?? {};
    if (tabData.containsKey('needUpdate') && tabData['needUpdate']) {
      updateTab(tabId);
      tabData['needUpdate'] = false;
    }
  }

  Map<String, dynamic> map(Function(String, Map<String, dynamic>) callback) {
    return tabDatas.map((key, value) {
      final result = callback(key, value);
      return result ?? MapEntry(key, value);
    });
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
    return tabIds.isNotEmpty && currentIndex.value < tabIds.length
        ? tabIds[currentIndex.value]
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
