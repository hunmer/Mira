import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';
import 'package:mira/dock/examples/dock_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/docking_tab_data.dart';
import 'docking_content_view.dart';

/// 使用新的注册方法，将 Docking 作为 DockItemRegistrar 的一个组件类型
class DockingDockItemRegistrar {
  static const String type = 'docking_tab';

  static void register(DockManager manager) {
    manager.registry.register(
      'docking_tab',
      builder: (values) {
        final tabDataJson = values['_tabDataJson'] as Map<String, dynamic>?;
        DockingTabData tabData;
        if (tabDataJson != null) {
          tabData = DockingTabData.fromMap(tabDataJson);
        } else {
          tabData = DockingTabData(
            id: values['id'] as String? ?? const Uuid().v4(),
            title: values['title'] as String? ?? 'Docking',
            createDate: DateTime.now(),
            stored: Map<String, dynamic>.from(
              values['stored'] as Map<String, dynamic>? ?? const {},
            ),
          );
        }

        return DockingContentView(tabData: tabData);
      },
    );
  }

  /// 通过新的 API 添加 docking 标签页
  static String addTab(
    DockManager manager, {
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

    final values = <String, dynamic>{
      '_tabDataJson': tabData.toJson(),
      'id': tabData.id,
      'title': tabData.title,
      'stored': tabData.stored,
    };

    // 选择一个可投放区域
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
      throw Exception('No valid DropArea to add docking tab');
    }

    manager.addTypedItem(
      id: tabData.id,
      type: type,
      values: values,
      targetArea: targetArea as DropArea,
      dropIndex: targetArea is DockingTabs ? 0 : null,
      dropPosition: targetArea is DockingTabs ? null : DropPosition.right,
      name: tabData.title,
      keepAlive: true,
      closable: true,
      maximizable: true,
    );

    return tabData.id;
  }

  // 以下为默认配置复用
  static Map<String, dynamic> _getDefaultLayoutData() {
    return {
      'type': 'row',
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

  static Map<String, dynamic> _getDefaultThemeConfig() {
    return {
      'divider': {
        'thickness': 4.0,
        'color': 0xFF424242,
        'highlightedColor': 0xFFFFFFFF,
        'backgroundColor': 0xFF616161,
        'painter': 'grooved2',
      },
      'tabs': {
        'theme': 'mobile',
        'tabsAreaButtonsVisibility': true,
        'tabsAreaVisible': true,
        'contentAreaVisible': true,
        'menuButtonTooltip': 'Show menu',
      },
    };
  }

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

  static Map<String, dynamic> _getDefaultItemProperties() {
    return {
      'defaultClosable': true,
      'defaultMaximizable': true,
      'defaultKeepAlive': false,
      'leadingWidget': null,
      'closeInterceptor': true,
    };
  }

  static Map<String, dynamic> _getDefaultSizeConfig() {
    return {'minimalSize': 100.0, 'initialSize': null, 'initialWeight': null};
  }

  static Map<String, dynamic> _getDefaultCallbacksConfig() {
    return {
      'onItemSelection': true,
      'onItemClose': true,
      'onLayoutChange': true,
    };
  }
}
