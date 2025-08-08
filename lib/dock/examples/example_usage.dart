import 'package:flutter/material.dart';
import 'package:mira/dock/dock_theme.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/core/widgets/window_controls.dart';
import 'package:mira/multi_split_view/lib/multi_split_view.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';
import 'dock_manager.dart';
import 'docking_persistence_logic.dart';
import 'widgets/counter_widget.dart';

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
    );

    manager.registry.register(
      'text',
      builder:
          (values) => Container(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                values['text'] ?? 'No text',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
    );
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
            icon: Icon(Icons.add_box),
            tooltip: '添加组件',
            onPressed: () => logic.showAddComponentTab(),
          ),
          IconButton(icon: Icon(Icons.save), onPressed: logic.saveLayout),
          IconButton(icon: Icon(Icons.restore), onPressed: logic.restoreLayout),
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
}
