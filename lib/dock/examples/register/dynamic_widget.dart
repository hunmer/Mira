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

  @override
  void initState() {
    super.initState();
    _initRegistry();
    _buildData();
  }

  void _initRegistry() {
    _registry = widget.registry ?? JsonWidgetRegistry.instance;

    // 添加一些常用的变量
    _registry.setValue('theme', Theme.of(context));
    _registry.setValue('mediaQuery', MediaQuery.of(context));
  }

  void _buildData() {
    try {
      _data = JsonWidgetData.fromDynamic(widget.jsonData, registry: _registry);
    } catch (e) {
      // 如果 JSON 解析失败，创建一个错误显示
      _data = JsonWidgetData.fromDynamic({
        'type': 'container',
        'args': {
          'padding': {'top': 16, 'bottom': 16, 'left': 16, 'right': 16},
          'decoration': {
            'color': '#ffebee',
            'border': {'width': 1, 'color': '#f44336'},
            'borderRadius': 8,
          },
          'child': {
            'type': 'column',
            'args': {
              'crossAxisAlignment': 'start',
              'mainAxisSize': 'min',
              'children': [
                {
                  'type': 'text',
                  'args': {
                    'data': 'JSON 解析错误',
                    'style': {'color': '#d32f2f', 'fontWeight': 'bold'},
                  },
                },
                {
                  'type': 'sized_box',
                  'args': {'height': 8},
                },
                {
                  'type': 'text',
                  'args': {
                    'data': e.toString(),
                    'style': {'color': '#666', 'fontSize': 12},
                  },
                },
              ],
            },
          },
        },
      }, registry: _registry);
    }
  }

  @override
  void didUpdateWidget(DynamicWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonData != widget.jsonData) {
      _buildData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _data.build(context: context, registry: _registry);
  }
}

/// 预设的示例 JSON 数据
class DynamicWidgetPresets {
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
            'type': 'column',
            'args': {
              'crossAxisAlignment': 'start',
              'mainAxisSize': 'min',
              'children': [
                {
                  'type': 'row',
                  'args': {
                    'children': [
                      {
                        'type': 'icon',
                        'args': {
                          'icon': Icons.star.codePoint,
                          'color': '#FFD700',
                          'size': 32,
                        },
                      },
                      {
                        'type': 'sized_box',
                        'args': {'width': 12},
                      },
                      {
                        'type': 'expanded',
                        'args': {
                          'child': {
                            'type': 'text',
                            'args': {
                              'data': '欢迎使用 Dynamic Widget',
                              'style': {
                                'fontSize': 20,
                                'fontWeight': 'bold',
                                'color': '#1976D2',
                              },
                            },
                          },
                        },
                      },
                    ],
                  },
                },
                {
                  'type': 'sized_box',
                  'args': {'height': 16},
                },
                {
                  'type': 'text',
                  'args': {
                    'data':
                        '这是一个通过 JSON 动态构建的 Widget 示例。你可以通过修改 JSON 数据来改变界面布局和样式。',
                    'style': {'fontSize': 14, 'color': '#666', 'height': 1.5},
                  },
                },
                {
                  'type': 'sized_box',
                  'args': {'height': 20},
                },
                {
                  'type': 'row',
                  'args': {
                    'mainAxisAlignment': 'spaceBetween',
                    'children': [
                      {
                        'type': 'elevated_button',
                        'args': {
                          'onPressed': r'${noop()}',
                          'child': {
                            'type': 'text',
                            'args': {'data': '开始使用'},
                          },
                        },
                      },
                      {
                        'type': 'text_button',
                        'args': {
                          'onPressed': r'${noop()}',
                          'child': {
                            'type': 'text',
                            'args': {'data': '了解更多'},
                          },
                        },
                      },
                    ],
                  },
                },
              ],
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
              'args': {'data': '动态构建'},
            },
            'subtitle': {
              'type': 'text',
              'args': {'data': '通过 JSON 动态构建 Widget'},
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
              'args': {'data': '无需重编译'},
            },
            'subtitle': {
              'type': 'text',
              'args': {'data': '修改 JSON 即可改变界面'},
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
              'args': {'data': '灵活样式'},
            },
            'subtitle': {
              'type': 'text',
              'args': {'data': '支持丰富的样式配置'},
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
                'data': '计数器示例',
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
                'data': r'${counter ?? 0}',
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
                  'args': {'data': '点击增加'},
                },
              },
            },
          ],
        },
      },
    },
  };
}
