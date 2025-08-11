import 'package:flutter/material.dart';
import 'package:mira/dock/examples/dock_manager.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view/library_gallery_events.dart';
import 'package:uuid/uuid.dart';
import '../models/library.dart';
import 'library_tab_data.dart';

/// 使用新的注册方法，将 Library 作为 DockItemRegistrar 的一个组件类型
class LibraryDockItemRegistrar {
  static const String type = 'library_tab';

  /// 注册 library_tab 组件到 DockItemRegistrar
  static void register(DockManager manager) {
    manager.registry.register(
      'library_tab',
      builder: (values) {
        // 期望 values 内包含 LibraryTabData 的序列化数据
        final tabDataJson = values['_tabDataJson'] as Map<String, dynamic>?;
        LibraryTabData? tabData;
        if (tabDataJson != null) {
          tabData = LibraryTabData.fromMap(tabDataJson);
        } else {
          // 兼容：从更平铺的字段恢复
          final libMap = values['library'] as Map<String, dynamic>?;
          if (libMap != null) {
            tabData = LibraryTabData(
              tabId: values['tabId'] as String? ?? const Uuid().v4(),
              itemId: values['itemId'] as String? ?? const Uuid().v4(),
              library: Library.fromMap(libMap),
              title: (values['title'] as String?) ?? '',
              isRecycleBin: values['isRecycleBin'] as bool? ?? false,
              createDate:
                  (values['createDate'] as String?) != null
                      ? DateTime.tryParse(values['createDate']) ??
                          DateTime.now()
                      : DateTime.now(),
              stored: Map<String, dynamic>.from(
                values['stored'] as Map<String, dynamic>? ?? const {},
              ),
            );
          }
        }

        if (tabData == null) {
          return const Center(
            child: Text(
              'Library content not available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // 初始化 dock values（和旧实现保持一致键名）
        final initialValues = LibraryGalleryEvents.initializeValues(
          tabData,
          null,
        );
        return LibraryGalleryView(tabData: tabData, dockValues: initialValues);
      },
    );
  }

  /// 通过新的 DockManager API 添加一个库标签页
  static bool addTab(
    Library library, {
    String title = '',
    bool isRecycleBin = false,
    required String tabId,
  }) {
    final manager = DockManager.getInstance()!;
    final tabData = LibraryTabData(
      tabId: tabId,
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

    // 将 tabData 打包为 values
    final values = <String, dynamic>{
      '_tabDataJson': tabData.toJson(),
      'tabId': tabData.tabId,
      'itemId': tabData.itemId,
      'title': tabData.title,
      'isRecycleBin': tabData.isRecycleBin,
      'createDate': tabData.createDate.toIso8601String(),
      'library': library.toMap(),
      'stored': tabData.stored,
      'id': tabData.itemId, // 供 registry 默认按钮使用
    };

    // 选择一个可投放区域（优先 Tabs 或 Item，否则 root）
    DockingArea? targetArea;
    for (final area in manager.layout.layoutAreas()) {
      if (area is DockingTabs) {
        targetArea = area;
        break;
      }
    }
    targetArea ??=
        manager.layout.layoutAreas().firstWhere(
              (a) => a is DockingItem,
              orElse: () => manager.layout.root!,
            )
            as DockingArea?;

    if (targetArea is! DropArea) {
      return false;
    }

    // 添加到布局
    manager.addTypedItem(
      id: tabData.itemId,
      type: type,
      values: values,
      targetArea: targetArea as DropArea,
      // 如果是 Tabs，插入到索引 0；否则靠右放置
      dropIndex: targetArea is DockingTabs ? 0 : null,
      dropPosition: targetArea is DockingTabs ? null : DropPosition.right,
      name: tabData.title.isNotEmpty ? tabData.title : tabData.library.name,
      keepAlive: true,
      closable: true,
      maximizable: true,
    );

    return true;
  }
}
