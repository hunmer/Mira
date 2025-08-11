import 'package:mira/dock/examples/dock_manager.dart';

import 'library_tab_data.dart';

/// LibraryTabManager的dock适配器
/// 提供与原LibraryTabManager兼容的接口，但使用dock系统作为后端
class LibraryTabManager {
  // 存储全局DockManager实例的静态变量，由LibraryTabsView设置
  static DockManager? _globalDockManager;

  /// 设置全局DockManager实例
  static void setGlobalDockManager(DockManager manager) {
    _globalDockManager = manager;
  }

  /// 获取全局DockManager实例
  static DockManager? get globalDockManager => _globalDockManager;

  /// 获取存储值
  static dynamic getValue(String tabId, String key, dynamic defaultValue) {
    if (_globalDockManager == null) {
      return defaultValue;
    }

    // 从item的values中获取存储的数据
    final itemData = _globalDockManager!.itemDataCache[tabId];
    if (itemData != null) {
      final storedData = itemData.values['stored'];
      return storedData?[key] ?? defaultValue;
    }

    return defaultValue;
  }

  /// 更新过滤器
  static void updateFilter(
    String tabId,
    Map<String, dynamic> filter, {
    bool overwrite = true,
  }) {
    _updateStoredValue(tabId, 'filter', {
      ...getCurrentFilter(tabId),
      ...filter,
    });

    // 重置分页到第一页
    _updateStoredValue(tabId, 'paginationOptions', {
      'page': 1,
      'perPage': 1000,
    });
  }

  /// 获取当前过滤器
  static Map<String, dynamic> getCurrentFilter(String tabId) {
    final value = getValue(tabId, 'filter', <String, dynamic>{});
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  /// 获取tab数据 - 从dock系统中获取
  static LibraryTabData? getTabData(String tabId) {
    if (_globalDockManager == null) {
      return null;
    }

    final itemData = _globalDockManager!.itemDataCache[tabId];
    if (itemData != null) {
      final tabDataJson = itemData.values as Map<String, dynamic>?;
      if (tabDataJson != null) {
        return LibraryTabData.fromMap(tabDataJson);
      }
    }

    return null;
  }

  /// 设置存储值
  static void setValue(String tabId, String key, dynamic value) {
    _updateStoredValue(tabId, key, value);
  }

  /// 设置排序选项
  static void setSortOptions(String tabId, Map<String, dynamic> sortOptions) {
    _updateStoredValue(tabId, 'sortOptions', sortOptions);
  }

  /// 内部方法：更新存储值
  static void _updateStoredValue(String tabId, String key, dynamic value) {
    if (_globalDockManager == null) {
      return;
    }

    final itemData = _globalDockManager!.itemDataCache[tabId];
    if (itemData != null) {
      // 更新stored数据
      final storedData = Map<String, dynamic>.from(itemData.values['stored']);
      storedData[key] = value;

      // 更新values
      var newValues = Map<String, dynamic>.from(itemData.values);
      newValues['stored'] = storedData;

      final tabDataJson = newValues as Map<String, dynamic>?;
      if (tabDataJson != null) {
        final tabData = LibraryTabData.fromMap(tabDataJson);
        tabData.stored[key] = value;
        newValues = tabData.toJson();
      }

      // 通过DockManager更新item values
      _globalDockManager!.updateItemValues(tabId, newValues);

      // 根据键名发布对应的广播
      _globalDockManager!.broadcastTabEvent(tabId, '${key}_changed', {
        'key': key,
        'value': value,
      });
    }
  }
}
