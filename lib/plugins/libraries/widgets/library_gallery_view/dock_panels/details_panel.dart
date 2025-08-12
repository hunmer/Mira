import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:mira/plugins/libraries/widgets/selected_files_page.dart';
import '../library_gallery_state.dart';

/// 详情面板组件
class DetailsPanel extends StatelessWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final LibraryGalleryState state;

  const DetailsPanel({
    super.key,
    required this.plugin,
    required this.library,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tooltip(
                  message: '文件信息',
                  child: Tab(icon: Icon(Icons.info_outline)),
                ),
                Tooltip(
                  message: '选中文件列表',
                  child: Tab(icon: Icon(Icons.list_alt)),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildFileInfoTab(), _buildSelectedFilesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfoTab() {
    return ValueListenableBuilder<LibraryFile?>(
      valueListenable: state.selectedFileNotifier,
      builder: (context, selectedFile, _) {
        return selectedFile != null
            ? LibraryFileInformationView(
              plugin: plugin,
              library: library,
              file: selectedFile,
            )
            : const Center(child: Text('请选择一个文件查看详情'));
      },
    );
  }

  Widget _buildSelectedFilesTab() {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: state.selectedFileIds,
      builder: (context, selectedIds, _) {
        final selectedFiles =
            state.items.value
                .where((file) => selectedIds.contains(file.id))
                .toList();
        if (selectedFiles.isEmpty) {
          return const Center(child: Text('未选中文件'));
        }
        return Column(
          children: [
            Expanded(
              child: SelectedFilesPage(
                plugin: plugin,
                library: library,
                selectedFiles: selectedFiles,
                galleryState: state,
                onSelectionChanged: (selectedIds) {
                  state.selectedFileIds.value = selectedIds;
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 详情面板注册器
class DetailsPanelRegistrar {
  static const String type = 'library_details';

  static void register(dynamic manager) {
    manager.registry.register(
      type,
      builder: (values) {
        final plugin = values['plugin'] as LibrariesPlugin;
        final library = Library.fromMap(
          values['library'] as Map<String, dynamic>,
        );
        final state = values['state'] as LibraryGalleryState;

        return DetailsPanel(plugin: plugin, library: library, state: state);
      },
    );
  }
}
