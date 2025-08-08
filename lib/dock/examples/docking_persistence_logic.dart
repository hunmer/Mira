import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';
import 'dock_manager.dart';
import 'dialog/add_component_dialog.dart';
import 'dialog/multi_tab_dialog.dart';
import 'registerdWidgets/dynamic_widget.dart';

/// Docking 持久化演示的业务逻辑
class DockingPersistenceLogic {
  final DockManager manager;
  final BuildContext context;

  DockingPersistenceLogic({required this.manager, required this.context});

  /// 显示提示消息
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 显示多标签对话框
  void showMultiTabDialog({int initialTabIndex = 0}) {
    showDialog(
      context: context,
      builder:
          (context) => MultiTabDialog(
            manager: manager,
            onShowSnackBar: showSnackBar,
            initialTabIndex: initialTabIndex,
          ),
    );
  }

  /// 显示调试工具（多标签对话框的调试页面）
  void showDebugTab() {
    showMultiTabDialog(initialTabIndex: 0);
  }

  /// 显示添加组件工具（多标签对话框的添加组件页面）
  void showAddComponentTab() {
    showMultiTabDialog(initialTabIndex: 1);
  }

  /// 显示添加组件对话框
  void showAddComponentDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddComponentDialog(
            manager: manager,
            onShowSnackBar: showSnackBar,
          ),
    );
  }

  /// 添加计数器组件
  void addCounter() {
    final root = manager.layout.root;
    if (root is DropArea) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      manager.addTypedItem(
        id: 'counter_$timestamp',
        type: 'counter',
        values: {'count': 0, 'id': 'counter_$timestamp'},
        targetArea: root as DropArea,
        dropPosition: DropPosition.right,
        name: 'Counter ${DateTime.now().millisecond}',
        keepAlive: true,
      );
      showSnackBar('已添加计数器组件');
    } else {
      showSnackBar('无法添加：没有可用的放置区域');
    }
  }

  /// 添加文本组件
  void addText() {
    final root = manager.layout.root;
    if (root is DropArea) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      manager.addTypedItem(
        id: 'text_$timestamp',
        type: 'text',
        values: {'text': 'Text created at ${DateTime.now()}'},
        targetArea: root as DropArea,
        dropPosition: DropPosition.bottom,
        name: 'Text ${DateTime.now().millisecond}',
        keepAlive: true,
      );
      showSnackBar('已添加文本组件');
    } else {
      showSnackBar('无法添加：没有可用的放置区域');
    }
  }

  /// 添加通用文本组件（主添加按钮使用）
  void addGenericText() {
    final root = manager.layout.root;
    if (root is DropArea) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      manager.addTypedItem(
        id: 'text_$timestamp',
        type: 'text',
        values: {'text': 'Created at ${DateTime.now()}'},
        targetArea: root as DropArea,
        dropPosition: DropPosition.right,
        name: 'Text $timestamp',
      );
    }
  }

  /// 保存布局
  Future<void> saveLayout() async {
    await manager.saveToFile();
    showSnackBar('Layout saved');
  }

  /// 恢复布局
  Future<void> restoreLayout() async {
    final restored = await manager.restoreFromFile();
    showSnackBar(restored ? 'Layout restored' : 'No saved layout');
  }

  /// 清除布局
  Future<void> clearLayout() async {
    manager.setRoot(null);
    showSnackBar('Layout cleared');
  }

  /// 创建默认布局
  void createDefaultLayout() {
    // 直接构建 dynamic widget
    final welcomeWidget = DynamicWidget(
      jsonData: {
        "type": "scaffold",
        "args": {
          "appBar": {
            "type": "app_bar",
            "args": {
              "title": {
                "type": "text",
                "args": {"text": "Rich Text"},
              },
            },
          },
          "body": {
            "type": "center",
            "args": {
              "child": {
                "type": "rich_text",
                "args": {
                  "text": {
                    "children": [
                      {"text": "Hello "},
                      {
                        "style": {"fontSize": 20.0, "fontWeight": "bold"},
                        "text": "RICH TEXT",
                      },
                      {"text": " World!"},
                    ],
                    "style": {"color": "#000000", "fontSize": 12.0},
                  },
                },
              },
            },
          },
        },
      },
    );

    final rootTabs = DockingTabs([
      DockingItem(
        id: 'welcome',
        name: 'Dynamic Welcome',
        widget: welcomeWidget,
      ),
    ], id: 'root');

    manager.setRoot(rootTabs);

    // 添加一个计数器组件
    manager.addTypedItem(
      id: 'counter1',
      type: 'counter',
      values: {'count': 0, 'id': 'counter1'},
      targetArea: rootTabs,
      dropIndex: 1,
      name: 'Counter 1',
      keepAlive: true,
    );
  }
}
