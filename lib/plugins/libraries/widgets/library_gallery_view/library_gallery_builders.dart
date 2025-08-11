import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_data.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/examples/dock_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'library_gallery_events.dart';
import 'library_gallery_state.dart';

/// 图库视图的UI构建器类
class LibraryGalleryBuilders {
  final LibraryGalleryState state;
  final LibraryGalleryEvents events;
  final LibrariesPlugin plugin;
  final Library library;
  late final String tabId;
  late final String itemId;
  final VoidCallback? onShowDropDialog;
  final Function(LibraryFile) onFileOpen;
  final Function(LibraryFile) onFileSelected;
  final Function(LibraryFile) onToggleSelected;
  late BuildContext context;
  final LibraryTabData tabData;

  LibraryGalleryBuilders({
    required this.state,
    required this.events,
    required this.plugin,
    required this.library,
    required this.tabData,
    this.onShowDropDialog,
    required this.onFileOpen,
    required this.onFileSelected,
    required this.onToggleSelected,
  }) {
    tabId = tabData.tabId;
    itemId = tabData.itemId;
  }

  /// 构建响应式布局
  Widget build(BuildContext context, bool isRecycleBin) {
    this.context = context;
    return _buildDockingLayout(context, {
      'type': 'row',
      'items': [
        {
          'id': 'quick_actions',
          'name': 'Quick Actions',
          'type': 'item',
          'closable': true,
          'maximizable': false,
          'keepAlive': true,
          'size': 60.0,
        },
        {
          'id': 'sidebar',
          'name': 'Sidebar',
          'type': 'item',
          'closable': true,
          'maximizable': false,
          'keepAlive': true,
          'weight': 0.15,
          'minimalSize': 150.0,
        },
        {
          'id': 'main_content',
          'name': 'Library Content',
          'type': 'item',
          'closable': true,
          'maximizable': true,
          'keepAlive': true,
          'weight': 0.6,
        },
        {
          'id': 'details',
          'name': 'Details',
          'type': 'item',
          'closable': true,
          'maximizable': false,
          'keepAlive': true,
          'weight': 0.2,
        },
        {
          'id': 'app_bar_actions',
          'name': 'Actions',
          'type': 'item',
          'closable': true,
          'maximizable': false,
          'keepAlive': true,
          'size': 60.0,
        },
      ],
    }, isRecycleBin);
  }

  /// 构建 Docking 布局
  Widget _buildDockingLayout(
    BuildContext context,
    Map<String, dynamic> layoutData,
    bool isRecycleBin,
  ) {
    final dockingLayout = DockingLayout(
      root: _buildAreaFromData(layoutData, isRecycleBin),
    );

    return Docking(
      layout: dockingLayout,
      onItemSelection: (DockingItem item) {
        // 处理项目选择
        print('Selected docking item: ${item.name}');
      },
      onItemClose: (DockingItem item) {
        // 处理项目关闭
        print('Closed docking item: ${item.name}');
      },
    );
  }

  /// 从数据构建 Docking 区域
  DockingArea _buildAreaFromData(Map<String, dynamic> data, bool isRecycleBin) {
    final type = data['type'] as String;

    if (type == 'row') {
      final items = data['items'] as List<dynamic>;
      final areas =
          items
              .map(
                (item) => _buildAreaFromData(
                  item as Map<String, dynamic>,
                  isRecycleBin,
                ),
              )
              .toList();
      return DockingRow(areas);
    } else if (type == 'column') {
      final items = data['items'] as List<dynamic>;
      final areas =
          items
              .map(
                (item) => _buildAreaFromData(
                  item as Map<String, dynamic>,
                  isRecycleBin,
                ),
              )
              .toList();
      return DockingColumn(areas);
    } else if (type == 'tabs') {
      final items = data['items'] as List<dynamic>;
      final dockingItems =
          items
              .map(
                (item) => _buildAreaFromData(
                  item as Map<String, dynamic>,
                  isRecycleBin,
                ),
              )
              .whereType<DockingItem>()
              .toList();
      return DockingTabs(dockingItems);
    } else {
      return _buildDockingItem(data, isRecycleBin);
    }
  }

  /// 构建单个 DockingItem
  DockingItem _buildDockingItem(Map<String, dynamic> data, bool isRecycleBin) {
    final id = data['id'] as String;
    final name = data['name'] as String;
    final closable = data['closable'] as bool? ?? true;
    final maximizable = data['maximizable'] as bool? ?? true;
    final keepAlive = data['keepAlive'] as bool? ?? false;
    final weight = data['weight'] as double?;
    final size = data['size'] as double?;
    final minimalSize = data['minimalSize'] as double?;

    return DockingItem(
      id: id,
      name: name,
      closable: closable,
      maximizable: maximizable,
      keepAlive: keepAlive,
      weight: weight,
      size: size,
      minimalSize: minimalSize,
      widget: _buildItemContent(id, isRecycleBin),
    );
  }

  /// 构建项目内容
  Widget _buildItemContent(String itemId, bool isRecycleBin) {
    final manager = DockManager.getInstance()!;
    Widget? widget;
    switch (itemId) {
      case 'quick_actions':
        widget = manager.registry.build('library_quick_actions', {
          'plugin': plugin,
          'library': library.toMap(),
          'events': events,
          'parentContext': context,
        });
        break;

      case 'sidebar':
        widget = manager.registry.build('library_sidebar', {
          'plugin': plugin,
          'library': library.toMap(),
          'tabId': tabId,
          'itemId': itemId,
          'tags': state.tags,
          'folders': state.folders,
          'filterOptionsNotifier': state.filterOptionsNotifier,
        });
        break;

      case 'main_content':
        widget = manager.registry.build('library_main_content', {
          'plugin': plugin,
          'library': library.toMap(),
          'state': state,
          'events': events,
          'isRecycleBin': isRecycleBin,
          'onFileOpen': onFileOpen,
          'onFileSelected': onFileSelected,
          'onToggleSelected': onToggleSelected,
        });
        break;

      case 'details':
        widget = manager.registry.build('library_details', {
          'plugin': plugin,
          'library': library.toMap(),
          'state': state,
        });
        break;

      case 'app_bar_actions':
        widget = manager.registry.build('library_app_bar_actions', {
          'plugin': plugin,
          'library': library.toMap(),
          'state': state,
          'events': events,
          'tabId': tabId,
          'itemId': itemId,
          'onShowDropDialog': onShowDropDialog,
        });
        break;

      default:
        return Center(child: Text('Unknown panel: $itemId'));
    }

    return widget ?? Center(child: Text('Failed to build panel: $itemId'));
  }
}
