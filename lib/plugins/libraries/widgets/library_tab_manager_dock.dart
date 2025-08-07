import 'package:mira/dock/dock_manager.dart';
import 'library_tab_data.dart';
import '../models/library.dart';
import 'library_dock_item.dart';

/// LibraryTabManager的dock适配器
/// 提供与原LibraryTabManager兼容的接口，但使用dock系统作为后端
class LibraryTabManager {
  /// 获取存储值

  static dynamic getValue(
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
    Map<String, dynamic> filter, {
    bool overwrite = true,
  }) {
    DockManager.updateLibraryTabValue(tabId, itemId, 'filter', {
      ...getCurrentFilter(tabId, itemId),
      ...filter,
    }, overwrite: overwrite);

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
  static void setValue(String tabId, String itemId, String key, dynamic value) {
    DockManager.updateLibraryTabValue(tabId, itemId, key, value);
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
