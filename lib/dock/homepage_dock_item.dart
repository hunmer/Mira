import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'dock_item.dart';
import 'dock_manager.dart';

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
                  Card(
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
      case '':
        break;
      default:
        return;
    }

    // 添加到当前的DockTabs中
    if (newItem != null) _addToCurrentTab(newItem);
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
