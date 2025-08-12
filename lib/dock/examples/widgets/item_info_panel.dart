import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import '../dock_manager.dart';
import '../dialog/debug_dialog_utils.dart';

/// 标签页信息面板
class ItemInfoPanel extends StatelessWidget {
  final DockingItem item;
  final DockManager manager;
  final VoidCallback onRefresh;

  const ItemInfoPanel({
    super.key,
    required this.item,
    required this.manager,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DebugDialogUtils.buildInfoRow('名称', item.name ?? '无名称'),
          DebugDialogUtils.buildInfoRow('ID', item.id?.toString() ?? '无'),
          DebugDialogUtils.buildInfoRow('类型', item.runtimeType.toString()),
          DebugDialogUtils.buildInfoRow('可关闭', item.closable ? '是' : '否'),
          DebugDialogUtils.buildInfoRow('最大化', item.maximized ? '是' : '否'),
          DebugDialogUtils.buildInfoRow(
            '可最大化',
            item.maximizable?.toString() ?? '继承',
          ),
          DebugDialogUtils.buildInfoRow(
            '保持活跃',
            item.globalKey != null ? '是' : '否',
          ),
          DebugDialogUtils.buildInfoRow('权重', item.weight?.toString() ?? '自动'),
          DebugDialogUtils.buildInfoRow(
            '最小权重',
            item.minimalWeight?.toString() ?? '无',
          ),
          DebugDialogUtils.buildInfoRow('大小', item.size?.toString() ?? '自动'),
          DebugDialogUtils.buildInfoRow('布局ID', item.layoutId.toString()),
          DebugDialogUtils.buildInfoRow('索引', item.index.toString()),
          DebugDialogUtils.buildInfoRow('层级', item.level.toString()),
          DebugDialogUtils.buildInfoRow('路径', item.path),

          const SizedBox(height: 16),
          const Text('父级信息：', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (item.parent != null) ...[
            DebugDialogUtils.buildInfoRow(
              '父级类型',
              item.parent.runtimeType.toString(),
            ),
            DebugDialogUtils.buildInfoRow(
              '父级ID',
              item.parent!.id?.toString() ?? '无',
            ),
          ] else
            const Text('无父级（根元素）', style: TextStyle(color: Colors.grey)),

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
          onPressed: () => _maximizeItem(context),
          icon: const Icon(Icons.fullscreen, size: 16),
          label: const Text('最大化'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _renameItem(context),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('重命名'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _removeItem(context),
          icon: const Icon(Icons.delete, size: 16),
          label: const Text('删除'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _maximizeItem(BuildContext context) {
    manager.layout.maximizeDockingItem(item);
    DebugDialogUtils.showSuccess(context, '已最大化: ${item.name}');
  }

  void _renameItem(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => RenameDialog(
            initialName: item.name ?? '',
            onRenamed: (newName) {
              item.name = newName;
              manager.layout.rebuild();
              onRefresh();
            },
          ),
    );
  }

  void _removeItem(BuildContext context) {
    manager.removeItemById(item.id);
    onRefresh();
    DebugDialogUtils.showSuccess(context, '已删除: ${item.name}');
  }
}
