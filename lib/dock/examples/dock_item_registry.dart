import 'package:flutter/widgets.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tab_button.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tab_leading_builder.dart';
import 'package:mira/tabbed/tabbed_view/lib/src/tabbed_view_menu_builder.dart';

/// 组件构建器，根据 values 创建 Widget
typedef DockItemBuilder = Widget Function(Map<String, dynamic> values);

/// 组件数据提取器，从 Widget 提取当前状态
typedef DockItemDataExtractor = Map<String, dynamic> Function(Widget widget);

/// 组件配置对话框构建器
typedef DockItemConfigBuilder =
    Widget Function(
      BuildContext context,
      Function(Map<String, dynamic>) onConfirm,
    );

/// DockItem 的数据模型
class DockItemData {
  final String id;
  final String type;
  final Map<String, dynamic> values;
  final String? name;
  final bool closable;
  final bool keepAlive;
  final bool? maximizable;
  final double? weight;
  // 新增：标签上的按钮/leading/菜单
  final List<TabButton>? buttons;
  final TabLeadingBuilder? leading;
  final TabbedViewMenuBuilder? menuBuilder;

  DockItemData({
    required this.id,
    required this.type,
    required this.values,
    this.name,
    this.closable = true,
    this.keepAlive = false,
    this.maximizable,
    this.weight,
    this.buttons,
    this.leading,
    this.menuBuilder,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'values': values,
    if (name != null) 'name': name,
    'closable': closable,
    'keepAlive': keepAlive,
    if (maximizable != null) 'maximizable': maximizable,
    if (weight != null) 'weight': weight,
    // 注意：函数类型（leading/menuBuilder）无法序列化，按钮也通常包含函数，默认不持久化
  };

  factory DockItemData.fromJson(Map<String, dynamic> json) {
    return DockItemData(
      id: json['id'] as String,
      type: json['type'] as String,
      values: Map<String, dynamic>.from(json['values'] ?? {}),
      name: json['name'] as String?,
      closable: json['closable'] ?? true,
      keepAlive: json['keepAlive'] ?? false,
      maximizable: json['maximizable'] as bool?,
      weight: json['weight'] as double?,
    );
  }
}

/// 组件注册器
class DockItemRegistry {
  static final DockItemRegistry _instance = DockItemRegistry._();
  factory DockItemRegistry() => _instance;
  DockItemRegistry._();

  final Map<String, DockItemBuilder> _builders = {};
  final Map<String, DockItemDataExtractor> _extractors = {};
  final Map<String, DockItemConfigBuilder> _configBuilders = {};
  // 新增：每种类型的默认按钮/leading/菜单
  final Map<String, List<TabButton>> _defaultButtons = {};
  final Map<String, TabLeadingBuilder> _defaultLeading = {};
  final Map<String, TabbedViewMenuBuilder> _defaultMenuBuilders = {};

  /// 注册组件类型
  void register(
    String type, {
    required DockItemBuilder builder,
    DockItemDataExtractor? extractor,
    DockItemConfigBuilder? configBuilder,
    List<TabButton>? defaultButtons,
    TabLeadingBuilder? defaultLeading,
    TabbedViewMenuBuilder? defaultMenuBuilder,
  }) {
    _builders[type] = builder;
    if (extractor != null) {
      _extractors[type] = extractor;
    }
    if (configBuilder != null) {
      _configBuilders[type] = configBuilder;
    }
    if (defaultButtons != null) {
      _defaultButtons[type] = List<TabButton>.from(defaultButtons);
    }
    if (defaultLeading != null) {
      _defaultLeading[type] = defaultLeading;
    }
    if (defaultMenuBuilder != null) {
      _defaultMenuBuilders[type] = defaultMenuBuilder;
    }
  }

  /// 构建组件
  Widget? build(String type, Map<String, dynamic> values) {
    final builder = _builders[type];
    return builder?.call(values);
  }

  /// 默认配置：按钮/leading/menu
  List<TabButton>? defaultButtonsOf(String type) => _defaultButtons[type];
  TabLeadingBuilder? defaultLeadingOf(String type) => _defaultLeading[type];
  TabbedViewMenuBuilder? defaultMenuOf(String type) => _defaultMenuBuilders[type];

  /// 提取组件数据
  Map<String, dynamic> extract(String type, Widget widget) {
    final extractor = _extractors[type];
    return extractor?.call(widget) ?? {};
  }

  /// 构建配置对话框
  Widget? buildConfigDialog(
    String type,
    BuildContext context,
    Function(Map<String, dynamic>) onConfirm,
  ) {
    final configBuilder = _configBuilders[type];
    return configBuilder?.call(context, onConfirm);
  }

  /// 检查类型是否已注册
  bool hasType(String type) => _builders.containsKey(type);

  /// 获取所有已注册的组件类型
  List<String> get registeredTypes => _builders.keys.toList();

  /// 获取有配置对话框的组件类型
  List<String> get typesWithConfig => _configBuilders.keys.toList();
}
