/// 展示如何使用新的 DockLayoutController 的示例
///
/// DockLayoutController 统一管理了所有布局相关的操作，使得布局逻辑更加清晰和集中：
///
/// 主要功能：
/// 1. 布局的保存和加载
/// 2. 预设管理
/// 3. 布局状态监控
/// 4. 异步布局操作
///
/// 使用方式：

import 'package:flutter/material.dart';
import 'dock_controller.dart';
import 'dock_layout_controller.dart';

class DockLayoutControllerUsageExample {
  /// 基本用法示例
  static void basicUsageExample() {
    // 1. 创建 DockController（内置 DockLayoutController）
    final dockController = DockController(dockTabsId: 'main');

    // 2. 访问布局控制器
    final layoutController = dockController.layoutController;

    // 3. 监听布局状态变化
    layoutController.addListener(() {
      print('Layout state changed:');
      print(
        '  - Has valid saved layout: ${layoutController.hasValidSavedLayout}',
      );
      print('  - Is loading: ${layoutController.isLayoutLoading}');
      print(
        '  - Last saved layout length: ${layoutController.lastSavedLayout.length}',
      );
    });

    // 4. 初始化Dock系统
    dockController.initializeDockSystem(savedLayoutId: 'main_layout');
  }

  /// 布局保存和加载示例
  static void layoutSaveLoadExample(DockLayoutController layoutController) {
    // 保存当前布局
    final saveSuccess = layoutController.saveLayout();
    print('Layout saved: $saveSuccess');

    // 加载布局
    final loadSuccess = layoutController.loadLayout();
    print('Layout loaded: $loadSuccess');

    // 从字符串加载布局
    final customLayoutData = '{"layout": "custom"}';
    final loadFromStringSuccess = layoutController.loadLayoutFromString(
      customLayoutData,
    );
    print('Layout loaded from string: $loadFromStringSuccess');

    // 重置为默认布局
    final resetSuccess = layoutController.resetToDefaultLayout();
    print('Layout reset: $resetSuccess');
  }

  /// 预设管理示例
  static Future<void> presetManagementExample(
    DockLayoutController layoutController,
  ) async {
    // 保存当前布局为预设
    final savePresetSuccess = await layoutController.saveLayoutAsPreset(
      presetName: 'My Custom Layout',
      description: 'A custom layout for development',
      setAsDefault: true,
    );
    print('Preset saved: $savePresetSuccess');

    // 获取所有可用预设
    final presets = await layoutController.getAvailablePresets();
    print('Available presets: ${presets.length}');
    for (final preset in presets) {
      print('  - ${preset.name} (${preset.id})');
    }

    // 从预设加载布局
    if (presets.isNotEmpty) {
      final loadPresetSuccess = await layoutController.loadLayoutFromPreset(
        presets.first.id,
      );
      print('Loaded from preset: $loadPresetSuccess');
    }

    // 删除预设
    if (presets.length > 1) {
      final deleteSuccess = await layoutController.deletePreset(
        presets.last.id,
      );
      print('Preset deleted: $deleteSuccess');
    }
  }

  /// 布局状态监控示例
  static void layoutMonitoringExample(DockLayoutController layoutController) {
    // 获取布局统计信息
    final stats = layoutController.getLayoutStats();
    print('Layout Statistics:');
    stats.forEach((key, value) {
      print('  $key: $value');
    });

    // 检查布局状态
    if (layoutController.isLayoutLoading) {
      print('Layout is currently loading...');
    }

    if (layoutController.hasValidSavedLayout) {
      print(
        'Has valid saved layout: ${layoutController.lastSavedLayout.length} characters',
      );
    }

    if (layoutController.pendingLayoutData != null) {
      print(
        'Has pending layout data: ${layoutController.pendingLayoutData!.length} characters',
      );
    }
  }

  /// Widget 集成示例
  static Widget buildLayoutControlWidget(DockController dockController) {
    return StatefulBuilder(
      builder: (context, setState) {
        final layoutController = dockController.layoutController;

        return Column(
          children: [
            // 布局状态显示
            ListenableBuilder(
              listenable: layoutController,
              builder: (context, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Layout Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Has Saved Layout: ${layoutController.hasValidSavedLayout}',
                        ),
                        Text('Is Loading: ${layoutController.isLayoutLoading}'),
                        Text(
                          'Layout Size: ${layoutController.lastSavedLayout.length} chars',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 布局操作按钮
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Layout Operations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            layoutController.saveLayout();
                          },
                          child: const Text('Save Layout'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            layoutController.loadLayout();
                          },
                          child: const Text('Load Layout'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            layoutController.resetToDefaultLayout();
                          },
                          child: const Text('Reset Layout'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await layoutController.saveLayoutAsPreset(
                              presetName:
                                  'Preset ${DateTime.now().millisecondsSinceEpoch}',
                            );
                          },
                          child: const Text('Save as Preset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Dock Widget
            Expanded(
              child:
                  dockController.dockTabs?.buildDockingWidget(context) ??
                  const Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      },
    );
  }
}

/// DockLayoutController 的优势：
/// 
/// 1. **职责分离**: 布局逻辑从 DockController 和 DockTabs 中分离出来
/// 2. **统一接口**: 所有布局操作都通过一个统一的接口进行
/// 3. **状态管理**: 提供完整的布局状态监控和通知
/// 4. **异步支持**: 支持异步布局操作，避免阻塞UI
/// 5. **预设管理**: 集成的布局预设管理功能
/// 6. **错误处理**: 统一的错误处理和日志记录
/// 7. **扩展性**: 易于添加新的布局功能
/// 
/// 使用 DockLayoutController 后的架构：
/// 
/// ```
/// DockController
/// ├── DockLayoutController (布局管理)
/// │   ├── 布局保存/加载
/// │   ├── 预设管理
/// │   ├── 状态监控
/// │   └── 异步操作
/// ├── DockTabs (UI组件管理)
/// │   ├── Tab管理
/// │   ├── Item管理
/// │   └── UI渲染
/// └── DockEventStreamController (事件管理)
///     ├── 事件发送
///     ├── 事件监听
///     └── 事件处理
/// ```
