import 'package:flutter/material.dart';
import 'package:mira/dock/dock_item.dart';
import 'package:mira/dock/dock_manager.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view/library_gallery_events.dart';
import 'package:uuid/uuid.dart';
import '../models/library.dart';
import 'library_tab_data.dart';

/// LibraryDockItem - 继承自DockItem的库标签页项目
class LibraryDockItem extends DockItem {
  final LibraryTabData tabData;
  static bool _isBuilderRegistered = false;

  LibraryDockItem({
    required this.tabData,
    Map<String, ValueNotifier<dynamic>>? initialValues,
  }) : super(
         type: 'library_tab',
         id: tabData.itemId,
         title: tabData.title.isNotEmpty ? tabData.title : tabData.library.name,
         values: LibraryGalleryEvents.initializeValues(tabData, initialValues),
         builder: (item) {
           final libraryItem = item as LibraryDockItem;
           return DockingItem(
             id: Uuid().v4(),
             name: item.title,
             closable: true,
             keepAlive: true, // 启用keepAlive
             widget: LibraryGalleryView(
               // 移除额外的key，让DockingItem的keepAlive机制处理
               tabData: tabData,
               dockValues: item.values, // 传递dock values
             ),
           );
         },
       ) {
    // 确保builder已注册
    _ensureBuilderRegistered();

    // 值变化监听器的设置现在在 LibraryGalleryEvents 中处理
  }

  /// 确保library_tab类型的builder已经注册
  static void _ensureBuilderRegistered() {
    if (!_isBuilderRegistered) {
      registerLibraryTabBuilder();
      _isBuilderRegistered = true;
    }
  }

  /// 注册library_tab类型的builder
  static void registerLibraryTabBuilder() {
    DockManager.registerBuilder('library_tab', (dockItem) {
      // 从dockItem中获取LibraryDockItem的实例
      if (dockItem is LibraryDockItem) {
        return dockItem.buildDockingItem();
      }

      // 如果不是LibraryDockItem实例，尝试从values中重建
      try {
        // 尝试从保存的值中恢复LibraryTabData
        final tabDataJson =
            dockItem.getValue('_tabDataJson') as Map<String, dynamic>?;

        if (tabDataJson != null) {
          // 重建LibraryTabData
          final tabData = LibraryTabData.fromMap(tabDataJson);

          // 创建新的LibraryDockItem，传递已有的values
          final libraryDockItem = LibraryDockItem(
            tabData: tabData,
            initialValues: dockItem.values,
          );

          // 创建DockingItem时也传递values
          return DockingItem(
            id: Uuid().v4(),
            name: dockItem.title,
            closable: true,
            keepAlive: true,
            widget: LibraryGalleryView(
              tabData: tabData,
              dockValues: dockItem.values, // 传递dock values
            ),
          );
        }
      } catch (e) {
        print('LibraryDockItem: Error restoring from saved data: $e');
      }

      // 如果无法重建，显示错误信息
      return DockingItem(
        id: 'library_${dockItem.title}',
        name: dockItem.title,
        closable: true,
        keepAlive: true, // 启用keepAlive
        widget: const Center(
          child: Text(
            'Library content not available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    });

    print('LibraryDockItem: Registered library_tab builder');
  }

  /// 静态方法：手动注册builder（供外部调用）
  static void ensureRegistered() {
    _ensureBuilderRegistered();
  }

  /// 静态方法：添加库标签页
  static bool addTab(
    Library library, {
    String title = '',
    bool isRecycleBin = false,
    String dockTabsId = 'main',
    required String dockTabId,
  }) {
    final tabData = LibraryTabData(
      tabId: dockTabId,
      itemId: const Uuid().v4(),
      library: library,
      title: title,
      isRecycleBin: isRecycleBin,
      createDate: DateTime.now(),
      stored: {
        'paginationOptions': {'page': 1, 'perPage': 1000},
        'sortOptions': {'field': 'id', 'order': 'desc'},
        'imagesPerRow': 0,
        'filter': {},
        'displayFields': ['title', 'notes', 'tags', 'folder', 'ext'],
      },
    );

    final libraryDockItem = LibraryDockItem(tabData: tabData);

    // 通过DockManager添加到dock系统
    final success = DockManager.addDockItem(
      dockTabsId,
      dockTabId,
      libraryDockItem,
    );
    return success;
  }
}
