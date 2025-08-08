import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';

class DockingExample extends StatefulWidget {
  @override
  State<DockingExample> createState() => _MyDockingPageState();
}

class _MyDockingPageState extends State<DockingExample> {
  // 1) 维护同一个 DockingLayout 实例
  final DockingLayout layout = DockingLayout(
    root: DockingTabs([
      DockingItem(id: 'a', name: 'A', widget: Text('A'), keepAlive: true),
      DockingItem(id: 'b', name: 'B', widget: Text('B'), keepAlive: true),
    ], id: 'tabs1'),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Docking Demo')),
      body: Docking(layout: layout, draggable: true),
      // 你可以放一些按钮来触发"实时"操作
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            onPressed: _addRightOfA,
            child: Icon(Icons.arrow_right),
          ),
          SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: _addTabToTabs1,
            child: Icon(Icons.tab),
          ),
          SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: _moveAToFirstTab,
            child: Icon(Icons.swap_horiz),
          ),
          SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: _removeB,
            child: Icon(Icons.close),
          ),
          SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: _renameA,
            child: Icon(Icons.edit),
          ),
        ],
      ),
    );
  }

  // 2) 添加：把新面板放到某个 DockingItem 的右侧
  void _addRightOfA() {
    final target = layout.findDockingItem('a');
    if (target != null) {
      layout.addItemOn(
        newItem: DockingItem(
          id: 'c',
          name: 'C',
          widget: Text('C'),
          keepAlive: true,
        ),
        targetArea: target, // 目标可以是 DockingItem 或 DockingTabs（它们实现了 DropArea）
        dropPosition: DropPosition.right, // 与 dropIndex 二选一
      );
    }
  }

  // 3) 添加为 Tab：把新面板插入到某个 Tabs 的指定索引
  void _addTabToTabs1() {
    final tabs = layout.findDockingArea('tabs1') as DockingTabs?;
    if (tabs != null) {
      layout.addItemOn(
        newItem: DockingItem(id: 'd', name: 'D', widget: Text('D')),
        targetArea: tabs,
        dropIndex: tabs.childrenCount, // 插到最后；与 dropPosition 互斥
      );
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
    }
  }

  // 5) 删除：按 id 删除
  void _removeB() {
    layout.removeItemByIds(['b']);
  }

  // 6) 更新：修改标题/内容后刷新
  void _renameA() {
    final item = layout.findDockingItem('a');
    if (item != null) {
      item.name = 'A (renamed)';
      // 若只改子 Widget 自己会重建就不需要；但改 DockingItem 的属性(如 name)后建议显式刷新
      layout.rebuild();
    }
  }
}
