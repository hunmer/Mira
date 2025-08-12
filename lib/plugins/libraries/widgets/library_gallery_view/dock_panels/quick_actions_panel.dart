import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import '../library_gallery_events.dart';

/// 快速操作面板组件
class QuickActionsPanel extends StatelessWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final LibraryGalleryEvents events;
  final BuildContext parentContext;

  const QuickActionsPanel({
    super.key,
    required this.plugin,
    required this.library,
    required this.events,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Tooltip(
            message: '显示/隐藏侧边栏',
            child: IconButton(
              icon: Icon(Icons.menu),
              onPressed: events.toggleSidebar,
            ),
          ),
          Tooltip(
            message: '文件夹列表',
            child: IconButton(
              icon: Icon(Icons.folder),
              onPressed: () async {
                final result = await plugin.libraryUIController
                    .showFolderSelector(library, parentContext);
                if (result != null && result.isNotEmpty) {
                  // 处理文件夹选择结果
                }
              },
            ),
          ),
          Tooltip(
            message: '标签列表',
            child: IconButton(
              icon: Icon(Icons.label),
              onPressed: () async {
                final result = await plugin.libraryUIController.showTagSelector(
                  library,
                  parentContext,
                );
                if (result != null && result.isNotEmpty) {
                  // 处理标签选择结果
                }
              },
            ),
          ),
          Tooltip(
            message: '收藏',
            child: IconButton(icon: Icon(Icons.favorite), onPressed: () {}),
          ),
          Tooltip(
            message: '回收站',
            child: IconButton(icon: Icon(Icons.delete), onPressed: () {}),
          ),
        ],
      ),
    );
  }
}

/// 快速操作面板注册器
class QuickActionsPanelRegistrar {
  static const String type = 'library_quick_actions';

  static void register(dynamic manager) {
    manager.registry.register(
      type,
      builder: (values) {
        final plugin = values['plugin'] as LibrariesPlugin;
        final library = Library.fromMap(
          values['library'] as Map<String, dynamic>,
        );
        final events = values['events'] as LibraryGalleryEvents;
        final parentContext = values['parentContext'] as BuildContext;

        return QuickActionsPanel(
          plugin: plugin,
          library: library,
          events: events,
          parentContext: parentContext,
        );
      },
    );
  }
}
