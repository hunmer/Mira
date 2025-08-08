import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';
import '../dock_manager.dart';

/// 添加组件对话框
class AddComponentDialog extends StatefulWidget {
  final DockManager manager;
  final Function(String message) onShowSnackBar;

  const AddComponentDialog({
    Key? key,
    required this.manager,
    required this.onShowSnackBar,
  }) : super(key: key);

  @override
  State<AddComponentDialog> createState() => _AddComponentDialogState();
}

class _AddComponentDialogState extends State<AddComponentDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 650,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('添加组件', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Expanded(
              child: AddComponentDialogContent(
                manager: widget.manager,
                onShowSnackBar: widget.onShowSnackBar,
              ),
            ),
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

/// 添加组件对话框内容组件（可在标签页中重用）
class AddComponentDialogContent extends StatefulWidget {
  final DockManager manager;
  final Function(String message) onShowSnackBar;

  const AddComponentDialogContent({
    Key? key,
    required this.manager,
    required this.onShowSnackBar,
  }) : super(key: key);

  @override
  State<AddComponentDialogContent> createState() =>
      _AddComponentDialogContentState();
}

class _AddComponentDialogContentState extends State<AddComponentDialogContent> {
  DockingArea? _selectedArea;
  DropPosition? _selectedPosition;
  String _selectedComponentType = '';
  int? _selectedDropIndex;

  @override
  void initState() {
    super.initState();
    // 初始化选择第一个已注册的组件类型
    final registeredTypes = widget.manager.registry.registeredTypes;
    if (registeredTypes.isNotEmpty) {
      _selectedComponentType = registeredTypes.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAreas = widget.manager.layout.layoutAreas();
    final dropAreas = allAreas.where((area) => area is DropArea).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 组件类型选择
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('选择组件类型', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                // 动态显示已注册的组件类型
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      widget.manager.registry.registeredTypes.map((type) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: type,
                              groupValue: _selectedComponentType,
                              onChanged: (value) {
                                setState(() => _selectedComponentType = value!);
                              },
                            ),
                            Text(_getComponentDisplayName(type)),
                          ],
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 目标区域选择和插入位置选择并排显示
        Expanded(
          flex: 3,
          child: Row(
            children: [
              // 左侧：目标区域选择
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '选择目标区域',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: dropAreas.length,
                            itemBuilder: (context, index) {
                              final area = dropAreas[index];
                              final isSelected = _selectedArea == area;
                              return ListTile(
                                selected: isSelected,
                                leading: Icon(_getAreaIcon(area)),
                                title: Text(_getAreaDisplayName(area)),
                                subtitle: Text(_getAreaDescription(area)),
                                trailing:
                                    (area is DockingItem && area.maximized) ||
                                            (area is DockingTabs &&
                                                area.maximized)
                                        ? const Icon(Icons.fullscreen, size: 16)
                                        : null,
                                onTap: () {
                                  setState(() {
                                    _selectedArea = area;
                                    _selectedPosition = null;
                                    _selectedDropIndex = null;
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
              ),

              const SizedBox(width: 8),

              // 右侧：插入位置选择
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '选择插入位置',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: _buildPositionSelector()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 操作按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _canAdd() ? _addComponent : null,
              child: const Text('添加'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPositionSelector() {
    if (_selectedArea == null) {
      return const Center(
        child: Text('请先选择目标区域', style: TextStyle(color: Colors.grey)),
      );
    }

    final area = _selectedArea!;

    if (area is DockingTabs) {
      return _buildTabsPositionSelector(area);
    } else if (area is DockingRow || area is DockingColumn) {
      return _buildLayoutPositionSelector(area);
    } else {
      return _buildGeneralPositionSelector();
    }
  }

  Widget _buildTabsPositionSelector(DockingTabs tabs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('在标签组中的位置：'),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              // 标签页插入位置
              for (int i = 0; i <= tabs.childrenCount; i++) ...[
                RadioListTile<int>(
                  value: i,
                  groupValue: _selectedDropIndex,
                  onChanged: (value) {
                    setState(() {
                      _selectedDropIndex = value;
                      _selectedPosition = null;
                    });
                  },
                  title: Text(
                    i == 0
                        ? '第一个位置'
                        : i == tabs.childrenCount
                        ? '最后位置'
                        : '第 ${i + 1} 个位置',
                  ),
                  subtitle:
                      i < tabs.childrenCount
                          ? Text('在 "${tabs.childAt(i).name}" 之前')
                          : i == tabs.childrenCount && tabs.childrenCount > 0
                          ? Text('在 "${tabs.childAt(i - 1).name}" 之后')
                          : null,
                ),
              ],
              const Divider(),
              const Text('或者相对于整个标签组：'),
              ...DropPosition.values.map(
                (position) => RadioListTile<DropPosition>(
                  value: position,
                  groupValue: _selectedPosition,
                  onChanged: (value) {
                    setState(() {
                      _selectedPosition = value;
                      _selectedDropIndex = null;
                    });
                  },
                  title: Text(_getPositionName(position)),
                  subtitle: Text(_getPositionDescription(position)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutPositionSelector(DockingArea area) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('在 ${area is DockingRow ? '行' : '列'} 布局中的位置：'),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              // 子项插入位置
              if (area is DockingTabs) ...[
                for (int i = 0; i <= area.childrenCount; i++) ...[
                  RadioListTile<int>(
                    value: i,
                    groupValue: _selectedDropIndex,
                    onChanged: (value) {
                      setState(() {
                        _selectedDropIndex = value;
                        _selectedPosition = null;
                      });
                    },
                    title: Text(
                      i == 0
                          ? '第一个位置'
                          : i == area.childrenCount
                          ? '最后位置'
                          : '第 ${i + 1} 个位置',
                    ),
                    subtitle:
                        i < area.childrenCount
                            ? Text(
                              '在 "${_getChildDisplayName(area.childAt(i))}" 之前',
                            )
                            : i == area.childrenCount && area.childrenCount > 0
                            ? Text(
                              '在 "${_getChildDisplayName(area.childAt(i - 1))}" 之后',
                            )
                            : null,
                  ),
                ],
              ] else if (area is DockingRow) ...[
                for (int i = 0; i <= area.childrenCount; i++) ...[
                  RadioListTile<int>(
                    value: i,
                    groupValue: _selectedDropIndex,
                    onChanged: (value) {
                      setState(() {
                        _selectedDropIndex = value;
                        _selectedPosition = null;
                      });
                    },
                    title: Text(
                      i == 0
                          ? '第一个位置'
                          : i == area.childrenCount
                          ? '最后位置'
                          : '第 ${i + 1} 个位置',
                    ),
                    subtitle:
                        i < area.childrenCount
                            ? Text(
                              '在 "${_getChildDisplayName(area.childAt(i))}" 之前',
                            )
                            : i == area.childrenCount && area.childrenCount > 0
                            ? Text(
                              '在 "${_getChildDisplayName(area.childAt(i - 1))}" 之后',
                            )
                            : null,
                  ),
                ],
              ] else if (area is DockingColumn) ...[
                for (int i = 0; i <= area.childrenCount; i++) ...[
                  RadioListTile<int>(
                    value: i,
                    groupValue: _selectedDropIndex,
                    onChanged: (value) {
                      setState(() {
                        _selectedDropIndex = value;
                        _selectedPosition = null;
                      });
                    },
                    title: Text(
                      i == 0
                          ? '第一个位置'
                          : i == area.childrenCount
                          ? '最后位置'
                          : '第 ${i + 1} 个位置',
                    ),
                    subtitle:
                        i < area.childrenCount
                            ? Text(
                              '在 "${_getChildDisplayName(area.childAt(i))}" 之前',
                            )
                            : i == area.childrenCount && area.childrenCount > 0
                            ? Text(
                              '在 "${_getChildDisplayName(area.childAt(i - 1))}" 之后',
                            )
                            : null,
                  ),
                ],
              ],
              ...DropPosition.values.map(
                (position) => RadioListTile<DropPosition>(
                  value: position,
                  groupValue: _selectedPosition,
                  onChanged: (value) {
                    setState(() {
                      _selectedPosition = value;
                      _selectedDropIndex = null;
                    });
                  },
                  title: Text(_getPositionName(position)),
                  subtitle: Text(_getPositionDescription(position)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralPositionSelector() {
    return ListView(
      children:
          DropPosition.values
              .map(
                (position) => RadioListTile<DropPosition>(
                  value: position,
                  groupValue: _selectedPosition,
                  onChanged: (value) {
                    setState(() {
                      _selectedPosition = value;
                      _selectedDropIndex = null;
                    });
                  },
                  title: Text(_getPositionName(position)),
                  subtitle: Text(_getPositionDescription(position)),
                ),
              )
              .toList(),
    );
  }

  bool _canAdd() {
    return _selectedArea != null &&
        (_selectedPosition != null || _selectedDropIndex != null);
  }

  void _addComponent() {
    if (!_canAdd()) return;

    // 检查是否有配置对话框
    final configDialog = widget.manager.registry.buildConfigDialog(
      _selectedComponentType,
      context,
      (values) {
        Navigator.of(context).pop(); // 关闭配置对话框
        _addComponentWithValues(values);
      },
    );

    if (configDialog != null) {
      // 显示配置对话框
      showDialog(context: context, builder: (context) => configDialog);
    } else {
      // 没有配置对话框，使用默认值
      _addComponentWithValues(
        _getComponentValues(DateTime.now().millisecondsSinceEpoch.toString()),
      );
    }
  }

  void _addComponentWithValues(Map<String, dynamic> values) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final area = _selectedArea!;

    try {
      if (_selectedDropIndex != null) {
        // 使用索引插入
        widget.manager.addTypedItem(
          id: '${_selectedComponentType}_$timestamp',
          type: _selectedComponentType,
          values: {...values, 'id': '${_selectedComponentType}_$timestamp'},
          targetArea: area as DropArea,
          dropIndex: _selectedDropIndex!,
          name: values['name'] ?? _getComponentName(timestamp),
          keepAlive: true,
        );
      } else if (_selectedPosition != null) {
        // 使用位置插入
        widget.manager.addTypedItem(
          id: '${_selectedComponentType}_$timestamp',
          type: _selectedComponentType,
          values: {...values, 'id': '${_selectedComponentType}_$timestamp'},
          targetArea: area as DropArea,
          dropPosition: _selectedPosition!,
          name: values['name'] ?? _getComponentName(timestamp),
          keepAlive: true,
        );
      }

      Navigator.of(context).pop();
      widget.onShowSnackBar(
        '已添加${_selectedComponentType == 'counter' ? '计数器' : '文本'}组件到 ${_getAreaDisplayName(area)}',
      );
    } catch (e) {
      widget.onShowSnackBar('添加失败: $e');
    }
  }

  Map<String, dynamic> _getComponentValues(String timestamp) {
    switch (_selectedComponentType) {
      case 'counter':
        return {'count': 0, 'id': 'counter_$timestamp'};
      case 'text':
        return {'text': 'Created at ${DateTime.now()}'};
      default:
        return {};
    }
  }

  String _getComponentName(String timestamp) {
    switch (_selectedComponentType) {
      case 'counter':
        return 'Counter ${DateTime.now().millisecond}';
      case 'text':
        return 'Text ${DateTime.now().millisecond}';
      default:
        return 'Component $timestamp';
    }
  }

  IconData _getAreaIcon(DockingArea area) {
    if (area is DockingTabs) return Icons.tab;
    if (area is DockingRow) return Icons.view_column;
    if (area is DockingColumn) return Icons.view_agenda;
    if (area is DockingItem) return Icons.article;
    return Icons.rectangle;
  }

  // ========= 辅助方法 =========

  String _getComponentDisplayName(String type) {
    switch (type) {
      case 'counter':
        return '计数器';
      case 'text':
        return '文本组件';
      case 'dynamic_widget':
        return 'Dynamic Widget';
      default:
        return type.toUpperCase();
    }
  }

  String _getAreaDisplayName(DockingArea area) {
    if (area is DockingTabs) {
      return '标签组 ${area.id ?? '未命名'}';
    }
    if (area is DockingRow) {
      return '行布局 ${area.id ?? '未命名'}';
    }
    if (area is DockingColumn) {
      return '列布局 ${area.id ?? '未命名'}';
    }
    if (area is DockingItem) {
      return '标签页 ${area.name ?? area.id ?? '未命名'}';
    }
    return '区域 ${area.id ?? '未命名'}';
  }

  String _getAreaDescription(DockingArea area) {
    final path = area.path;
    if (area is DockingTabs) {
      return '子项数: ${area.childrenCount} | 路径: $path';
    }
    if (area is DockingRow) {
      return '子项数: ${area.childrenCount} | 路径: $path';
    }
    if (area is DockingColumn) {
      return '子项数: ${area.childrenCount} | 路径: $path';
    }
    return '路径: $path';
  }

  String _getChildDisplayName(DockingArea child) {
    if (child is DockingItem) return child.name ?? child.id ?? '未命名';
    return _getAreaDisplayName(child);
  }

  String _getPositionName(DropPosition position) {
    switch (position) {
      case DropPosition.left:
        return '左侧';
      case DropPosition.right:
        return '右侧';
      case DropPosition.top:
        return '上方';
      case DropPosition.bottom:
        return '下方';
    }
  }

  String _getPositionDescription(DropPosition position) {
    switch (position) {
      case DropPosition.left:
        return '在目标区域左侧创建新区域';
      case DropPosition.right:
        return '在目标区域右侧创建新区域';
      case DropPosition.top:
        return '在目标区域上方创建新区域';
      case DropPosition.bottom:
        return '在目标区域下方创建新区域';
    }
  }
}
