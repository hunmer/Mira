import 'package:flutter/material.dart';
import 'package:mira/dock/dock_item.dart';
import 'package:mira/dock/dock_manager.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:uuid/uuid.dart';
import '../models/docking_tab_data.dart';
import 'docking_content_view.dart';

/// DockingDockItem - 继承自DockItem的docking标签页项目
class DockingDockItem extends DockItem {
  final DockingTabData tabData;
  static bool _isBuilderRegistered = false;

  // 为每个实例创建固定的GlobalKey
  late final GlobalKey _contentKey;

  DockingDockItem({
    required String id,
    required this.tabData,
    Map<String, ValueNotifier<dynamic>>? initialValues,
  }) : super(
         type: 'docking_tab',
         id: id,
         title: tabData.title.isNotEmpty ? tabData.title : 'Docking',
         values: _initializeValues(tabData, initialValues),
         builder: (item) {
           final dockingItem = item as DockingDockItem;
           return DockingItem(
             id: 'docking_${tabData.id}',
             name: item.title,
             closable: true,
             keepAlive: true, // 启用keepAlive
             widget: DockingContentView(
               key: dockingItem._contentKey, // 使用固定的GlobalKey
               tabData: tabData,
             ),
           );
         },
       ) {
    // 初始化固定的GlobalKey
    _contentKey = GlobalKey(debugLabel: 'docking_content_${tabData.id}');

    // 确保builder已注册
    _ensureBuilderRegistered();

    _setupValueListeners();
  }

  /// 确保docking_tab类型的builder已经注册
  static void _ensureBuilderRegistered() {
    if (!_isBuilderRegistered) {
      registerDockingTabBuilder();
      _isBuilderRegistered = true;
    }
  }

