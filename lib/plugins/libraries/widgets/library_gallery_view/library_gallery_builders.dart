import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_data.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/examples/dock_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:responsive_builder/responsive_builder.dart';
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
  final items = [
    {
      'id': 'quick_actions',
      'name': '',
      'type': 'item',
      'closable': true,
      'maximizable': false,
      'keepAlive': true,
      'size': 60.0,
      'showAtDevices': [DeviceScreenType.desktop],
    },
    {
      'id': 'sidebar',
      'name': '',
      'type': 'item',
      'closable': true,
      'maximizable': false,
      'keepAlive': true,
      'weight': 0.2,
      'minimalSize': 150.0,
      'showAtDevices': [DeviceScreenType.tablet],
    },
    {
      'id': 'main_content',
      'name': '',
      'type': 'item',
      'closable': true,
      'maximizable': true,
      'keepAlive': true,
      'weight': 0.6,
      'minimalSize': 300.0,
    },
    {
      'id': 'details',
      'name': '',
      'type': 'item',
      'closable': true,
      'maximizable': false,
      'keepAlive': true,
      'weight': 0.2,
      'minimalSize': 150.0,
      'showAtDevices': [DeviceScreenType.tablet],
    },
    {
      'id': 'app_bar_actions',
      'name': '',
      'type': 'item',
      'closable': true,
      'maximizable': false,
      'keepAlive': true,
      'weight': 0.1,
      'minimalSize': 40.0,
      'showAtDevices': [DeviceScreenType.desktop],
    },
  ];

  // 缓存 DockingLayout 以避免重复创建
  DockingLayout? _cachedDockingLayout;
  bool? _lastIsRecycleBin;

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

    // 检查是否需要重新创建 DockingLayout
    if (_cachedDockingLayout == null || _lastIsRecycleBin != isRecycleBin) {
      _cachedDockingLayout = _createDockingLayout(isRecycleBin);
      _lastIsRecycleBin = isRecycleBin;
    }

    return Docking(
      layout: _cachedDockingLayout!,
      autoBreakpoints: true,
      breakpoints: const ScreenBreakpoints(
        desktop: 800,
        tablet: 600,
        watch: 200,
      ),
    );
  }

  /// 创建 DockingLayout（只在必要时调用）
  DockingLayout _createDockingLayout(bool isRecycleBin) {
    return DockingLayout(
      root: _buildAreaFromData({'type': 'row', 'items': items}, isRecycleBin),
    );
  }

  /// 从数据构建 Docking 区域
  DockingArea _buildAreaFromData(Map<String, dynamic> data, bool isRecycleBin) {
    final type = data['type'] as String;
    final items =
        data.containsKey('items') ? data['items'] as List<dynamic> : [];
    final areas =
        items
            .map(
              (item) => _buildAreaFromData(
                item as Map<String, dynamic>,
                isRecycleBin,
              ),
            )
            .toList();
    if (type == 'row') {
      return DockingRow(areas);
    } else if (type == 'column') {
      return DockingColumn(areas);
    } else if (type == 'tabs') {
      return DockingTabs(areas.whereType<DockingItem>().toList());
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
    final showAtDevices = data['showAtDevices'] as List<DeviceScreenType>?;
    return DockingItem(
      id: id,
      name: name,
      closable: closable,
      maximizable: maximizable,
      keepAlive: keepAlive,
      weight: weight,
      size: size,
      minimalSize: minimalSize,
      visibilityMode: DeviceVisibilityMode.specifiedAndLarger,
      showAtDevices: showAtDevices,
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
