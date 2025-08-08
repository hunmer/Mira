// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:mira/dock/dock_theme.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/core/widgets/window_controls.dart';
import 'package:mira/dock/examples/widgets/dock_item_registrar.dart';
import 'package:mira/multi_split_view/lib/multi_split_view.dart';
import 'package:mira/tabbed/tabbed_view/lib/tabbed_view.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';
import 'dock_manager.dart';
import 'docking_persistence_logic.dart';
import '../debug_layout_preset_dialog.dart';

// ========= 示例页面 =========

class DockingPersistenceDemo extends StatefulWidget {
  const DockingPersistenceDemo({super.key});

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
    DockItemRegistrar.registerAllComponents(manager);

    // 尝试恢复上次的布局
    final restored = await manager.restoreFromFile();

    if (!restored) {
      // 如果没有保存的数据，创建默认布局
      logic.createDefaultLayout();
    }

    setState(() => _loading = false);
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
            data: MultiSplitViewThemeData(
              dividerPainter: DividerPainters.grooved1(
                color: Colors.indigo[100]!,
                highlightedColor: Colors.indigo[900]!,
              ),
            ),
            child: Docking(
              layout: manager.layout,
              draggable: _draggable,
              breakpoints: const ScreenBreakpoints(
                desktop: 800,
                tablet: 600,
                watch: 200,
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
          const SizedBox(height: 12),
          Tooltip(
            message: '一键添加演示 DockingItem（不同设备可见性）',
            child: FloatingActionButton.small(
              tooltip: '添加设备演示项',
              heroTag: 'add_device_demo_items',
              onPressed: _addDeviceDemoItems,
              child: const Icon(Icons.devices_other),
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

  /// 一键添加多个带 showAtDevices 的 DockingItem
  void _addDeviceDemoItems() {
    final layout = manager.layout;

    // 选择一个可投放的目标区域（优先 DockingTabs，其次任意 DockingItem，再不行用 root 只要是 DropArea）
    DockingArea? target = _findPreferredDropArea();
    if (target is! DropArea) {
      logic.showSnackBar('未找到可添加的目标区域');
      return;
    }

    // 为了避免 id 冲突，使用时间戳前缀
    final ts = DateTime.now().millisecondsSinceEpoch;

    final demos = [
      (
        id: 'demo_desktop_$ts',
        name: 'Desktop Only',
        devices: [DeviceScreenType.desktop],
        color: Colors.blue,
      ),
      (
        id: 'demo_tablet_$ts',
        name: 'Tablet Only',
        devices: [DeviceScreenType.tablet],
        color: Colors.green,
      ),
      (
        id: 'demo_mobile_$ts',
        name: 'Mobile Only',
        devices: [DeviceScreenType.mobile],
        color: Colors.orange,
      ),
      (
        id: 'demo_watch_$ts',
        name: 'Watch Only',
        devices: [DeviceScreenType.watch],
        color: Colors.purple,
      ),
      (
        id: 'demo_desktop_tablet_$ts',
        name: 'Desktop + Tablet',
        devices: [DeviceScreenType.desktop, DeviceScreenType.tablet],
        color: Colors.indigo,
      ),
    ];

    for (final d in demos) {
      layout.addItemOn(
        newItem: DockingItem(
          id: d.id,
          name: d.name,
          widget: _buildDeviceDemoBox(d.name, d.devices, d.color),
          showAtDevices: d.devices,
          closable: true,
          keepAlive: true,
          maximizable: true,
        ),
        targetArea: target as DropArea,
        dropPosition: target is DockingTabs ? null : DropPosition.right,
        dropIndex: target is DockingTabs ? 0 : null,
      );
    }

    logic.showSnackBar('已添加 ${demos.length} 个演示 DockingItem');
  }

  /// 从当前布局中挑选一个合适的可投放区域
  DockingArea? _findPreferredDropArea() {
    final layout = manager.layout;
    // 优先选择已有的 DockingTabs
    for (final area in layout.layoutAreas()) {
      if (area is DockingTabs) return area;
    }
    // 其次选择任意 DockingItem
    for (final area in layout.layoutAreas()) {
      if (area is DockingItem) return area;
    }
    // 最后尝试使用 root（如果支持 DropArea）
    final root = layout.root;
    if (root is DropArea) return root as DockingArea;
    return null;
  }

  Widget _buildDeviceDemoBox(
    String title,
    List<DeviceScreenType> devices,
    Color color,
  ) {
    final deviceText = devices.map((e) => e.name).join(' / ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$title\n(showAtDevices: $deviceText)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.3,
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
