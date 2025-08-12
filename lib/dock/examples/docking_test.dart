import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';
import 'package:mira/core/widgets/window_controls.dart';

// 一个可延迟加载并带自增按钮的示例内容组件，用于测试 keepAlive
class LazyCounterPanel extends StatefulWidget {
  final String title;
  final Duration delay;
  const LazyCounterPanel({
    super.key,
    required this.title,
    this.delay = const Duration(milliseconds: 800),
  });

  @override
  State<LazyCounterPanel> createState() => _LazyCounterPanelState();
}

class _LazyCounterPanelState extends State<LazyCounterPanel>
    with AutomaticKeepAliveClientMixin {
  bool _loaded = false;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin
    if (!_loaded) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('正在加载 ${widget.title} ...'),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '面板：${widget.title}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => setState(() => _count++),
            child: Text('自增：$_count'),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class DockingExample extends StatefulWidget {
  const DockingExample({super.key});

  @override
  State<DockingExample> createState() => _MyDockingPageState();
}

class _MyDockingPageState extends State<DockingExample> {
  // 1) 维护同一个 DockingLayout 实例
  final DockingLayout layout = DockingLayout(
    root: DockingTabs([
      DockingItem(
        id: 'a',
        name: 'A',
        widget: const LazyCounterPanel(title: 'A'),
        keepAlive: true,
      ),
      DockingItem(
        id: 'b',
        name: 'B',
        widget: const LazyCounterPanel(title: 'B'),
        keepAlive: true,
      ),
    ], id: 'tabs1'),
  );

  // 运行时控制
  bool _draggable = true;
  int _seq = 0; // 用于生成唯一ID

  @override
  Widget build(BuildContext context) {
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
                  // ignore: deprecated_member_use
                ).textTheme.titleMedium?.color?.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              const Tooltip(message: '拖拽此区域移动窗口', child: Text('Docking Demo')),
            ],
          ),
        ),
      ),
      body: Docking(layout: layout, draggable: _draggable),
      // 更多带提示与反馈的调试按钮
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Tooltip(
            message: '在 A 的右侧添加新面板',
            child: FloatingActionButton.small(
              tooltip: '右侧添加',
              onPressed: _addRightOfA,
              child: const Icon(Icons.arrow_right),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '在 A 的左侧添加新面板',
            child: FloatingActionButton.small(
              tooltip: '左侧添加',
              onPressed: _addLeftOfA,
              child: const Icon(Icons.arrow_left),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '在 A 的上方添加新面板',
            child: FloatingActionButton.small(
              tooltip: '上方添加',
              onPressed: _addTopOfA,
              child: const Icon(Icons.arrow_upward),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '在 A 的下方添加新面板',
            child: FloatingActionButton.small(
              tooltip: '下方添加',
              onPressed: _addBottomOfA,
              child: const Icon(Icons.arrow_downward),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '向 tabs1 末尾添加一个新的 Tab',
            child: FloatingActionButton.small(
              tooltip: '添加 Tab',
              onPressed: _addTabToTabs1,
              child: const Icon(Icons.tab),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '把 A 移动到 tabs1 的第一个位置',
            child: FloatingActionButton.small(
              tooltip: '移动 A',
              onPressed: _moveAToFirstTab,
              child: const Icon(Icons.swap_horiz),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '删除面板 B',
            child: FloatingActionButton.small(
              tooltip: '删除 B',
              onPressed: _removeB,
              child: const Icon(Icons.close),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '重命名面板 A',
            child: FloatingActionButton.small(
              tooltip: '重命名 A',
              onPressed: _renameA,
              child: const Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '最大化 A 面板',
            child: FloatingActionButton.small(
              tooltip: '最大化 A',
              onPressed: _maximizeA,
              child: const Icon(Icons.fullscreen),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '还原所有最大化状态',
            child: FloatingActionButton.small(
              tooltip: '还原布局',
              onPressed: _restoreLayout,
              child: const Icon(Icons.fullscreen_exit),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: _draggable ? '禁用拖拽' : '启用拖拽',
            child: FloatingActionButton.small(
              tooltip: '切换拖拽',
              onPressed: _toggleDraggable,
              child: Icon(_draggable ? Icons.pan_tool_alt : Icons.do_not_touch),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '打印布局结构到控制台',
            child: FloatingActionButton.small(
              tooltip: '打印布局',
              onPressed: _printHierarchy,
              child: const Icon(Icons.list),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: '在嵌套的Docking中添加新面板',
            child: FloatingActionButton.small(
              tooltip: '嵌套Docking',
              onPressed: _addNestedDocking,
              child: const Icon(Icons.layers),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  DockingItem _newItem(String baseName) {
    _seq++;
    final id = '${baseName.toLowerCase()}_$_seq';
    return DockingItem(
      id: id,
      name: '$baseName $_seq',
      widget: LazyCounterPanel(title: '$baseName $_seq'),
      keepAlive: true,
    );
  }

  // 2) 添加：把新面板放到某个 DockingItem 的右侧
  void _addRightOfA() {
    final target = layout.findDockingItem('a');
    if (target != null) {
      layout.addItemOn(
        newItem: _newItem('C'),
        targetArea: target,
        dropPosition: DropPosition.right,
      );
      _snack('已在 A 右侧添加新面板');
    } else {
      _snack('未找到面板 A');
    }
  }

  void _addLeftOfA() {
    final target = layout.findDockingItem('a');
    if (target != null) {
      layout.addItemOn(
        newItem: _newItem('L'),
        targetArea: target,
        dropPosition: DropPosition.left,
      );
      _snack('已在 A 左侧添加新面板');
    } else {
      _snack('未找到面板 A');
    }
  }

  void _addTopOfA() {
    final target = layout.findDockingItem('a');
    if (target != null) {
      layout.addItemOn(
        newItem: _newItem('T'),
        targetArea: target,
        dropPosition: DropPosition.top,
      );
      _snack('已在 A 上方添加新面板');
    } else {
      _snack('未找到面板 A');
    }
  }

  void _addBottomOfA() {
    final target = layout.findDockingItem('a');
    if (target != null) {
      layout.addItemOn(
        newItem: _newItem('Btm'),
        targetArea: target,
        dropPosition: DropPosition.bottom,
      );
      _snack('已在 A 下方添加新面板');
    } else {
      _snack('未找到面板 A');
    }
  }

  // 3) 添加为 Tab：把新面板插入到某个 Tabs 的指定索引
  void _addTabToTabs1() {
    final tabs = layout.findDockingArea('tabs1') as DockingTabs?;
    if (tabs != null) {
      layout.addItemOn(
        newItem: _newItem('Tab'),
        targetArea: tabs,
        dropIndex: tabs.childrenCount, // 插到最后
      );
      _snack('已向 tabs1 添加新 Tab');
    } else {
      _snack('未找到 tabs1');
    }
  }

  // 4) 移动：把已有面板移动到某个 Tabs 的第一个位置（索引 0）
  void _moveAToFirstTab() {
    final item = layout.findDockingItem('a');
    final tabs = layout.findDockingArea('tabs1') as DockingTabs?;
    if (item != null && tabs != null) {
      layout.moveItem(
        draggedItem: item,
        targetArea: tabs,
        dropIndex: 0, // 只传一个：dropIndex 或 dropPosition
      );
      _snack('已将 A 移动到 tabs1 的第一个位置');
    } else {
      _snack('未找到 A 或 tabs1');
    }
  }

  // 5) 删除：按 id 删除
  void _removeB() {
    final exists = layout.findDockingItem('b') != null;
    layout.removeItemByIds(['b']);
    _snack(exists ? '已删除面板 B' : '面板 B 不存在或已删除');
  }

  // 6) 更新：修改标题/内容后刷新
  void _renameA() {
    final item = layout.findDockingItem('a');
    if (item != null) {
      item.name = 'A (renamed)';
      // 若只改子 Widget 自己会重建就不需要；但改 DockingItem 的属性(如 name)后建议显式刷新
      layout.rebuild();
      _snack('已重命名 A');
    } else {
      _snack('未找到面板 A');
    }
  }

  void _maximizeA() {
    final item = layout.findDockingItem('a');
    if (item != null) {
      layout.maximizeDockingItem(item);
      _snack('已最大化 A');
    } else {
      _snack('未找到面板 A');
    }
  }

  void _restoreLayout() {
    layout.restore();
    _snack('已还原最大化状态');
  }

  void _toggleDraggable() {
    setState(() => _draggable = !_draggable);
    _snack(_draggable ? '已启用拖拽' : '已禁用拖拽');
  }

  void _printHierarchy() {
    final s = layout.hierarchy(
      indexInfo: true,
      levelInfo: true,
      hasParentInfo: true,
      nameInfo: true,
    );
    // 打印到控制台
    // ignore: avoid_print
    print(s);
    _snack('已打印布局结构到控制台');
  }

  void _addNestedDocking() {
    // 创建一个嵌套的Docking布局
    final nestedLayout = DockingLayout(
      root: DockingTabs([
        DockingItem(
          id: 'nested_1',
          name: '嵌套面板 1',
          widget: const LazyCounterPanel(title: '嵌套面板 1'),
          keepAlive: true,
        ),
        DockingItem(
          id: 'nested_2',
          name: '嵌套面板 2',
          widget: const LazyCounterPanel(title: '嵌套面板 2'),
          keepAlive: true,
        ),
      ], id: 'nested_tabs'),
    );

    // 将嵌套的Docking作为新的DockingItem添加到主布局
    final nestedDockingItem = _newItem('嵌套Dock');
    nestedDockingItem.widget = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Docking(layout: nestedLayout, draggable: true),
    );

    final tabs = layout.findDockingArea('tabs1') as DockingTabs?;
    if (tabs != null) {
      layout.addItemOn(
        newItem: nestedDockingItem,
        targetArea: tabs,
        dropIndex: tabs.childrenCount,
      );
      _snack('已添加嵌套Docking面板');
    } else {
      _snack('未找到 tabs1');
    }
  }
}
