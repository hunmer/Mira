import 'package:flutter/material.dart';
import '../dock_manager.dart';
import 'dock_debug_dialog.dart';
import 'add_component_dialog.dart';

/// 多功能标签页对话框
class MultiTabDialog extends StatefulWidget {
  final DockManager manager;
  final Function(String message) onShowSnackBar;
  final int initialTabIndex;

  const MultiTabDialog({
    super.key,
    required this.manager,
    required this.onShowSnackBar,
    this.initialTabIndex = 0,
  });

  @override
  State<MultiTabDialog> createState() => _MultiTabDialogState();
}

class _MultiTabDialogState extends State<MultiTabDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 800,
        height: 700,
        child: Column(
          children: [
            // 标签页头部
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.bug_report), text: '调试工具'),
                  Tab(icon: Icon(Icons.add_box), text: '添加组件'),
                ],
              ),
            ),

            // 标签页内容
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 调试工具页面
                  _DebugTabContent(manager: widget.manager),

                  // 添加组件页面
                  _AddComponentTabContent(
                    manager: widget.manager,
                    onShowSnackBar: widget.onShowSnackBar,
                  ),
                ],
              ),
            ),

            // 底部操作栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 调试工具标签页内容
class _DebugTabContent extends StatelessWidget {
  final DockManager manager;

  const _DebugTabContent({required this.manager});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: DebugDialogContent(manager: manager),
    );
  }
}

/// 添加组件标签页内容
class _AddComponentTabContent extends StatelessWidget {
  final DockManager manager;
  final Function(String message) onShowSnackBar;

  const _AddComponentTabContent({
    required this.manager,
    required this.onShowSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: AddComponentDialogContent(
        manager: manager,
        onShowSnackBar: onShowSnackBar,
      ),
    );
  }
}
