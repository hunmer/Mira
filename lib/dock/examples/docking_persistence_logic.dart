import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/docking/lib/src/layout/drop_position.dart';
import 'package:mira/dock/examples/registerdWidgets/dynamic_widget.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'dock_manager.dart';
import 'dialog/add_component_dialog.dart';
import 'dialog/multi_tab_dialog.dart';

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
    final widget = DynamicWidget(
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

    manager.setRoot(
      DockingTabs([
        DockingItem(
          id: 'default_item',
          name: 'Default Item',
          widget: widget,
          closable: true,
          maximizable: false,
          keepAlive: false,
        ),
      ]),
    );
  }

  void createTest() {
    final widget1 = DockingLayout(
      root: DockingRow([
        DockingItem(
          id: 'item1_left',
          name: 'Item left',
          parentId: 'row1',
          showAtDevices: [DeviceScreenType.tablet],
          visibilityMode: DeviceVisibilityMode.specifiedAndLarger,
          widget: Container(color: Colors.cyan),
        ),
        DockingItem(
          id: 'item1_1',
          name: 'Item 1-1',
          parentId: 'row1',
          widget: Container(color: Colors.red),
        ),
        DockingItem(
          id: 'item1_2',
          name: 'Item 1-2',
          parentId: 'row1',
          widget: Container(color: Colors.blue),
        ),
        DockingItem(
          id: 'item1_right',
          name: 'Item right',
          parentId: 'row1',
          showAtDevices: [DeviceScreenType.tablet],
          visibilityMode: DeviceVisibilityMode.specifiedAndLarger,
          widget: Container(color: Colors.green),
        ),
      ], id: 'root'),
    );

    final widget2 = DockingLayout(
      root: DockingRow([
        DockingItem(
          id: 'item2_left',
          name: 'Item 2 left',
          parentId: 'row2',
          showAtDevices: [DeviceScreenType.tablet],
          visibilityMode: DeviceVisibilityMode.specifiedAndLarger,
          widget: Container(color: Colors.purple),
        ),
        DockingItem(
          id: 'item2_1',
          name: 'Item 2-1',
          parentId: 'row2',
          widget: Container(color: Colors.green),
        ),
        DockingItem(
          id: 'item2_2',
          name: 'Item 2-2',
          parentId: 'row2',
          widget: Container(color: Colors.yellow),
        ),
        DockingItem(
          id: 'item2_right',
          name: 'Item 2 right',
          parentId: 'row2',
          showAtDevices: [DeviceScreenType.tablet],
          visibilityMode: DeviceVisibilityMode.specifiedAndLarger,
          widget: Container(color: Colors.orange),
        ),
      ], id: 'nested2'),
    );

    final rootRow = DockingRow([
      DockingItem(
        id: 'row1',
        name: 'Row 1',
        widget: Docking(
          layout: widget1,
          breakpoints: const ScreenBreakpoints(
            desktop: 800,
            tablet: 600,
            watch: 200,
          ),
          autoBreakpoints: true,
        ),
      ),
      DockingItem(
        id: 'row2',
        name: 'Row 2',
        widget: Docking(
          layout: widget2,
          breakpoints: const ScreenBreakpoints(
            desktop: 800,
            tablet: 600,
            watch: 200,
          ),
          autoBreakpoints: true,
        ),
      ),
    ], id: 'root');
    manager.setRoot(rootRow);
  }
}
