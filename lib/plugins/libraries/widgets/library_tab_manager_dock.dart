import 'package:mira/dock/dock_manager.dart';
import 'library_tab_data.dart';
import '../models/library.dart';
import 'library_dock_item.dart';

/// LibraryTabManager的dock适配器
/// 提供与原LibraryTabManager兼容的接口，但使用dock系统作为后端
class LibraryTabManager {
  /// 获取存储值

  static dynamic getStoredValue(
    String tabId,
    String itemId,
    String key,
    dynamic defaultValue,
  ) {
    return DockManager.getLibraryTabValue(
      tabId,
      itemId,
      key,
      defaultValue: defaultValue,
    );
  }

  /// 更新过滤器

  static void updateFilter(
    String tabId,
    String itemId,
    Map<String, dynamic> filter,
  ) {
    DockManager.updateLibraryTabValue(tabId, itemId, 'filter', {
      ...getCurrentFilter(tabId, itemId),
      ...filter,
    });

    // 重置分页到第一页
    DockManager.updateLibraryTabValue(tabId, itemId, 'paginationOptions', {
      'page': 1,
      'perPage': 1000,
    });
  }

  /// 获取当前过滤器
  static Map<String, dynamic> getCurrentFilter(String tabId, String itemId) {
    return DockManager.getLibraryTabValue<Map<String, dynamic>>(
          tabId,
          itemId,
          'filter',
          defaultValue: <String, dynamic>{},
        ) ??
        <String, dynamic>{};
  }

  /// 获取tab数据 - 从dock系统中获取

  static LibraryTabData? getTabData(String tabId, String itemId) {
    // 首先尝试从dock系统获取DockItem
    final dockItem = DockManager.getDockItemById('main', tabId, itemId);

    if (dockItem != null && dockItem is LibraryDockItem) {
      return dockItem.tabData;
    }
    return null;
  }

  /// 设置存储值

  static void setStoreValue(
    String tabId,
    String itemId,
    String key,
    dynamic value,
  ) {
    DockManager.updateLibraryTabValue(tabId, itemId, key, value);
  }

  /// 设置值

  static void setValue(String tabId, String itemId, String key, dynamic value) {
    // 根据key的不同，映射到dock系统的不同存储位置
    switch (key) {
      case 'stored':
        if (value is Map<String, dynamic>) {
          for (final entry in value.entries) {
            DockManager.updateLibraryTabValue(
              tabId,
              itemId,
              entry.key,
              entry.value,
            );
          }
        }
        break;
      case 'needUpdate':
        DockManager.updateLibraryTabValue(tabId, itemId, 'needUpdate', value);
        break;
      default:
        DockManager.updateLibraryTabValue(tabId, itemId, key, value);
    }
  }

  /// 尝试更新

  static void tryUpdate(String tabId, String itemId) {
    final needUpdate = getStoredValue(tabId, itemId, 'needUpdate', false);
    if (needUpdate == true) {
      setValue(tabId, itemId, 'needUpdate', false);
      // 广播更新事件
      // EventManager.instance.broadcast('tab::doUpdate', MapEventArgs({'tabId': tabId}));
    }
  }

  /// 设置排序选项

  static void setSortOptions(
    String tabId,
    String itemId,
    Map<String, dynamic> sortOptions,
  ) {
    DockManager.updateLibraryTabValue(
      tabId,
      itemId,
      'sortOptions',
      sortOptions,
    );
  }

  static String? getCurrentTabId() {
    // TODO: 需要在DockManager中实现获取当前活动tab的逻辑
    return null;
  }

  static void addTab(
    Library library, {
    String title = '',
    bool isRecycleBin = false,
    String dockTabsId = 'main',
    String? dockTabId,
  }) {
    // 使用dock系统添加库标签页
    // DockManager.addDockItem(
    //   dockTabsId,
    //   dockTabId,
    //   LibraryDockItem(tabData: LibraryTabData(library: library, createDate: createDate, stored: stored)),
    // );
  }
}
