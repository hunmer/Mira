import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mira/dock/dock_controller.dart';
import 'package:mira/dock/dock_events.dart';

/// 示例：如何使用新的Dock事件系统
class DockUsageExample extends StatefulWidget {
  const DockUsageExample({super.key});

  @override
  State<DockUsageExample> createState() => _DockUsageExampleState();
}

class _DockUsageExampleState extends State<DockUsageExample> {
  late DockController _dockController;
  late StreamSubscription<DockEvent> _eventSubscription;
  final List<String> _eventLog = [];

  @override
  void initState() {
    super.initState();

    // 创建DockController并监听事件
    _dockController = DockController(dockTabsId: 'example');
    _dockController.addListener(_onDockControllerChanged);

    // 监听dock事件
    _eventSubscription = _dockController.eventStream.listen(_onDockEvent);

    // 初始化dock系统，尝试加载之前保存的布局
    _dockController.initializeDockSystem(savedLayoutId: 'example_layout');
  }

  void _onDockControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onDockEvent(DockEvent event) {
    setState(() {
      final eventDesc = _formatEvent(event);
      _eventLog.insert(0, eventDesc);
      // 保持日志最多50条
      if (_eventLog.length > 50) {
        _eventLog.removeRange(50, _eventLog.length);
      }
    });
  }

  String _formatEvent(DockEvent event) {
    final time =
        '${event.timestamp.hour}:${event.timestamp.minute}:${event.timestamp.second}';

    switch (event.type) {
      case DockEventType.tabCreated:
        final tabEvent = event as DockTabEvent;
        return '[$time] Tab创建: ${tabEvent.displayName} (ID: ${tabEvent.tabId})';

      case DockEventType.tabClosed:
        final tabEvent = event as DockTabEvent;
        return '[$time] Tab关闭: ${tabEvent.displayName} (ID: ${tabEvent.tabId})';

      case DockEventType.tabSwitched:
        final tabEvent = event as DockTabEvent;
        return '[$time] Tab切换: ${tabEvent.displayName} (ID: ${tabEvent.tabId})';

      case DockEventType.itemCreated:
        final itemEvent = event as DockItemEvent;
        return '[$time] Item创建: ${itemEvent.itemTitle} (类型: ${itemEvent.itemType})';

      case DockEventType.itemClosed:
        final itemEvent = event as DockItemEvent;
        return '[$time] Item关闭: ${itemEvent.itemTitle} (类型: ${itemEvent.itemType})';

      case DockEventType.layoutChanged:
        return '[$time] 布局变更';
    }
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    _dockController.removeListener(_onDockControllerChanged);
    _dockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dock事件系统示例'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // 创建新的tab
              _dockController.createTabWithName(
                '新Tab ${DateTime.now().millisecondsSinceEpoch}',
              );
            },
            tooltip: '创建新Tab',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // 保存当前布局
              final success = _dockController.saveLayout();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? '布局保存成功' : '布局保存失败')),
              );
            },
            tooltip: '保存布局',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () {
              // 加载保存的布局
              final success = _dockController.loadLayout();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? '布局加载成功' : '布局加载失败')),
              );
            },
            tooltip: '加载布局',
          ),
        ],
      ),
      body: Row(
        children: [
          // 左侧：事件日志
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: const Text(
                    '事件日志',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _eventLog.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: index % 2 == 0 ? Colors.grey.shade50 : null,
                        ),
                        child: Text(
                          _eventLog[index],
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 右侧：Dock系统
          Expanded(child: _dockController.dockTabs.buildDockingWidget(context)),
        ],
      ),
    );
  }
}
