import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/widgets/folder_tree_widget.dart';
import 'package:mira/widgets/tree_view.dart';
import '../libraries_plugin.dart';
import '../models/library.dart';

class LibrarySidebarView extends StatelessWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final VoidCallback onHideSidebar;

  const LibrarySidebarView({
    super.key,
    required this.plugin,
    required this.library,
    required this.onHideSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.all_inbox),
            title: const Text('所有素材库'),
            onTap: () => Navigator.pushNamed(context, '/libraries'),
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('我的收藏'),
            onTap: onHideSidebar,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('回收站'),
            onTap: onHideSidebar,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('标签目录', style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: FutureBuilder<List<LibraryTag?>>(
              future:
                  plugin.foldersTagsController.getTagCache(library.id).getAll(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FolderTreeWidget(
                    items:
                        snapshot.data!
                            .map(
                              (tag) => TreeItem(id: tag!.id, title: tag.title),
                            )
                            .toList(),
                    library: library,
                    showSelectAll: false,
                    onSelectionChanged:
                        (ids) => plugin.tabManager.updateCurrentFitler({
                          'tags': ids,
                        }),
                    type: 'tags',
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '文件夹目录',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LibraryFolder?>>(
              future:
                  plugin.foldersTagsController
                      .getFolderCache(library.id)
                      .getAll(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return FolderTreeWidget(
                    items:
                        snapshot.data!
                            .map(
                              (folder) =>
                                  TreeItem(id: folder!.id, title: folder.title),
                            )
                            .toList(),
                    library: library,
                    showSelectAll: false,
                    onSelectionChanged: (ids) {
                      if (ids != null && ids.isNotEmpty) {
                        plugin.tabManager.updateCurrentFitler({
                          'folder': ids.first,
                        });
                      } else {
                        plugin.tabManager.updateCurrentFitler({'folder': ''});
                      }
                    },
                    type: 'folders',
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}
