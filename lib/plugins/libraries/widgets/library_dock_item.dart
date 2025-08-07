import 'package:flutter/material.dart';
import 'package:mira/dock/dock_item.dart';
import 'package:mira/dock/dock_manager.dart';
import 'package:mira/dock/dock_tab.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:uuid/uuid.dart';
import '../models/library.dart';
import 'library_content_view.dart';
import 'library_tab_data.dart';

/// LibraryDockItem - 继承自DockItem的库标签页项目
class LibraryDockItem extends DockItem {
  final LibraryTabData tabData;
  late final LibrariesPlugin plugin;
  static bool _isBuilderRegistered = false;

  // 为每个实例创建固定的GlobalKey
  late final GlobalKey _contentKey;

  LibraryDockItem({
    required this.tabData,
    Map<String, ValueNotifier<dynamic>>? initialValues,
  }) : super(
         type: 'library_tab',
         title: tabData.title.isNotEmpty ? tabData.title : tabData.library.name,
         values: _initializeValues(tabData, initialValues),
         builder: (item) {
           final libraryItem = item as LibraryDockItem;
           return DockingItem(
             id: 'library_${tabData.id}',
             name: item.title,
             closable: true,
             keepAlive: true, // 启用keepAlive
             widget: LibraryContentView(
               key: libraryItem._contentKey, // 使用固定的GlobalKey
               plugin:
                   PluginManager.instance.getPlugin('libraries')
                       as LibrariesPlugin,
               tabData: tabData,
             ),
           );
         },
       ) {
    // 确保builder已注册
    _ensureBuilderRegistered();

    // 初始化固定的GlobalKey
    _contentKey = GlobalKey(debugLabel: 'library_content_${tabData.id}');
    plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;

    _setupValueListeners();
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
    DockTab.registerBuilder('library_tab', (dockItem) {
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

          // 创建新的LibraryDockItem
          final libraryDockItem = LibraryDockItem(
            tabData: tabData,
            initialValues: dockItem.values,
          );
          return libraryDockItem.buildDockingItem();
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

  /// 初始化values
  static Map<String, ValueNotifier<dynamic>> _initializeValues(
    LibraryTabData tabData,
    Map<String, ValueNotifier<dynamic>>? initialValues,
  ) {
    final values = initialValues ?? <String, ValueNotifier<dynamic>>{};

    // 从stored数据中初始化动态值
    final stored = tabData.stored;

    values['paginationOptions'] = ValueNotifier(
      stored['paginationOptions'] ?? {'page': 1, 'perPage': 1000},
    );
    values['sortOptions'] = ValueNotifier(
      stored['sortOptions'] ?? {'field': 'id', 'order': 'desc'},
    );
    values['imagesPerRow'] = ValueNotifier(stored['imagesPerRow'] ?? 0);
    values['filter'] = ValueNotifier(stored['filter'] ?? {});
    values['displayFields'] = ValueNotifier(
      stored['displayFields'] ??
          [
            'title',
            'rating',
            'notes',
            'createdAt',
            'tags',
            'folder',
            'size',
            'ext',
          ],
    );
    values['needUpdate'] = ValueNotifier(tabData.needUpdate);
    values['isActive'] = ValueNotifier(tabData.isActive);

    // 存储LibraryTabData的完整信息以便恢复
    values['_tabDataJson'] = ValueNotifier(tabData.toJson());

    return values;
  }

  /// 设置值变化监听器
  void _setupValueListeners() {
    // 监听分页选项变化
    values['paginationOptions']?.addListener(() {
      _updateStoredValue(
        'paginationOptions',
        values['paginationOptions']!.value,
      );
    });

    // 监听排序选项变化
    values['sortOptions']?.addListener(() {
      _updateStoredValue('sortOptions', values['sortOptions']!.value);
    });

    // 监听每行图片数变化
    values['imagesPerRow']?.addListener(() {
      _updateStoredValue('imagesPerRow', values['imagesPerRow']!.value);
    });

    // 监听过滤器变化
    values['filter']?.addListener(() {
      _updateStoredValue('filter', values['filter']!.value);
    });

    // 监听显示字段变化
    values['displayFields']?.addListener(() {
      _updateStoredValue('displayFields', values['displayFields']!.value);
    });

    // 监听需要更新状态变化
    values['needUpdate']?.addListener(() {
      tabData.needUpdate = values['needUpdate']!.value;
      values['_tabDataJson']?.value = tabData.toJson();
    });

    // 监听激活状态变化
    values['isActive']?.addListener(() {
      tabData.isActive = values['isActive']!.value;
      values['_tabDataJson']?.value = tabData.toJson();
    });
  }

  /// 更新stored值并保存
  void _updateStoredValue(String key, dynamic value) {
    tabData.stored[key] = value;
    // 更新_tabDataJson以保持数据同步
    values['_tabDataJson']?.value = tabData.toJson();
    // 这里会通过DockManager来保存数据
  }

  /// 静态方法：添加库标签页
  static String addTab(
    Library library, {
    String title = '',
    bool isRecycleBin = false,
    String dockTabsId = 'main',
    String? dockTabId, // 改为可为空，默认不指定
  }) {
    final tabData = LibraryTabData(
      id: Uuid().v4(),
      library: library,
      title: title,
      isRecycleBin: isRecycleBin,
      createDate: DateTime.now(),
      stored: {
        'paginationOptions': {'page': 1, 'perPage': 1000},
        'sortOptions': {'field': 'id', 'order': 'desc'},
        'imagesPerRow': 0,
        'filter': {},
        'displayFields': [
          'title',
          'rating',
          'notes',
          'createdAt',
          'tags',
          'folder',
          'size',
          'ext',
        ],
      },
    );

    final libraryDockItem = LibraryDockItem(tabData: tabData);

    // 通过DockManager添加到dock系统
    final success = DockManager.addDockItem(
      dockTabsId,
      dockTabId,
      libraryDockItem,
    );

    if (success) {
      return tabData.id;
    }
    throw Exception('Failed to add library tab');
  }

  /// 获取stored值
  T? getStoredValue<T>(String key, [T? defaultValue]) {
    final stored = getValue('stored') as Map<String, dynamic>?;
    return stored?[key] as T? ?? defaultValue;
  }

  /// 设置stored值
  void setStoredValue(String key, dynamic value) {
    final stored = Map<String, dynamic>.from(
      getValue('stored') as Map<String, dynamic>? ?? {},
    );
    stored[key] = value;
    update('stored', stored);
  }
}
