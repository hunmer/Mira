import 'package:mira/dock/dock_manager.dart';
import 'library_tab_manager.dart';
import 'i_library_tab_manager.dart';
import '../models/library.dart';
import 'library_dock_item.dart';

/// LibraryTabManager的dock适配器
/// 提供与原LibraryTabManager兼容的接口，但使用dock系统作为后端
class LibraryTabManagerDockAdapter implements ILibraryTabManager {
  /// 获取存储值
  dynamic getStoredValue(String tabId, String key, dynamic defaultValue) {
    return DockManager.getLibraryTabStoredValue(
      tabId,
      key,
      defaultValue: defaultValue,
    );
  }

  /// 更新过滤器
  void updateFilter(String tabId, Map<String, dynamic> filter) {
    DockManager.updateLibraryTabStoredValue(tabId, 'filter', {
      ..._getCurrentFilter(tabId),
      ...filter,
    });

    // 重置分页到第一页
    DockManager.updateLibraryTabStoredValue(tabId, 'paginationOptions', {
      'page': 1,
      'perPage': 1000,
    });
  }

  /// 获取当前过滤器
  Map<String, dynamic> _getCurrentFilter(String tabId) {
    return DockManager.getLibraryTabStoredValue<Map<String, dynamic>>(
          tabId,
          'filter',
          defaultValue: <String, dynamic>{},
        ) ??
        <String, dynamic>{};
  }

  /// 获取tab数据 - 从dock系统中获取
  @override
  LibraryTabData? getTabData(String tabId) {
    // 首先尝试从dock系统获取DockItem
    final dockItem = DockManager.getDockItem('main', 'home', 'library_$tabId');

    if (dockItem != null && dockItem is LibraryDockItem) {
      return dockItem.tabData;
    }

    // 如果找不到，返回null
    // 调用者应该处理这种情况
    return null;
  }

  /// 设置存储值
  void setStoreValue(String tabId, String key, dynamic value) {
    DockManager.updateLibraryTabStoredValue(tabId, key, value);
  }

  /// 设置值
  void setValue(String tabId, String key, dynamic value) {
    // 根据key的不同，映射到dock系统的不同存储位置
    switch (key) {
      case 'stored':
        if (value is Map<String, dynamic>) {
          for (final entry in value.entries) {
            DockManager.updateLibraryTabStoredValue(
              tabId,
              entry.key,
              entry.value,
            );
          }
        }
        break;
      case 'needUpdate':
        DockManager.updateLibraryTabStoredValue(tabId, 'needUpdate', value);
        break;
      default:
        DockManager.updateLibraryTabStoredValue(tabId, key, value);
    }
  }

  /// 尝试更新
  void tryUpdate(String tabId) {
    final needUpdate = getStoredValue(tabId, 'needUpdate', false);
    if (needUpdate == true) {
      setValue(tabId, 'needUpdate', false);
      // 广播更新事件
      // EventManager.instance.broadcast('tab::doUpdate', MapEventArgs({'tabId': tabId}));
    }
  }

  /// 设置排序选项
  @override
  void setSortOptions(String tabId, Map<String, dynamic> sortOptions) {
    DockManager.updateLibraryTabStoredValue(tabId, 'sortOptions', sortOptions);
  }

  @override
  String? getCurrentTabId() {
    // TODO: 需要在DockManager中实现获取当前活动tab的逻辑
    return null;
  }

  @override
  void addTab(Library library, {String title = '', bool isRecycleBin = false}) {
    // 使用dock系统添加库标签页
    DockManager.addLibraryTab(
      library,
      title: title,
      isRecycleBin: isRecycleBin,
    );
  }
}
