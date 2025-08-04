import 'package:flutter/material.dart';

/// 右键菜单包装器 - 增强版，支持更多功能
class ContextMenuWrapper extends StatelessWidget {
  final Widget child;
  final String itemName;
  final String? itemType;
  final VoidCallback? onRename;
  final VoidCallback? onClose;
  final VoidCallback? onDuplicate;
  final VoidCallback? onMaximize;
  final VoidCallback? onMinimize;
  final VoidCallback? onSaveLayout;
  final VoidCallback? onExport;
  final Map<String, VoidCallback>? customActions;

  const ContextMenuWrapper({
    Key? key,
    required this.child,
    required this.itemName,
    this.itemType,
    this.onRename,
    this.onClose,
    this.onDuplicate,
    this.onMaximize,
    this.onMinimize,
    this.onSaveLayout,
    this.onExport,
    this.customActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      onLongPress: () {
        // 在移动设备上支持长按显示菜单
        _showContextMenu(context, Offset.zero);
      },
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final items = <PopupMenuEntry<String>>[];

    // 编辑操作
    if (onRename != null) {
      items.add(
        PopupMenuItem<String>(
          value: 'rename',
          child: const Row(
            children: [
              Icon(Icons.edit, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text('重命名'),
            ],
          ),
        ),
      );
    }

    if (onDuplicate != null) {
      items.add(
        PopupMenuItem<String>(
          value: 'duplicate',
          child: const Row(
            children: [
              Icon(Icons.copy, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Text('复制'),
            ],
          ),
        ),
      );
    }

    // 布局操作
    if (onMaximize != null || onMinimize != null) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider());

      if (onMaximize != null) {
        items.add(
          PopupMenuItem<String>(
            value: 'maximize',
            child: const Row(
              children: [
                Icon(Icons.fullscreen, size: 16, color: Colors.purple),
                SizedBox(width: 8),
                Text('最大化'),
              ],
            ),
          ),
        );
      }

      if (onMinimize != null) {
        items.add(
          PopupMenuItem<String>(
            value: 'minimize',
            child: const Row(
              children: [
                Icon(Icons.fullscreen_exit, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Text('最小化'),
              ],
            ),
          ),
        );
      }
    }

    // 保存和导出操作
    if (onSaveLayout != null || onExport != null) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider());

      if (onSaveLayout != null) {
        items.add(
          PopupMenuItem<String>(
            value: 'save_layout',
            child: const Row(
              children: [
                Icon(Icons.save, size: 16, color: Colors.indigo),
                SizedBox(width: 8),
                Text('保存布局'),
              ],
            ),
          ),
        );
      }

      if (onExport != null) {
        items.add(
          PopupMenuItem<String>(
            value: 'export',
            child: const Row(
              children: [
                Icon(Icons.download, size: 16, color: Colors.teal),
                SizedBox(width: 8),
                Text('导出'),
              ],
            ),
          ),
        );
      }
    }

    // 自定义操作
    if (customActions != null && customActions!.isNotEmpty) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider());

      for (var entry in customActions!.entries) {
        items.add(
          PopupMenuItem<String>(
            value: 'custom_${entry.key}',
            child: Row(
              children: [
                const Icon(Icons.extension, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(entry.key),
              ],
            ),
          ),
        );
      }
    }

    // 删除操作（放在最后）
    if (onClose != null) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem<String>(
          value: 'close',
          child: const Row(
            children: [
              Icon(Icons.close, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('关闭', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    if (items.isNotEmpty) {
      // 使用Overlay而不是showMenu以获得更好的定位
      final RenderBox? overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;

      if (overlay != null) {
        showMenu<String>(
          context: context,
          position: position == Offset.zero
              ? RelativeRect.fromLTRB(100, 100, 100, 100) // 长按时的默认位置
              : RelativeRect.fromLTRB(
                  position.dx,
                  position.dy,
                  overlay.size.width - position.dx,
                  overlay.size.height - position.dy,
                ),
          items: items,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ).then((String? selectedAction) {
          if (selectedAction != null) {
            _handleMenuAction(context, selectedAction);
          }
        });
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context);
        break;
      case 'duplicate':
        onDuplicate?.call();
        break;
      case 'maximize':
        onMaximize?.call();
        break;
      case 'minimize':
        onMinimize?.call();
        break;
      case 'save_layout':
        onSaveLayout?.call();
        break;
      case 'export':
        onExport?.call();
        break;
      case 'close':
        _showCloseConfirmation(context);
        break;
      default:
        if (action.startsWith('custom_')) {
          final customKey = action.substring(7); // 移除 'custom_' 前缀
          customActions?[customKey]?.call();
        }
        break;
    }
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: itemName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('重命名'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (itemType != null) ...[
              Text(
                '类型: $itemType',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '新名称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.pop(context);
                  onRename?.call();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                onRename?.call();
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showCloseConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('确认关闭'),
          ],
        ),
        content: Text('确定要关闭 "$itemName" 吗？\n\n此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onClose?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
