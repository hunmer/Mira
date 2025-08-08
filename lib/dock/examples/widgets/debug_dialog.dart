import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import '../dock_manager.dart';
import 'debug_dialog_utils.dart';
import 'item_info_panel.dart';
import 'tabs_info_panel.dart';

/// 调试对话框主界面
class DebugDialog extends StatefulWidget {
  final DockManager manager;

  const DebugDialog({Key? key, required this.manager}) : super(key: key);

  @override
  State<DebugDialog> createState() => _DebugDialogState();
}

class _DebugDialogState extends State<DebugDialog> {
  DockingItem? _selectedItem;
  DockingTabs? _selectedTabs;

  @override
  Widget build(BuildContext context) {
    final allAreas = widget.manager.layout.layoutAreas();
    final items = allAreas.whereType<DockingItem>().toList();
    final tabsAreas = allAreas.whereType<DockingTabs>().toList();

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('调试工具', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // 布局信息
            _buildLayoutInfoCard(allAreas, items, tabsAreas),

            const SizedBox(height: 16),

            // 主要内容区域
            Expanded(
              child: Row(
                children: [
                  // 左侧：标签页和标签组列表
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // 标签页列表
                        _buildItemsList(items),
                        const SizedBox(height: 8),
                        // 标签组列表
                        _buildTabsList(tabsAreas),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 右侧：详细信息面板
                  Expanded(
                    flex: 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '详细信息',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Expanded(child: _buildInfoPanel()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 底部操作按钮
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutInfoCard(
    List<DockingArea> allAreas,
    List<DockingItem> items,
    List<DockingTabs> tabsAreas,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('布局信息', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('总区域数: ${allAreas.length}'),
                      Text('标签页数: ${items.length}'),
                      Text('标签组数: ${tabsAreas.length}'),
                      Text(
                        '最大化区域: ${widget.manager.layout.maximizedArea?.id ?? '无'}',
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      () => DebugDialogUtils.showHierarchy(
                        context,
                        widget.manager,
                      ),
                  child: const Text('查看层次结构'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(List<DockingItem> items) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('标签页', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = _selectedItem == item;
                    return ListTile(
                      selected: isSelected,
                      title: Text(item.name ?? '无名称'),
                      subtitle: Text('ID: ${item.id}'),
                      trailing:
                          item.maximized ? const Icon(Icons.fullscreen) : null,
                      onTap: () {
                        setState(() {
                          _selectedItem = isSelected ? null : item;
                          _selectedTabs = null;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabsList(List<DockingTabs> tabsAreas) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('标签组', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: tabsAreas.length,
                  itemBuilder: (context, index) {
                    final tabs = tabsAreas[index];
                    final isSelected = _selectedTabs == tabs;
                    return ListTile(
                      selected: isSelected,
                      title: Text('标签组 ${tabs.id}'),
                      subtitle: Text('子项数: ${tabs.childrenCount}'),
                      trailing:
                          tabs.maximized ? const Icon(Icons.fullscreen) : null,
                      onTap: () {
                        setState(() {
                          _selectedTabs = isSelected ? null : tabs;
                          _selectedItem = null;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    if (_selectedItem != null) {
      return ItemInfoPanel(
        item: _selectedItem!,
        manager: widget.manager,
        onRefresh:
            () => setState(() {
              // 刷新选择状态，可能项目已被删除
              if (_selectedItem != null &&
                  !widget.manager.layout.layoutAreas().contains(
                    _selectedItem,
                  )) {
                _selectedItem = null;
              }
            }),
      );
    } else if (_selectedTabs != null) {
      return TabsInfoPanel(
        tabs: _selectedTabs!,
        manager: widget.manager,
        onRefresh: () => setState(() {}),
      );
    } else {
      return const Center(
        child: Text(
          '请选择一个标签页或标签组\n查看详细信息',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
  }

  Widget _buildBottomActions() {
    return Wrap(
      spacing: 8,
      children: [
        ElevatedButton(
          onPressed: () {
            widget.manager.layout.restore();
            DebugDialogUtils.showSuccess(context, '已还原布局');
          },
          child: const Text('还原布局'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
