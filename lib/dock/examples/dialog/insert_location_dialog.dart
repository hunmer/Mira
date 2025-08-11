import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';

/// 插入位置选择结果
class InsertLocationResult {
  final DockingArea targetArea;
  final DropPosition? dropPosition;
  final int? dropIndex;

  InsertLocationResult({
    required this.targetArea,
    this.dropPosition,
    this.dropIndex,
  });
}

/// 显示插入位置选择对话框
class InsertLocationDialog extends StatefulWidget {
  final DockingLayout layout;

  const InsertLocationDialog({super.key, required this.layout});

  @override
  State<InsertLocationDialog> createState() => _InsertLocationDialogState();
}

class _InsertLocationDialogState extends State<InsertLocationDialog> {
  DockingArea? selectedArea;

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
            Row(
              children: [
                const Icon(Icons.dashboard_customize, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '选择插入位置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '点击方块选择插入位置，然后选择插入方向：',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildLayoutVisualization(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutVisualization() {
    if (widget.layout.root == null) {
      return const Center(
        child: Text('布局为空', style: TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildAreaWidget(widget.layout.root!, isRoot: true),
    );
  }

  Widget _buildAreaWidget(DockingArea area, {bool isRoot = false}) {
    if (area is DockingRow) {
      return _buildRowWidget(area);
    } else if (area is DockingColumn) {
      return _buildColumnWidget(area);
    } else if (area is DockingTabs) {
      return _buildTabsWidget(area);
    } else if (area is DockingItem) {
      return _buildItemWidget(area);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('未知区域'),
    );
  }

  Widget _buildRowWidget(DockingRow row) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade300, width: 2),
        borderRadius: BorderRadius.circular(6),
        color: Colors.blue.shade50,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Row (${row.childrenCount} 项)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: List.generate(row.childrenCount, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index > 0 ? 2 : 0,
                      right: index < row.childrenCount - 1 ? 2 : 0,
                    ),
                    child: _buildAreaWidget(row.childAt(index)),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnWidget(DockingColumn column) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade300, width: 2),
        borderRadius: BorderRadius.circular(6),
        color: Colors.green.shade50,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Column (${column.childrenCount} 项)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Column(
              children: List.generate(column.childrenCount, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      top: index > 0 ? 2 : 0,
                      bottom: index < column.childrenCount - 1 ? 2 : 0,
                    ),
                    child: _buildAreaWidget(column.childAt(index)),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsWidget(DockingTabs tabs) {
    return _buildClickableArea(
      tabs,
      Container(
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.purple.shade300, width: 2),
          borderRadius: BorderRadius.circular(6),
          color:
              selectedArea == tabs
                  ? Colors.purple.shade100
                  : Colors.purple.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tab, color: Colors.purple.shade600, size: 24),
            const SizedBox(height: 4),
            Text(
              'Tabs',
              style: TextStyle(
                fontSize: 14,
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${tabs.childrenCount} 标签页',
              style: TextStyle(fontSize: 12, color: Colors.purple.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemWidget(DockingItem item) {
    return _buildClickableArea(
      item,
      Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 80),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange.shade300, width: 2),
          borderRadius: BorderRadius.circular(6),
          color:
              selectedArea == item
                  ? Colors.orange.shade100
                  : Colors.orange.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, color: Colors.orange.shade600, size: 24),
            const SizedBox(height: 4),
            Text(
              item.name ?? 'Item',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableArea(DockingArea area, Widget child) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (area is DropArea) {
            setState(() {
              selectedArea = selectedArea == area ? null : area;
            });
          }
        },
        child: Stack(
          children: [
            child,
            if (selectedArea == area) _buildInsertButtons(area),
          ],
        ),
      ),
    );
  }

  Widget _buildInsertButtons(DockingArea area) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            // 上方按钮
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: _buildDirectionButton(
                  Icons.keyboard_arrow_up,
                  '上方',
                  () => _selectPosition(area, DropPosition.top, null),
                ),
              ),
            ),
            // 下方按钮
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: _buildDirectionButton(
                  Icons.keyboard_arrow_down,
                  '下方',
                  () => _selectPosition(area, DropPosition.bottom, null),
                ),
              ),
            ),
            // 左侧按钮
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildDirectionButton(
                  Icons.keyboard_arrow_left,
                  '左侧',
                  () => _selectPosition(area, DropPosition.left, null),
                ),
              ),
            ),
            // 右侧按钮
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildDirectionButton(
                  Icons.keyboard_arrow_right,
                  '右侧',
                  () => _selectPosition(area, DropPosition.right, null),
                ),
              ),
            ),
            // 如果是 Tabs，添加内部插入按钮
            if (area is DockingTabs)
              Positioned.fill(
                child: Center(
                  child: _buildDirectionButton(
                    Icons.add,
                    '添加标签',
                    () => _selectPosition(area, null, area.childrenCount),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionButton(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 24),
        ),
      ),
    );
  }

  void _selectPosition(
    DockingArea targetArea,
    DropPosition? dropPosition,
    int? dropIndex,
  ) {
    if (targetArea is! DropArea) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('所选区域不支持插入操作')));
      return;
    }

    Navigator.of(context).pop(
      InsertLocationResult(
        targetArea: targetArea,
        dropPosition: dropPosition,
        dropIndex: dropIndex,
      ),
    );
  }
}

/// 显示插入位置选择对话框
Future<InsertLocationResult?> showInsertLocationDialog(
  BuildContext context,
  DockingLayout layout,
) {
  return showDialog<InsertLocationResult>(
    context: context,
    builder: (context) => InsertLocationDialog(layout: layout),
  );
}
