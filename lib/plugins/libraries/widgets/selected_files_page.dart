import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view/library_gallery_state.dart';
import 'package:mira/widgets/checkable_treeview/treeview.dart';

enum SelectedFilesViewType { list, grid }

class SelectedFilesPage extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final List<LibraryFile> selectedFiles;
  final Function(Set<int>) onSelectionChanged;
  final LibraryGalleryState? galleryState;

  const SelectedFilesPage({
    Key? key,
    required this.plugin,
    required this.library,
    required this.selectedFiles,
    required this.onSelectionChanged,
    this.galleryState,
  }) : super(key: key);

  @override
  State<SelectedFilesPage> createState() => _SelectedFilesPageState();
}

class _SelectedFilesPageState extends State<SelectedFilesPage> {
  SelectedFilesViewType _viewType = SelectedFilesViewType.list;

  @override
  void initState() {
    super.initState();
  }

  // 根据当前选中的ID从主界面获取文件列表
  List<LibraryFile> get _files {
    if (widget.galleryState != null) {
      final selectedIds = widget.galleryState!.selectedFileIds.value;
      final allItems = widget.galleryState!.items.value;
      return allItems.where((file) => selectedIds.contains(file.id)).toList();
    }
    // 如果没有 galleryState，使用传入的静态列表
    return widget.selectedFiles;
  }

  Set<int> get _selectedFileIds {
    return widget.galleryState?.selectedFileIds.value ??
        _files.map((f) => f.id).toSet();
  }

  void _updateSelection(Set<int> newSelection) {
    if (widget.galleryState != null) {
      widget.galleryState!.selectedFileIds.value = newSelection;
    }
    widget.onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    // 如果有 galleryState，使用 ValueListenableBuilder 来监听变化
    if (widget.galleryState != null) {
      return ValueListenableBuilder<List<LibraryFile>>(
        valueListenable: widget.galleryState!.items,
        builder: (context, allItems, _) {
          return ValueListenableBuilder<Set<int>>(
            valueListenable: widget.galleryState!.selectedFileIds,
            builder: (context, selectedIds, _) {
              return _buildScaffold();
            },
          );
        },
      );
    }
    // 如果没有 galleryState，直接构建界面
    return _buildScaffold();
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 移除返回按钮
        title: Text('选中文件 (${_files.length})'),
        actions: [
          IconButton(
            icon: Icon(
              _viewType == SelectedFilesViewType.list
                  ? Icons.grid_view
                  : Icons.list,
            ),
            onPressed: () {
              setState(() {
                _viewType =
                    _viewType == SelectedFilesViewType.list
                        ? SelectedFilesViewType.grid
                        : SelectedFilesViewType.list;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {
              _updateSelection({});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatisticsSection(),
          _buildSelectionActionsSection(),
          Expanded(
            child:
                _files.isEmpty
                    ? const Center(child: Text('无选中文件'))
                    : _buildFilesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final totalSize = _files.fold<int>(0, (sum, file) => sum + file.size);
    final tagCounts = <String, int>{};
    final folderCounts = <String, int>{};

    for (final file in _files) {
      for (final tag in file.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
      folderCounts[file.folderId] = (folderCounts[file.folderId] ?? 0) + 1;
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('统计信息', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '文件数量',
                    _files.length.toString(),
                    Icons.description,
                    null,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    '总大小',
                    _formatFileSize(totalSize),
                    Icons.storage,
                    null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '标签数',
                    tagCounts.length.toString(),
                    Icons.label,
                    _showTagSelector,
                  ),
                ),
                Expanded(
                  child: _buildStatCard(
                    '文件夹数',
                    folderCounts.length.toString(),
                    Icons.folder,
                    _showFolderSelector,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String tooltip,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Card(
          color:
              onTap != null
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : null,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Icon(icon, size: 24),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionActionsSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 全选
            Tooltip(
              message: '全选',
              child: IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: () {
                  final allIds = _files.map((f) => f.id).toSet();
                  _updateSelection(allIds);
                },
              ),
            ),
            // 反选
            Tooltip(
              message: '反选',
              child: IconButton(
                icon: const Icon(Icons.check_box),
                onPressed: () {
                  final allIds = _files.map((f) => f.id).toSet();
                  final newSelection =
                      allIds.difference(_selectedFileIds).toSet();
                  _updateSelection(newSelection);
                },
              ),
            ),
            // 清空选择
            Tooltip(
              message: '清空选择',
              child: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _updateSelection({});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    return _viewType == SelectedFilesViewType.list
        ? _buildListView()
        : _buildGridView();
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () => _removeFile(file.id),
                ),
              ],
            ),
            title: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storage, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(_formatFileSize(file.size)),
                  ],
                ),
                if (file.tags.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.label, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          file.tags.join(', '),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    const Icon(Icons.folder, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(file.folderId),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.8,
      ),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return Card(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: () => _removeFile(file.id),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFileSize(file.size),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      if (file.tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 2.0,
                          children:
                              file.tags
                                  .take(3)
                                  .map(
                                    (tag) => Chip(
                                      label: Text(
                                        tag,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeFile(int fileId) {
    // 直接从选中列表中移除该文件ID
    final newSelection = _selectedFileIds.where((id) => id != fileId).toSet();
    _updateSelection(newSelection);
  }

  Future<void> _showFolderSelector() async {
    final result = await widget.plugin.libraryUIController.showFolderSelector(
      widget.library,
      context,
      selectedFileIds: _files.map((f) => f.id).toList(),
    );

    if (result != null && result.isNotEmpty) {
      final folder = result.first;
      await _updateFilesFolder(folder.id);
    }
  }

  Future<void> _showTagSelector() async {
    final result = await widget.plugin.libraryUIController.showTagSelector(
      widget.library,
      context,
      selectionMode: TreeSelectionMode.multiple,
      selectedFileIds: _files.map((f) => f.id).toList(),
    );

    if (result != null && result.isNotEmpty) {
      final tagIds = result.map((tag) => tag.id).toList();
      await _updateFilesTags(tagIds);
    }
  }

  Future<void> _updateFilesFolder(String folderId) async {
    final libraryData = widget.plugin.libraryController.getLibraryInst(
      widget.library.id,
    );
    if (libraryData == null) return;

    try {
      for (final file in _files) {
        await libraryData.setFileFolders(file.id, folderId);
        // 更新本地文件信息
        final index = widget.selectedFiles.indexWhere((f) => f.id == file.id);
        if (index != -1) {
          widget.selectedFiles[index] = file.copyWith(folderId: folderId);
        }
      }

      // 更新本地文件信息
      // TODO 根据files的fileids从服务器获取信息
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已更新 ${_files.length} 个文件的文件夹')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新文件夹失败: $e')));
    }
  }

  Future<void> _updateFilesTags(List<String> tagIds) async {
    final libraryData = widget.plugin.libraryController.getLibraryInst(
      widget.library.id,
    );
    if (libraryData == null) return;

    try {
      for (final file in _files) {
        await libraryData.setFileTags(file.id, tagIds);
        // 更新本地文件信息
        final index = widget.selectedFiles.indexWhere((f) => f.id == file.id);
        if (index != -1) {
          widget.selectedFiles[index] = file.copyWith(tags: tagIds);
        }
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已更新 ${_files.length} 个文件的标签')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新标签失败: $e')));
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
