import 'package:flutter/material.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/widgets/library_sidebar_view.dart';

/// 侧边栏面板组件
class SidebarPanel extends StatelessWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final String tabId;
  final ValueNotifier<List<LibraryTag>> tags;
  final ValueNotifier<List<LibraryFolder>> folders;
  final ValueNotifier<Map<String, dynamic>> filterOptionsNotifier;

  const SidebarPanel({
    super.key,
    required this.plugin,
    required this.library,
    required this.tabId,
    required this.tags,
    required this.folders,
    required this.filterOptionsNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      valueListenables: [tags, folders, filterOptionsNotifier],
      builder: (context, values, _) {
        final tagsList = values[0] as List<LibraryTag>;
        final foldersList = values[1] as List<LibraryFolder>;
        final filterOptions = values[2] as Map<String, dynamic>;

        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: LibrarySidebarView(
            plugin: plugin,
            library: library,
            tabId: tabId,
            tags: tagsList,
            tagsSelected: List<String>.from(filterOptions['tags'] ?? []),
            folders: foldersList,
            folderSelected:
                filterOptions['folder'] is String
                    ? [filterOptions['folder']]
                    : [],
          ),
        );
      },
    );
  }
}

/// 侧边栏面板注册器
class SidebarPanelRegistrar {
  static const String type = 'library_sidebar';

  static void register(dynamic manager) {
    manager.registry.register(
      type,
      builder: (values) {
        final plugin = values['plugin'] as LibrariesPlugin;
        final library = Library.fromMap(
          values['library'] as Map<String, dynamic>,
        );
        final tabId = values['tabId'] as String;
        final tags = values['tags'] as ValueNotifier<List<LibraryTag>>;
        final folders = values['folders'] as ValueNotifier<List<LibraryFolder>>;
        final filterOptionsNotifier =
            values['filterOptionsNotifier']
                as ValueNotifier<Map<String, dynamic>>;

        return SidebarPanel(
          plugin: plugin,
          library: library,
          tabId: tabId,
          tags: tags,
          folders: folders,
          filterOptionsNotifier: filterOptionsNotifier,
        );
      },
    );
  }
}
