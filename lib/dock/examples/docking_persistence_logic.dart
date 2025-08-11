import 'package:flutter/material.dart';
import 'package:mira/dock/docking/lib/src/docking.dart';
import 'package:mira/dock/docking/lib/src/layout/docking_layout.dart';
import 'package:mira/dock/examples/dock_insert_mode.dart';
import 'package:mira/plugins/libraries/widgets/library_dock_item.dart';
import 'package:mira/plugins/libraries/widgets/library_list_view.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:uuid/uuid.dart';
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

  /// 保存布局
  Future<void> saveLayout() async {
    await manager.saveToFile();
  }

  /// 恢复布局
  Future<void> restoreLayout() async {
    final restored = await manager.restoreFromFile();
  }

  /// 清除布局
  Future<void> clearLayout() async {
    manager.setRoot(null);
  }

  /// 创建默认布局
  void createDefaultLayout() {
    manager.setRoot(getDefaultLayout() as DockingArea);
  }

  DockingTabs getDefaultLayout() {
    return DockingTabs([
      DockingItem(
        id: 'home',
        name: '选择素材库',
        widget: LibraryListView(
          onSelected: (library) {
            LibraryDockItemRegistrar.addTab(
              library,
              tabId: Uuid().v4(),
              insertMode: DockInsertMode.auto,
              context: context,
            );
            manager.removeItemById('home');
          },
        ),
        closable: false,
        maximizable: false,
        keepAlive: false,
      ),
    ]);
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
