import 'package:flutter/material.dart';

/// 组件配置对话框的基础类
abstract class DockItemConfig extends StatefulWidget {
  final Function(Map<String, dynamic>) onConfirm;

  const DockItemConfig({super.key, required this.onConfirm});
}

/// 组件信息
class DockItemTypeInfo {
  final String type;
  final String displayName;
  final String description;
  final IconData icon;
  final Widget Function(BuildContext, Function(Map<String, dynamic>))?
  configBuilder;

  const DockItemTypeInfo({
    required this.type,
    required this.displayName,
    required this.description,
    required this.icon,
    this.configBuilder,
  });
}