  /// 注册docking_tab类型的builder
  static void registerDockingTabBuilder() {
    DockManager.registerBuilder('docking_tab', (dockItem) {
      // 从dockItem中获取DockingDockItem的实例
      if (dockItem is DockingDockItem) {
        return dockItem.buildDockingItem();
      }

      // 如果不是DockingDockItem实例，尝试从values中重建
      try {
        // 尝试从保存的值中恢复DockingTabData
        final tabDataJson =
            dockItem.getValue('_tabDataJson') as Map<String, dynamic>?;

        if (tabDataJson != null) {
          // 重建DockingTabData
          final tabData = DockingTabData.fromMap(tabDataJson);

          // 创建新的DockingDockItem
          final dockingDockItem = DockingDockItem(
            id: dockItem.id,
            tabData: tabData,
            initialValues: dockItem.values,
          );
          return dockingDockItem.buildDockingItem();
        }
      } catch (e) {
        print('DockingDockItem: Error restoring from saved data: $e');
      }

      // 如果无法重建，显示错误信息
      return DockingItem(
        id: 'docking_${dockItem.title}',
        name: dockItem.title,
        closable: true,
        keepAlive: true, // 启用keepAlive
        widget: const Center(
          child: Text(
            'Docking content not available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    });

    print('DockingDockItem: Registered docking_tab builder');
  }

  /// 静态方法：手动注册builder（供外部调用）
  static void ensureRegistered() {
    _ensureBuilderRegistered();
  }

  /// 初始化values
  static Map<String, ValueNotifier<dynamic>> _initializeValues(
    DockingTabData tabData,
    Map<String, ValueNotifier<dynamic>>? initialValues,
  ) {
    final values = initialValues ?? <String, ValueNotifier<dynamic>>{};

    // 从stored数据中初始化动态值
    final stored = tabData.stored;

    // Docking layout data - 存储整个docking布局的JSON字符串
    values['layoutData'] = ValueNotifier(
      stored['layoutData'] ?? _getDefaultLayoutData(),
    );

    // Docking theme configuration
    values['themeConfig'] = ValueNotifier(
      stored['themeConfig'] ?? _getDefaultThemeConfig(),
    );

    // Docking buttons build configuration
    values['buttonsConfig'] = ValueNotifier(
      stored['buttonsConfig'] ?? _getDefaultButtonsConfig(),
    );

    // Item properties
    values['itemProperties'] = ValueNotifier(
      stored['itemProperties'] ?? _getDefaultItemProperties(),
    );

    // Size configuration
    values['sizeConfig'] = ValueNotifier(
      stored['sizeConfig'] ?? _getDefaultSizeConfig(),
    );

    // Docking callbacks configuration
    values['callbacksConfig'] = ValueNotifier(
      stored['callbacksConfig'] ?? _getDefaultCallbacksConfig(),
    );

    values['needUpdate'] = ValueNotifier(tabData.needUpdate);
    values['isActive'] = ValueNotifier(tabData.isActive);

    // 存储DockingTabData的完整信息以便恢复
    values['_tabDataJson'] = ValueNotifier(tabData.toJson());

    return values;
  }

  /// 获取默认的Layout数据
  static Map<String, dynamic> _getDefaultLayoutData() {
    return {
      'type': 'row', // row, column, tabs
      'items': [
        {
          'id': 'item1',
          'name': 'Item 1',
          'type': 'item',
          'closable': true,
          'maximizable': true,
          'keepAlive': false,
          'weight': 0.5,
        },
        {
          'id': 'item2',
          'name': 'Item 2',
          'type': 'item',
          'closable': true,
          'maximizable': true,
          'keepAlive': false,
          'weight': 0.5,
        },
      ],
    };
  }

  /// 获取默认的Theme配置
  static Map<String, dynamic> _getDefaultThemeConfig() {
    return {
      'divider': {
        'thickness': 4.0,
        'color': 0xFF424242, // Colors.grey[800]
        'highlightedColor': 0xFFFFFFFF, // Colors.white
        'backgroundColor': 0xFF616161, // Colors.grey[700]
        'painter': 'grooved2', // grooved1, grooved2, background, etc.
      },
      'tabs': {
        'theme': 'mobile', // mobile, dark, light, custom
        'tabsAreaButtonsVisibility': true,
        'tabsAreaVisible': true,
        'contentAreaVisible': true,
        'menuButtonTooltip': 'Show menu',
      },
    };
  }

  /// 获取默认的Buttons配置
  static Map<String, dynamic> _getDefaultButtonsConfig() {
    return {
      'enabled': true,
      'buttons': [
        {
          'id': 'refresh',
          'icon': 'refresh',
          'tooltip': 'Refresh',
          'onPressed': 'refresh',
        },
        {
          'id': 'settings',
          'icon': 'settings',
          'tooltip': 'Settings',
          'onPressed': 'settings',
        },
      ],
    };
  }

  /// 获取默认的Item属性
  static Map<String, dynamic> _getDefaultItemProperties() {
    return {
      'defaultClosable': true,
      'defaultMaximizable': true,
      'defaultKeepAlive': false,
      'leadingWidget': null,
      'closeInterceptor': true,
    };
  }

  /// 获取默认的Size配置
  static Map<String, dynamic> _getDefaultSizeConfig() {
    return {'minimalSize': 100.0, 'initialSize': null, 'initialWeight': null};
  }

  /// 获取默认的Callbacks配置
  static Map<String, dynamic> _getDefaultCallbacksConfig() {
    return {
      'onItemSelection': true,
      'onItemClose': true,
      'onLayoutChange': true,
    };
  }

  /// 设置值变化监听器
  void _setupValueListeners() {
    // 监听layout数据变化
    values['layoutData']?.addListener(() {
      _updateStoredValue('layoutData', values['layoutData']!.value);
    });

    // 监听theme配置变化
    values['themeConfig']?.addListener(() {
      _updateStoredValue('themeConfig', values['themeConfig']!.value);
    });

    // 监听buttons配置变化
    values['buttonsConfig']?.addListener(() {
      _updateStoredValue('buttonsConfig', values['buttonsConfig']!.value);
    });

    // 监听item属性变化
    values['itemProperties']?.addListener(() {
      _updateStoredValue('itemProperties', values['itemProperties']!.value);
    });

    // 监听size配置变化
    values['sizeConfig']?.addListener(() {
      _updateStoredValue('sizeConfig', values['sizeConfig']!.value);
    });

    // 监听callbacks配置变化
    values['callbacksConfig']?.addListener(() {
      _updateStoredValue('callbacksConfig', values['callbacksConfig']!.value);
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

  /// 静态方法：添加docking标签页
  static String addTab({
    String title = 'Docking',
    Map<String, dynamic>? layoutData,
    Map<String, dynamic>? themeConfig,
    Map<String, dynamic>? buttonsConfig,
    String dockTabsId = 'main',
    required String dockTabId,
  }) {
    final tabData = DockingTabData(
      id: const Uuid().v4(),
      title: title,
      createDate: DateTime.now(),
      stored: {
        'layoutData': layoutData ?? _getDefaultLayoutData(),
        'themeConfig': themeConfig ?? _getDefaultThemeConfig(),
        'buttonsConfig': buttonsConfig ?? _getDefaultButtonsConfig(),
        'itemProperties': _getDefaultItemProperties(),
        'sizeConfig': _getDefaultSizeConfig(),
        'callbacksConfig': _getDefaultCallbacksConfig(),
      },
    );

    final dockingDockItem = DockingDockItem(
      id: const Uuid().v4(),
      tabData: tabData,
    );

    // 通过DockManager添加到dock系统
    final success = DockManager.addDockItem(
      dockTabsId,
      dockTabId,
      dockingDockItem,
    );

    if (success) {
      return tabData.id;
    }
    throw Exception('Failed to add docking tab');
  }

  /// 获取layout数据
  Map<String, dynamic>? getLayoutData() {
    return values['layoutData']?.value as Map<String, dynamic>?;
  }

  /// 更新layout数据
  void updateLayoutData(Map<String, dynamic> layoutData) {
    values['layoutData']?.value = layoutData;
  }

  /// 获取theme配置
  Map<String, dynamic>? getThemeConfig() {
    return values['themeConfig']?.value as Map<String, dynamic>?;
  }

  /// 更新theme配置
  void updateThemeConfig(Map<String, dynamic> themeConfig) {
    values['themeConfig']?.value = themeConfig;
  }

  /// 获取buttons配置
  Map<String, dynamic>? getButtonsConfig() {
    return values['buttonsConfig']?.value as Map<String, dynamic>?;
  }

  /// 更新buttons配置
  void updateButtonsConfig(Map<String, dynamic> buttonsConfig) {
    values['buttonsConfig']?.value = buttonsConfig;
  }

  /// 获取item属性
  Map<String, dynamic>? getItemProperties() {
    return values['itemProperties']?.value as Map<String, dynamic>?;
  }

  /// 更新item属性
  void updateItemProperties(Map<String, dynamic> itemProperties) {
    values['itemProperties']?.value = itemProperties;
  }

  /// 获取size配置
  Map<String, dynamic>? getSizeConfig() {
    return values['sizeConfig']?.value as Map<String, dynamic>?;
  }

  /// 更新size配置
  void updateSizeConfig(Map<String, dynamic> sizeConfig) {
    values['sizeConfig']?.value = sizeConfig;
  }

  /// 获取callbacks配置
  Map<String, dynamic>? getCallbacksConfig() {
    return values['callbacksConfig']?.value as Map<String, dynamic>?;
  }

  /// 更新callbacks配置
  void updateCallbacksConfig(Map<String, dynamic> callbacksConfig) {
    values['callbacksConfig']?.value = callbacksConfig;
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
