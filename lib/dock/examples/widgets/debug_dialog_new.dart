import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import '../dock_manager.dart';
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
  @override
  Widget build(BuildContext context) {
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
            Expanded(child: DebugDialogContent(manager: widget.manager)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 调试对话框内容组件（可在标签页中重用）
class DebugDialogContent extends StatefulWidget {
  final DockManager manager;

  const DebugDialogContent({Key? key, required this.manager}) : super(key: key);

  @override
  State<DebugDialogContent> createState() => _DebugDialogContentState();
}

class _DebugDialogContentState extends State<DebugDialogContent> {
  DockingItem? _selectedItem;
  DockingTabs? _selectedTabs;

  @override
  Widget build(BuildContext context) {
    final allAreas = widget.manager.layout.layoutAreas();
    final items = allAreas.whereType<DockingItem>().toList();
    final tabsAreas = allAreas.whereType<DockingTabs>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  onPressed: _showHierarchy,
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
        onRefresh: () => setState(() => _selectedItem = null),
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
        if (_selectedItem != null) ...[
          ElevatedButton(
            onPressed: () => _maximizeItem(_selectedItem!),
            child: const Text('最大化'),
          ),
          ElevatedButton(
            onPressed: () => _renameItem(_selectedItem!),
            child: const Text('重命名'),
          ),
          ElevatedButton(
            onPressed: () => _removeItem(_selectedItem!),
            child: const Text('删除'),
          ),
        ],
        if (_selectedTabs != null) ...[
          ElevatedButton(
            onPressed: () => _maximizeTabs(_selectedTabs!),
            child: const Text('最大化组'),
          ),
          ElevatedButton(
            onPressed: () => _addToTabs(_selectedTabs!),
            child: const Text('添加标签页'),
          ),
        ],
        ElevatedButton(
          onPressed: () => widget.manager.layout.restore(),
          child: const Text('还原布局'),
        ),
      ],
    );
  }

  void _showHierarchy() {
    final hierarchy = widget.manager.layout.hierarchy(
      indexInfo: true,
      levelInfo: true,
      hasParentInfo: true,
      nameInfo: true,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('布局层次结构'),
            content: Container(
              width: 400,
              height: 300,
              child: SingleChildScrollView(
                child: SelectableText(
                  hierarchy,
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
    );
  }

  void _maximizeItem(DockingItem item) {
    widget.manager.layout.maximizeDockingItem(item);
    _showSnackBar('已最大化: ${item.name}');
  }

  void _maximizeTabs(DockingTabs tabs) {
    widget.manager.layout.maximizeDockingTabs(tabs);
    _showSnackBar('已最大化标签组: ${tabs.id}');
  }

  void _renameItem(DockingItem item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('重命名'),
            content: TextField(
              controller: TextEditingController(text: item.name ?? ''),
              decoration: const InputDecoration(
                labelText: '新名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (newName) {
                if (newName.trim().isNotEmpty) {
                  item.name = newName.trim();
                  widget.manager.layout.rebuild();
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () {
                  final controller = TextEditingController(
                    text: item.name ?? '',
                  );
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty) {
                    item.name = newName;
                    widget.manager.layout.rebuild();
                    setState(() {});
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('确定'),
              ),
            ],
          ),
    );
  }

  void _removeItem(DockingItem item) {
    widget.manager.removeItemById(item.id);
    setState(() {
      _selectedItem = null;
    });
    _showSnackBar('已删除: ${item.name}');
  }

  void _addToTabs(DockingTabs tabs) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    widget.manager.addTypedItem(
      id: 'new_$timestamp',
      type: 'text',
      values: {'text': 'New tab created at ${DateTime.now()}'},
      targetArea: tabs,
      dropIndex: tabs.childrenCount,
      name: 'New Tab',
      keepAlive: true,
    );
    setState(() {});
    _showSnackBar('已向 ${tabs.id} 添加新标签页');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
