import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'dock_item.dart';
import 'dock_manager.dart';
import 'context_menu_wrapper.dart';

/// HomePage DockItem - 默认的首页面板，包含新建tab功能
class HomePageDockItem extends DockItem {
  final VoidCallback? onCreateNewTab;

  HomePageDockItem({this.onCreateNewTab, String title = 'Home'})
    : super(
        type: 'homepage',
        title: title,
        values: {
          'welcomeText': ValueNotifier('Welcome to Dock System'),
          'registeredTypes': ValueNotifier(_getRegisteredTypes()),
        },
        builder:
            (dockItem) => DockingItem(
              name: dockItem.title,
              widget: _buildHomePageWidget(dockItem),
            ),
      );

  static Widget _buildHomePageWidget(DockItem dockItem) {
    return ValueListenableBuilder(
      valueListenable: dockItem.values['welcomeText']!,
      builder: (context, welcomeText, child) {
        return ValueListenableBuilder(
          valueListenable: dockItem.values['registeredTypes']!,
          builder: (context, registeredTypes, child) {
            final types = registeredTypes as List<DockItemType>;

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 欢迎信息
                  ContextMenuWrapper(
                    itemName: 'Welcome Card',
                    itemType: 'info',
                    onRename: () {
                      // 可以在这里实现重命名功能
                      print('Rename welcome message');
                    },
                    customActions: {
                      '编辑欢迎消息': () {
                        // 编辑欢迎消息的逻辑
                        print('Edit welcome message');
                      },
                      '重置为默认': () {
                        dockItem.update(
                          'welcomeText',
                          'Welcome to Dock System',
                        );
                      },
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              welcomeText.toString(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Select a panel type below to get started',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 新建Tab按钮
                  ContextMenuWrapper(
                    itemName: 'Panel Creator',
                    itemType: 'tool',
                    onDuplicate: () {
                      print('Duplicate panel creator');
                    },
                    customActions: {
                      '添加自定义面板类型': () {
                        print('Add custom panel type');
                      },
                      '批量创建面板': () {
                        print('Batch create panels');
                      },
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create New Panel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Choose a panel type to create:',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  types.map((type) {
                                    return ElevatedButton.icon(
                                      onPressed:
                                          () => _createNewTab(context, type),
                                      icon: Icon(type.icon),
                                      label: Text(type.name),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: type.color,
                                        foregroundColor: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void _createNewTab(BuildContext context, DockItemType type) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Create ${type.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Create a new ${type.name} panel?'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Panel Name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (name) {
                    Navigator.pop(context);
                    _createDockItem(type, name.isEmpty ? type.name : name);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (value) {
                        // 可以添加选项来替换当前的homepage
                      },
                    ),
                    const Expanded(child: Text('Replace current homepage')),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _createDockItem(type, type.name);
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  static void _createDockItem(DockItemType type, String name) {
    DockItem? newItem;

    switch (type.type) {
      case 'text':
        newItem = DockManager.createTextDockItem(
          name,
          content: 'New text content',
        );
        break;
      case 'counter':
        newItem = DockManager.createCounterDockItem(name);
        break;
      case 'list':
        newItem = DockManager.createListDockItem(name);
        break;
      case 'chart':
        newItem = _createChartDockItem(name);
        break;
      case 'editor':
        newItem = _createEditorDockItem(name);
        break;
      default:
        return;
    }

    // 添加到当前的DockTabs中
    _addToCurrentTab(newItem);
  }

  static DockItem _createChartDockItem(String name) {
    return DockItem(
      type: 'chart',
      title: name,
      values: {
        'data': ValueNotifier([10, 20, 15, 30, 25]),
        'chartType': ValueNotifier('bar'),
      },
      builder:
          (dockItem) => DockingItem(
            name: dockItem.title,
            widget: ValueListenableBuilder(
              valueListenable: dockItem.values['data']!,
              builder: (context, data, child) {
                final chartData = data as List<int>;
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children:
                              chartData.map((value) {
                                return Container(
                                  width: 30,
                                  height: value * 4.0,
                                  color: Colors.blue,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final newData = List<int>.generate(
                            5,
                            (index) =>
                                (index + 1) *
                                (10 + (DateTime.now().millisecond % 20)),
                          );
                          dockItem.update('data', newData);
                        },
                        child: const Text('Refresh Data'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }

  static DockItem _createEditorDockItem(String name) {
    return DockItem(
      type: 'editor',
      title: name,
      values: {
        'content': ValueNotifier(
          '// Welcome to the editor\nprint("Hello World");',
        ),
        'language': ValueNotifier('dart'),
      },
      builder:
          (dockItem) => DockingItem(
            name: dockItem.title,
            widget: ValueListenableBuilder(
              valueListenable: dockItem.values['content']!,
              builder: (context, content, child) {
                return Container(
                  color: Colors.grey[900],
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        color: Colors.grey[800],
                        child: Text(
                          '${dockItem.getValue<String>('language')} - $name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: TextEditingController(
                              text: content.toString(),
                            ),
                            maxLines: null,
                            expands: true,
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter your code here...',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            onChanged: (value) {
                              dockItem.update('content', value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }

  static void _addToCurrentTab(DockItem item) {
    // 获取当前可用的DockTabs和Tabs
    final allDockTabs = DockManager.getAllDockTabs();
    if (allDockTabs.isEmpty) return;

    // 默认添加到'main' DockTabs的'workspace' tab
    final mainDockTabs = allDockTabs['main'];
    if (mainDockTabs != null) {
      final tabs = mainDockTabs.getAllDockTabs();
      if (tabs.containsKey('workspace')) {
        DockManager.addDockItem('main', 'workspace', item);
      } else if (tabs.isNotEmpty) {
        // 如果没有workspace tab，添加到第一个可用的tab
        final firstTabId = tabs.keys.first;
        DockManager.addDockItem('main', firstTabId, item);
      }
    }
  }

  static List<DockItemType> _getRegisteredTypes() {
    return [
      DockItemType(
        type: 'text',
        name: 'Text Panel',
        description: 'Display and edit text content',
        icon: Icons.text_fields,
        color: Colors.blue,
      ),
      DockItemType(
        type: 'counter',
        name: 'Counter Panel',
        description: 'Interactive counter with increment/decrement',
        icon: Icons.add_circle,
        color: Colors.green,
      ),
      DockItemType(
        type: 'list',
        name: 'List Panel',
        description: 'Manage list of items',
        icon: Icons.list,
        color: Colors.orange,
      ),
      DockItemType(
        type: 'chart',
        name: 'Chart Panel',
        description: 'Display data in chart format',
        icon: Icons.bar_chart,
        color: Colors.purple,
      ),
      DockItemType(
        type: 'editor',
        name: 'Code Editor',
        description: 'Code editor with syntax highlighting',
        icon: Icons.code,
        color: Colors.red,
      ),
    ];
  }
}

/// DockItem类型定义
class DockItemType {
  final String type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  DockItemType({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}
