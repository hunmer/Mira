import 'package:flutter/material.dart';
import 'package:mira/dock/examples/register/counter_widget.dart';
import 'package:mira/dock/examples/register/dynamic_widget.dart';
import '../dock_manager.dart';
import '../dock_item_registry.dart';
import 'counter_config.dart';
import 'text_config.dart';
import 'dynamic_widget.dart';
import 'dynamic_widget_config.dart';
import 'dock_item_config_base.dart';

/// 组件注册管理器
class DockItemRegistrar {
  static void registerAllComponents(DockManager manager) {
    // 注册计数器组件
    manager.registry.register(
      'counter',
      builder:
          (values) => CounterWidget(
            initialValue: values['count'] ?? 0,
            onChanged: (newValue) {
              manager.updateItemValues(values['id'], {
                'count': newValue,
                'id': values['id'],
              });
            },
          ),
      configBuilder: CounterTypeInfo.info.configBuilder,
    );

    // 注册文本组件
    manager.registry.register(
      'text',
      builder:
          (values) => Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                values['text'] ?? 'No text',
                style: TextStyle(
                  fontSize: (values['fontSize'] as double?) ?? 16,
                  fontWeight:
                      values['fontWeight'] != null
                          ? FontWeight.values[values['fontWeight'] as int]
                          : FontWeight.normal,
                  color:
                      values['textColor'] != null
                          ? Color(values['textColor'] as int)
                          : Colors.black,
                ),
                textAlign:
                    values['textAlign'] != null
                        ? TextAlign.values[values['textAlign'] as int]
                        : TextAlign.center,
                maxLines: values['maxLines'] as int?,
                overflow:
                    (values['wordWrap'] ?? true)
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
              ),
            ),
          ),
      configBuilder: TextTypeInfo.info.configBuilder,
    );

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
