import 'package:flutter/material.dart';
import 'dock_manager.dart';

/// DemoData - 包含示例数据和演示功能的类
class DemoData {
  /// 创建示例文本DockItem的列表
  static List<Map<String, dynamic>> getTextItemExamples() {
    return [
      {
        'title': 'Welcome Text',
        'content':
            'Welcome to the Docking System!\n\nThis is a powerful layout management system for Flutter applications.',
      },
      {
        'title': 'Features',
        'content': '''Key Features:
• Draggable panels
• Resizable layouts
• Tabbed interfaces
• Context menus
• Layout persistence
• Custom themes''',
      },
      {
        'title': 'Quick Start',
        'content': '''Getting Started:
1. Add new panels using the "+" button
2. Drag panels to rearrange layout
3. Right-click for context menu options
4. Save/load layouts with toolbar buttons
5. Customize themes as needed''',
      },
    ];
  }

  /// 创建示例计数器DockItem的列表
  static List<Map<String, dynamic>> getCounterItemExamples() {
    return [
      {'title': 'Downloads', 'initialCount': 150},
      {'title': 'Active Users', 'initialCount': 42},
      {'title': 'Tasks Completed', 'initialCount': 0},
    ];
  }

  /// 创建示例列表DockItem的列表
  static List<Map<String, dynamic>> getListItemExamples() {
    return [
      {
        'title': 'Todo List',
        'initialItems': [
          'Review code changes',
          'Update documentation',
          'Test new features',
          'Deploy to staging',
        ],
      },
      {
        'title': 'Shopping List',
        'initialItems': ['Milk', 'Bread', 'Eggs', 'Coffee'],
      },
      {
        'title': 'Project Files',
        'initialItems': [
          'main.dart',
          'dock_manager.dart',
          'dock_controller.dart',
          'demo_data.dart',
        ],
      },
    ];
  }

  /// 创建工作区示例数据
  static void populateWorkspace() {
    final textExamples = getTextItemExamples();
    final counterExamples = getCounterItemExamples();

    // 添加文本示例
    for (var example in textExamples) {
      final item = DockManager.createTextDockItem(
        example['title'],
        content: example['content'],
      );
      DockManager.addDockItem('main', 'workspace', item);
    }

    // 添加计数器示例
    for (var example in counterExamples) {
      final item = DockManager.createCounterDockItem(
        example['title'],
        initialCount: example['initialCount'],
      );
      DockManager.addDockItem('main', 'workspace', item);
    }
  }

  /// 创建工具区示例数据
  static void populateTools() {
    final listExamples = getListItemExamples();

    // 添加列表示例
    for (var example in listExamples) {
      final item = DockManager.createListDockItem(
        example['title'],
        initialItems: List<String>.from(example['initialItems']),
      );
      DockManager.addDockItem('main', 'tools', item);
    }
  }

  /// 创建完整的演示环境
  static void createDemoEnvironment() {
    // 创建演示tabs
    DockManager.createDockTab(
      'main',
      'demo_workspace',
      displayName: '演示工作区',
      closable: true,
      maximizable: false,
      buttons: [],
    );

    DockManager.createDockTab(
      'main',
      'demo_tools',
      displayName: '演示工具',
      closable: true,
      maximizable: false,
      buttons: [],
    );

    // 填充演示数据
    populateWorkspace();
    populateTools();
  }

  /// 获取预定义的主题配置
  static Map<String, dynamic> getThemeConfigurations() {
    return {
      'light': {
        'name': 'Light Theme',
        'primaryColor': Colors.blue,
        'backgroundColor': Colors.white,
        'textColor': Colors.black87,
      },
      'dark': {
        'name': 'Dark Theme',
        'primaryColor': Colors.blueGrey,
        'backgroundColor': Colors.grey[900],
        'textColor': Colors.white,
      },
      'ocean': {
        'name': 'Ocean Theme',
        'primaryColor': Colors.teal,
        'backgroundColor': Colors.cyan[50],
        'textColor': Colors.teal[800],
      },
      'sunset': {
        'name': 'Sunset Theme',
        'primaryColor': Colors.orange,
        'backgroundColor': Colors.orange[50],
        'textColor': Colors.orange[800],
      },
    };
  }

  /// 获取示例布局配置
  static Map<String, String> getSampleLayouts() {
    return {
      'default': 'Default Layout - Standard three-tab setup',
      'workspace_focused':
          'Workspace Focused - Large workspace with minimal tools',
      'tools_heavy': 'Tools Heavy - Multiple tool panels with small workspace',
      'minimal': 'Minimal - Single tab with essential items only',
    };
  }

  /// 创建快速启动项目列表
  static List<Map<String, dynamic>> getQuickStartItems() {
    return [
      {
        'title': 'Create Text Editor',
        'description': 'Add a new text editing panel',
        'icon': Icons.edit,
        'action': 'create_text',
      },
      {
        'title': 'Add Counter',
        'description': 'Insert a counter widget',
        'icon': Icons.add_circle,
        'action': 'create_counter',
      },
      {
        'title': 'New List',
        'description': 'Create a new list manager',
        'icon': Icons.list,
        'action': 'create_list',
      },
      {
        'title': 'Load Demo',
        'description': 'Load demonstration layout',
        'icon': Icons.dashboard,
        'action': 'load_demo',
      },
    ];
  }

  /// 获取帮助文档内容
  static Map<String, String> getHelpContent() {
    return {
      'overview': '''
Docking System Overview

This is a comprehensive docking and layout management system for Flutter applications. 
It provides a flexible way to create, manage, and persist complex UI layouts.
''',
      'features': '''
Key Features

• Draggable Panels: Move panels around the interface
• Resizable Layouts: Adjust panel sizes as needed
• Tabbed Interface: Organize content in tabs
• Context Menus: Right-click for additional options
• Layout Persistence: Save and restore layouts
• Custom Themes: Customize appearance
• Multiple Content Types: Text, counters, lists, and more
''',
      'shortcuts': '''
Keyboard Shortcuts

Ctrl+S: Save current layout
Ctrl+O: Load saved layout
Ctrl+N: Create new tab
Ctrl+W: Close current tab
F11: Toggle fullscreen
''',
      'tips': '''
Tips and Tricks

• Drag tabs to reorder them
• Right-click on tabs for context menu
• Use the toolbar buttons for quick actions
• Save layouts before making major changes
• Experiment with different themes
• Use the statistics view to monitor usage
''',
    };
  }
}
