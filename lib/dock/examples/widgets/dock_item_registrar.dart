import 'package:flutter/material.dart';
import 'package:mira/dock/examples/registerdWidgets/dynamic_widget.dart';
import 'package:mira/plugins/docking/widgets/docking_dock_item.dart';
import 'package:mira/plugins/libraries/widgets/library_dock_item.dart';
import '../dock_manager.dart';
import '../registerdWidgets/counter_config.dart';
import '../registerdWidgets/text_config.dart';
import '../registerdWidgets/dynamic_widget_config.dart';
import 'dock_item_config_base.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';

/// 组件注册管理器
class DockItemRegistrar {
  static void registerAllComponents(DockManager manager) {
    DockingDockItemRegistrar.register(manager);
    LibraryDockItemRegistrar.register(manager);

    // 注册动态组件
    manager.registry.register(
      'dynamic_widget',
      builder: (values) {
        final jsonData =
            values['jsonData'] as Map<String, dynamic>? ??
            DynamicWidgetPresets.welcomeCard;
        return DynamicWidget(
          jsonData: jsonData,
          onDataChanged: () {
            // 当数据发生变化时，可以在这里处理
          },
        );
      },
      configBuilder: DynamicWidgetTypeInfo.info.configBuilder,
      defaultLeading:
          (context, status) => Icon(
            Icons.dynamic_form,
            size: 16,
            color: status == TabStatus.selected ? Colors.purple : Colors.grey,
          ),
      defaultButtons: [
        TabButton(
          icon: IconProvider.data(Icons.refresh),
          onPressed: () {
            print('刷新动态组件');
          },
        ),
        TabButton(
          icon: IconProvider.data(Icons.palette),
          menuBuilder:
              (context) => [
                TabbedViewMenuItem(
                  text: '欢迎卡片',
                  onSelection: () {
                    print('切换到欢迎卡片预设');
                  },
                ),
                TabbedViewMenuItem(
                  text: '功能列表',
                  onSelection: () {
                    print('切换到功能列表预设');
                  },
                ),
                TabbedViewMenuItem(
                  text: '计数器示例',
                  onSelection: () {
                    print('切换到计数器示例预设');
                  },
                ),
              ],
        ),
      ],
      defaultMenuBuilder:
          (context) => [
            TabbedViewMenuItem(
              text: '编辑 JSON',
              onSelection: () {
                print('打开 JSON 编辑器');
              },
            ),
            TabbedViewMenuItem(
              text: '导出 JSON',
              onSelection: () {
                print('导出当前 JSON 配置');
              },
            ),
            TabbedViewMenuItem(
              text: '重置为默认',
              onSelection: () {
                print('重置为默认预设');
              },
            ),
          ],
    );
  }

  /// 获取所有组件类型信息
  static List<DockItemTypeInfo> getAllComponentTypes() {
    return [
      CounterTypeInfo.info,
      TextTypeInfo.info,
      DynamicWidgetTypeInfo.info,
    ];
  }

  /// 根据类型获取组件信息
  static DockItemTypeInfo? getComponentInfo(String type) {
    final allTypes = getAllComponentTypes();
    try {
      return allTypes.firstWhere((info) => info.type == type);
    } catch (e) {
      return null;
    }
  }

  /// 获取组件的默认配置
  static Map<String, dynamic> getDefaultConfig(String type) {
    switch (type) {
      case 'counter':
        return {
          'count': 0,
          'minValue': null,
          'maxValue': null,
          'step': 1,
          'showStepControls': true,
          'allowNegative': true,
        };
      case 'text':
        return {
          'text': 'Sample Text',
          'fontSize': 16.0,
          'fontWeight': FontWeight.normal.index,
          'textColor': Colors.black.value,
          'textAlign': TextAlign.center.index,
          'maxLines': null,
          'wordWrap': true,
        };
      case 'dynamic_widget':
        return {
          'jsonData': DynamicWidgetPresets.welcomeCard,
          'preset': 'welcomeCard',
        };
      default:
        return {};
    }
  }
}
