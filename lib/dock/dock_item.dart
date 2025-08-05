import 'package:flutter/material.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';

/// DockItem类 - 包含type、title、values和builder属性
class DockItem {
  final String type;
  final String title;
  final Map<String, ValueNotifier<dynamic>> values;
  final DockingItem Function(DockItem) builder;

  DockItem({
    required this.type,
    required this.title,
    Map<String, ValueNotifier<dynamic>>? values,
    required this.builder,
  }) : values = values ?? {};

  /// 更新values中的数据
  void update(String key, dynamic value) {
    if (values.containsKey(key)) {
      values[key]!.value = value;
    } else {
      values[key] = ValueNotifier(value);
    }
  }

  /// 获取values中的数据
  T? getValue<T>(String key) {
    return values[key]?.value as T?;
  }

  /// 添加监听器
  void addListener(String key, VoidCallback listener) {
    if (values.containsKey(key)) {
      values[key]!.addListener(listener);
    }
  }

  /// 移除监听器
  void removeListener(String key, VoidCallback listener) {
    if (values.containsKey(key)) {
      values[key]!.removeListener(listener);
    }
  }

  /// 构建DockingItem
  DockingItem buildDockingItem({Map<String, dynamic>? defaultConfig}) {
    final dockingItem = builder(this);

    // 应用默认配置（如果提供）
    if (defaultConfig != null) {
      return DockingItem(
        id: dockingItem.id,
        name: dockingItem.name,
        widget: dockingItem.widget,
        value: dockingItem.value,
        closable: defaultConfig['closable'] ?? true,
        buttons:
            defaultConfig['buttons'] != null
                ? (defaultConfig['buttons'] as List)
                    .map((e) => e as TabButton)
                    .toList()
                : [],
        maximizable: defaultConfig['maximizable'] ?? false,
        maximized: defaultConfig['maximized'] ?? false,
        leading: defaultConfig['leading'],
        size: defaultConfig['size'],
        weight: defaultConfig['weight'],
        minimalWeight: defaultConfig['minimalWeight'],
        minimalSize: defaultConfig['minimalSize'],
        keepAlive: defaultConfig['keepAlive'] ?? true,
      );
    }
    return dockingItem;
  }

  /// 释放资源
  void dispose() {
    for (var notifier in values.values) {
      notifier.dispose();
    }
    values.clear();
  }

  /// 从JSON创建DockItem
  factory DockItem.fromJson(
    Map<String, dynamic> json,
    DockingItem Function(DockItem) builder,
  ) {
    final values = <String, ValueNotifier<dynamic>>{};

    if (json['values'] != null) {
      final valuesMap = json['values'] as Map<String, dynamic>;
      for (var entry in valuesMap.entries) {
        values[entry.key] = ValueNotifier(entry.value);
      }
    }

    return DockItem(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      values: values,
      builder: builder,
    );
  }

  // copyWith
  DockItem copyWith({
    String? type,
    String? title,
    Map<String, ValueNotifier<dynamic>>? values,
    DockingItem Function(DockItem)? builder,
  }) {
    return DockItem(
      type: type ?? this.type,
      title: title ?? this.title,
      values: values ?? this.values,
      builder: builder ?? this.builder,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final valuesMap = <String, dynamic>{};
    for (var entry in values.entries) {
      valuesMap[entry.key] = entry.value.value;
    }

    return {'type': type, 'title': title, 'values': valuesMap};
  }
}
