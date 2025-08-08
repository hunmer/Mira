import 'package:flutter/material.dart';
import 'package:mira/dock/dock_theme.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/core/widgets/window_controls.dart';
import 'package:mira/multi_split_view/lib/multi_split_view.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';
import 'dock_manager.dart';
import 'docking_persistence_logic.dart';
import 'register/counter_widget.dart';
import 'register/dynamic_widget.dart';
import 'widgets/counter_config_dialog.dart';
import 'widgets/text_config_dialog.dart';
import 'widgets/dynamic_widget_config_dialog.dart';
import '../debug_layout_preset_dialog.dart';

// ========= 示例页面 =========

class DockingPersistenceDemo extends StatefulWidget {
  @override
  State<DockingPersistenceDemo> createState() => _DockingPersistenceDemoState();
}

class _DockingPersistenceDemoState extends State<DockingPersistenceDemo> {
  late final DockManager manager;
  late final DockingPersistenceLogic logic;
  bool _loading = true;
  bool _draggable = true;

  @override
  void initState() {
    super.initState();
    _initManager();
  }

  Future<void> _initManager() async {
    // 创建 Manager，使用唯一 ID
    manager = DockManager(id: 'main_layout', autoSave: true);

    // 创建业务逻辑实例
    logic = DockingPersistenceLogic(manager: manager, context: context);

    // 注册自定义组件类型
    _registerComponents();

    // 尝试恢复上次的布局
    final restored = await manager.restoreFromFile();

    if (!restored) {
      // 如果没有保存的数据，创建默认布局
      logic.createDefaultLayout();
    }

    setState(() => _loading = false);
  }

  void _registerComponents() {
    manager.registry.register(
      'counter',
      builder:
          (values) => CounterWidget(
            initialValue: values['count'] ?? 0,
            onChanged: (newValue) {
              // 实时更新值
              manager.updateItemValues(values['id'], {
                'count': newValue,
                'id': values['id'],
              });
            },
          ),
      configBuilder:
          (context, onConfirm) => CounterConfigDialog(onConfirm: onConfirm),
    );

    manager.registry.register(
      'text',
      builder:
          (values) => Container(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                values['text'] ?? 'No text',
                style: TextStyle(
                  fontSize: values['fontSize']?.toDouble() ?? 18,
                  fontWeight: _parseStringToFontWeight(
                    values['fontWeight'] ?? 'normal',
                  ),
                  color: _parseStringToColor(values['color'] ?? '#000000'),
                ),
              ),
            ),
          ),
      configBuilder:
          (context, onConfirm) => TextConfigDialog(onConfirm: onConfirm),
    );

    manager.registry.register(
      'dynamic_widget',
      builder: (values) {
        final jsonData =
            values['jsonData'] as Map<String, dynamic>? ??
            {
              'type': 'text',
              'args': {'data': 'Dynamic Widget'},
            };
        return DynamicWidget(
          jsonData: jsonData,
          onDataChanged: () {
            // 当数据发生变化时，可以在这里处理
          },
        );
      },
      configBuilder:
          (context, onConfirm) =>
              DynamicWidgetConfigDialog(onConfirm: onConfirm),
    );
  }

  // 辅助方法：将字符串解析为 FontWeight
  FontWeight _parseStringToFontWeight(String fontWeightStr) {
    switch (fontWeightStr) {
      case 'bold':
        return FontWeight.bold;
      case 'w100':
        return FontWeight.w100;
      case 'w200':
        return FontWeight.w200;
      case 'w300':
        return FontWeight.w300;
      case 'w400':
        return FontWeight.w400;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      case 'w800':
        return FontWeight.w800;
      case 'w900':
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  // 辅助方法：将字符串解析为 Color
  Color _parseStringToColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      final hexColor = colorStr.substring(1);
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: DragToMoveArea(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.drag_indicator,
                size: 16,
                color: Theme.of(
                  context,
                ).textTheme.titleMedium?.color?.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              const Tooltip(
                message: '拖拽此区域移动窗口',
                child: Text('Docking Persistence Demo'),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.dashboard),
            tooltip: '多功能工具面板',
            onPressed: () => logic.showMultiTabDialog(),
          ),
          IconButton(
            icon: Icon(Icons.bug_report),
            tooltip: '调试工具',
            onPressed: () => logic.showDebugTab(),
          ),
          IconButton(
            icon: Icon(Icons.storage),
            tooltip: '调试布局存储管理器',
            onPressed: () => _showDebugLayoutManager(),
          ),
          IconButton(
            icon: Icon(Icons.add_box),
            tooltip: '添加组件',
            onPressed: () => logic.showAddComponentTab(),
          ),
          IconButton(icon: Icon(Icons.delete), onPressed: logic.clearLayout),
        ],
      ),
      body: TabbedViewTheme(
        data: DockTheme.createCustomThemeData(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: MultiSplitViewTheme(
            child: Docking(layout: manager.layout, draggable: _draggable),
            data: MultiSplitViewThemeData(
              dividerPainter: DividerPainters.grooved1(
                color: Colors.indigo[100]!,
                highlightedColor: Colors.indigo[900]!,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Tooltip(
            message: '切换拖拽功能',
            child: FloatingActionButton.small(
              tooltip: '切换拖拽',
              heroTag: 'toggle_drag',
              onPressed: _toggleDraggable,
              child: Icon(_draggable ? Icons.pan_tool_alt : Icons.do_not_touch),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }

  // ========= 事件处理 =========

  void _toggleDraggable() {
    setState(() => _draggable = !_draggable);
    logic.showSnackBar(_draggable ? '已启用拖拽功能' : '已禁用拖拽功能');
  }

  /// 显示调试布局存储管理器
  void _showDebugLayoutManager() {
    showDialog(
      context: context,
      builder: (context) => DebugLayoutPresetDialog(manager: manager),
    );
  }
}
