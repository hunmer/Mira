import 'package:flutter/material.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

/// Dynamic Widget 组件，能够通过 JSON 动态构建 Widget
class DynamicWidget extends StatefulWidget {
  final Map<String, dynamic> jsonData;
  final JsonWidgetRegistry? registry;
  final VoidCallback? onDataChanged;

  const DynamicWidget({
    Key? key,
    required this.jsonData,
    this.registry,
    this.onDataChanged,
  }) : super(key: key);

  @override
  State<DynamicWidget> createState() => _DynamicWidgetState();
}

class _DynamicWidgetState extends State<DynamicWidget> {
  late JsonWidgetData _data;
  late JsonWidgetRegistry _registry;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // 确保使用包含所有内部构建器的默认 registry
    _registry = widget.registry ?? JsonWidgetRegistry.instance;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initRegistry();
      _buildData();
      _initialized = true;
    }
  }

  void _initRegistry() {
    // 添加一些常用的变量
    _registry.setValue('theme', Theme.of(context));
    _registry.setValue('mediaQuery', MediaQuery.of(context));

    // 添加计数器变量
    _registry.setValue('counter', 0);
  }

  void _buildData() {
    try {
      _data = JsonWidgetData.fromDynamic(widget.jsonData, registry: _registry);
    } catch (e) {
      // 如果 JSON 解析失败，创建一个简单的错误显示
      _data = JsonWidgetData.fromDynamic({
        'type': 'text',
        'args': {'text': 'JSON 解析错误: ${e.toString()}'},
      }, registry: _registry);
    }
  }

  @override
  void didUpdateWidget(DynamicWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonData != widget.jsonData) {
      _buildData();
    }
    if (oldWidget.registry != widget.registry) {
      _registry = widget.registry ?? JsonWidgetRegistry.instance;
      _initRegistry();
      _buildData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final builtWidget = _data.build(context: context, registry: _registry);
    return builtWidget;
  }
}

/// 预设的示例 JSON 数据
class DynamicWidgetPresets {
  /// 简单文本测试
  static Map<String, dynamic> get simpleText => {
    'type': 'text',
    'args': {'text': '这是一个简单的文本测试'},
  };

  /// 欢迎卡片
  static Map<String, dynamic> get welcomeCard => {
    'type': 'card',
    'args': {
      'margin': {'all': 16},
      'elevation': 4,
      'child': {
        'type': 'padding',
        'args': {
          'padding': {'all': 20},
          'child': {
            'type': 'text',
            'args': {
              'text': '欢迎使用 Dynamic Widget',
              'style': {
                'fontSize': 20,
                'fontWeight': 'bold',
                'color': '#1976D2',
              },
            },
          },
        },
      },
    },
  };

  /// 功能列表
  static Map<String, dynamic> get featureList => {
    'type': 'column',
    'args': {
      'children': [
        {
          'type': 'list_tile',
          'args': {
            'leading': {
              'type': 'icon',
              'args': {'icon': Icons.build.codePoint, 'color': '#4CAF50'},
            },
            'title': {
              'type': 'text',
              'args': {'text': '动态构建'},
            },
            'subtitle': {
              'type': 'text',
              'args': {'text': '通过 JSON 动态构建 Widget'},
            },
          },
        },
        {'type': 'divider', 'args': {}},
        {
          'type': 'list_tile',
          'args': {
            'leading': {
              'type': 'icon',
              'args': {'icon': Icons.code.codePoint, 'color': '#FF9800'},
            },
            'title': {
              'type': 'text',
              'args': {'text': '无需重编译'},
            },
            'subtitle': {
              'type': 'text',
              'args': {'text': '修改 JSON 即可改变界面'},
            },
          },
        },
        {'type': 'divider', 'args': {}},
        {
          'type': 'list_tile',
          'args': {
            'leading': {
              'type': 'icon',
              'args': {'icon': Icons.palette.codePoint, 'color': '#E91E63'},
            },
            'title': {
              'type': 'text',
              'args': {'text': '灵活样式'},
            },
            'subtitle': {
              'type': 'text',
              'args': {'text': '支持丰富的样式配置'},
            },
          },
        },
      ],
    },
  };

  /// 计数器示例
  static Map<String, dynamic> get counterExample => {
    'type': 'container',
    'args': {
      'padding': {'all': 16},
      'decoration': {'color': '#F5F5F5', 'borderRadius': 12},
      'child': {
        'type': 'column',
        'args': {
          'mainAxisAlignment': 'center',
          'children': [
            {
              'type': 'text',
              'args': {
                'text': '计数器示例',
                'style': {'fontSize': 18, 'fontWeight': 'bold'},
              },
            },
            {
              'type': 'sized_box',
              'args': {'height': 16},
            },
            {
              'type': 'text',
              'args': {
                'text': r'${counter ?? 0}',
                'style': {
                  'fontSize': 48,
                  'fontWeight': 'bold',
                  'color': '#2196F3',
                },
              },
            },
            {
              'type': 'sized_box',
              'args': {'height': 16},
            },
            {
              'type': 'elevated_button',
              'args': {
                'onPressed': r"${set_value('counter', (counter ?? 0) + 1)}",
                'child': {
                  'type': 'text',
                  'args': {'text': '点击增加'},
                },
              },
            },
          ],
        },
      },
    },
  };
}
