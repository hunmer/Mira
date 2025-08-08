import 'package:flutter/material.dart';
import 'package:mira/dock/examples/registerdWidgets/counter_widget.dart';
import 'package:mira/dock/examples/registerdWidgets/dynamic_widget.dart';
import '../dock_manager.dart';
import '../registerdWidgets/counter_config.dart';
import '../registerdWidgets/text_config.dart';
import '../registerdWidgets/dynamic_widget_config.dart';
import 'dock_item_config_base.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';

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
      defaultLeading: (context, status) => Icon(
        Icons.numbers,
        size: 16,
        color: status == TabStatus.selected ? Colors.blue : Colors.grey,
      ),
      defaultButtons: [
        TabButton(
          icon: IconProvider.data(Icons.add_circle_outline),
          onPressed: () {
            // 注意：这里需要通过其他方式获取当前item的ID和manager实例
            // 实际使用时需要传入具体的context或通过其他方式获取
            print('增加计数器值');
          },
        ),
        TabButton(
          icon: IconProvider.data(Icons.settings),
          menuBuilder: (context) => [
            TabbedViewMenuItem(
              text: '重置计数器',
              onSelection: () {
                print('重置计数器');
              },
            ),
            TabbedViewMenuItem(
              text: '设置为 10',
              onSelection: () {
                print('设置为 10');
              },
            ),
          ],
        ),
      ],
      defaultMenuBuilder: (context) => [
        TabbedViewMenuItem(
          text: '重置',
          onSelection: () {
            print('重置计数器');
          },
        ),
        TabbedViewMenuItem(
          text: '配置',
          onSelection: () {
            print('打开配置对话框');
          },
        ),
        TabbedViewMenuItem(
          text: '复制',
          onSelection: () {
            print('复制当前计数器');
          },
        ),
      ],
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
      defaultLeading: (context, status) => Icon(
        Icons.text_fields,
        size: 16,
        color: status == TabStatus.selected ? Colors.green : Colors.grey,
      ),
      defaultButtons: [
        TabButton(
          icon: IconProvider.data(Icons.format_size),
          menuBuilder: (context) => [
            TabbedViewMenuItem(
              text: '小号字体',
              onSelection: () {
                print('设置小号字体');
              },
            ),
            TabbedViewMenuItem(
              text: '中号字体',
              onSelection: () {
                print('设置中号字体');
              },
            ),
            TabbedViewMenuItem(
              text: '大号字体',
              onSelection: () {
                print('设置大号字体');
              },
            ),
          ],
        ),
      ],
      defaultMenuBuilder: (context) => [
        TabbedViewMenuItem(
          text: '编辑文本',
          onSelection: () {
            print('打开文本编辑对话框');
          },
        ),
        TabbedViewMenuItem(
          text: '复制文本',
          onSelection: () {
            print('复制文本内容到剪贴板');
          },
        ),
        TabbedViewMenuItem(
          text: '清空文本',
          onSelection: () {
            print('清空文本内容');
          },
        ),
      ],
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
      defaultLeading: (context, status) => Icon(
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
          menuBuilder: (context) => [
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
      defaultMenuBuilder: (context) => [
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
