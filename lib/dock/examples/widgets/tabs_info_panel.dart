import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import '../dock_manager.dart';
import 'debug_dialog_utils.dart';

/// 标签组信息面板
class TabsInfoPanel extends StatelessWidget {
  final DockingTabs tabs;
  final DockManager manager;
  final VoidCallback onRefresh;

  const TabsInfoPanel({
    Key? key,
    required this.tabs,
    required this.manager,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DebugDialogUtils.buildInfoRow('ID', tabs.id?.toString() ?? '无'),
          DebugDialogUtils.buildInfoRow('类型', tabs.runtimeType.toString()),
          DebugDialogUtils.buildInfoRow('子项数量', tabs.childrenCount.toString()),
          DebugDialogUtils.buildInfoRow('选中索引', tabs.selectedIndex.toString()),
          DebugDialogUtils.buildInfoRow('最大化', tabs.maximized ? '是' : '否'),
          DebugDialogUtils.buildInfoRow(
            '可最大化',
            tabs.maximizable?.toString() ?? '继承',
          ),
          DebugDialogUtils.buildInfoRow('权重', tabs.weight?.toString() ?? '自动'),
          DebugDialogUtils.buildInfoRow(
            '最小权重',
            tabs.minimalWeight?.toString() ?? '无',
          ),
          DebugDialogUtils.buildInfoRow('大小', tabs.size?.toString() ?? '自动'),
          DebugDialogUtils.buildInfoRow('布局ID', tabs.layoutId.toString()),
          DebugDialogUtils.buildInfoRow('索引', tabs.index.toString()),
          DebugDialogUtils.buildInfoRow('层级', tabs.level.toString()),
          DebugDialogUtils.buildInfoRow('路径', tabs.path),

          const SizedBox(height: 16),
          const Text('父级信息：', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (tabs.parent != null) ...[
            DebugDialogUtils.buildInfoRow(
              '父级类型',
              tabs.parent.runtimeType.toString(),
            ),
            DebugDialogUtils.buildInfoRow(
              '父级ID',
              tabs.parent!.id?.toString() ?? '无',
            ),
          ] else
            const Text('无父级（根元素）', style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 16),
          const Text('子项列表：', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(tabs.childrenCount, (index) {
            final child = tabs.childAt(index);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text('$index: '),
                  Expanded(child: Text(child.name ?? '无名称')),
                  if (index == tabs.selectedIndex)
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // 操作按钮
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () => _maximizeTabs(context),
          icon: const Icon(Icons.fullscreen, size: 16),
          label: const Text('最大化组'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _addToTabs(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('添加标签页'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  void _maximizeTabs(BuildContext context) {
    manager.layout.maximizeDockingTabs(tabs);
    DebugDialogUtils.showSuccess(context, '已最大化标签组: ${tabs.id}');
  }

  void _addToTabs(BuildContext context) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    manager.addTypedItem(
      id: 'new_$timestamp',
      type: 'text',
      values: {'text': 'New tab created at ${DateTime.now()}'},
      targetArea: tabs,
      dropIndex: tabs.childrenCount,
      name: 'New Tab',
      keepAlive: true,
    );
    onRefresh();
    DebugDialogUtils.showSuccess(context, '已向 ${tabs.id} 添加新标签页');
  }
}
