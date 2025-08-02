// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/widgets/checkable_treeview/treeview.dart';
import 'package:path/path.dart' as path;
// ignore: depend_on_referenced_packages
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'dart:io' if (dart.library.html) 'web_io_stub.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/library.dart';

// ignore: must_be_immutable
class FileDropView extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final String btnOk;
  final List<File> items;
  late Function(List<File>, Map<File, List<String>>, Map<File, String?>)
  onFileAdded;
  late Function(List<File>, Map<File, List<String>>, Map<File, String?>) onDone;
  late Function() onClear;

  FileDropView({
    super.key,
    this.btnOk = '确定上传',
    required this.items,
    required this.plugin,
    required this.library,
    required this.onFileAdded,
    required this.onDone,
    required this.onClear,
  });

  @override
  _FileDropViewState createState() => _FileDropViewState();
}

class FileDataSource extends AsyncDataTableSource {
  final List<File> files;
  final List<bool> selectedItems;
  final Map<int, List<String>> fileTags;
  final Map<int, String?> fileFolders;
  final Function(int, bool) onSelectChanged;
  final Function(int) onSetTag;
  final Function(int) onSetFolder;
  final Function(int) onDelete;
  final Future<String> Function(String) getTagTitle;
  final Future<String> Function(String) getFolderTitle;

  FileDataSource({
    required this.files,
    required this.selectedItems,
    required this.fileTags,
    required this.fileFolders,
    required this.onSelectChanged,
    required this.onSetTag,
    required this.onSetFolder,
    required this.onDelete,
    required this.getTagTitle,
    required this.getFolderTitle,
  }) {
    addListener(() {});
  }
  @override
  DataRow? getRow(int index) {
    if (index >= files.length) return null;
    final file = files[index];
    final tags = fileTags[index] ?? [];
    final folderId = fileFolders[index];

    return DataRow2(
      selected: selectedItems[index],
      onSelectChanged: (value) => onSelectChanged(index, value ?? false),
      cells: [
        DataCell(Text(path.basenameWithoutExtension(file.path))),
        DataCell(Text(path.extension(file.path).toUpperCase())),
        DataCell(
          FutureBuilder<int>(
            future: file.length(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(formatFileSize(snapshot.data!));
              }
              return const Text('计算中...');
            },
          ),
        ),
        DataCell(
          tags.isEmpty
              ? const Text('无')
              : FutureBuilder<List<String>>(
                future: Future.wait(
                  tags.map((tagId) => getTagTitle(tagId)).toList(),
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Wrap(
                      spacing: 4,
                      children: [
                        const Icon(Icons.tag, size: 16),
                        const SizedBox(width: 4),
                        Expanded(child: Text(snapshot.data!.join(', '))),
                      ],
                    );
                  }
                  return const Text('加载中...');
                },
              ),
        ),
        DataCell(
          folderId == null
              ? const Text('无')
              : FutureBuilder<String>(
                future: getFolderTitle(folderId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder, size: 16),
                        const SizedBox(width: 4),
                        Expanded(child: Text(snapshot.data!)),
                      ],
                    );
                  }
                  return const Text('加载中...');
                },
              ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.label, size: 16),
                tooltip: '设置标签',
                onPressed: () => onSetTag(index),
              ),
              IconButton(
                icon: const Icon(Icons.folder, size: 16),
                tooltip: '设置文件夹',
                onPressed: () => onSetFolder(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 16),
                tooltip: '删除',
                onPressed: () => onDelete(index),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  Future<AsyncRowsResponse> getRows(int firstRowIndex, int count) async {
    final end = firstRowIndex + count;
    final rows = <DataRow>[];
    for (var index = firstRowIndex; index < end; index++) {
      if (index >= files.length) break;
      final file = files[index];
      final tags = fileTags[index] ?? [];
      final folderId = fileFolders[index];

      rows.add(
        DataRow2(
          selected: selectedItems[index],
          onSelectChanged: (value) {
            onSelectChanged(index, value ?? false);
            // Remove notifyListeners() call to prevent full list refresh
          },
          cells: [
            DataCell(Text(path.basenameWithoutExtension(file.path))),
            DataCell(Text(path.extension(file.path).toUpperCase())),
            DataCell(
              FutureBuilder<int>(
                future: file.length(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(formatFileSize(snapshot.data!));
                  }
                  return const Text('计算中...');
                },
              ),
            ),
            DataCell(
              tags.isEmpty
                  ? const Text('无')
                  : FutureBuilder<List<String>>(
                    future: Future.wait(
                      tags.map((tagId) => getTagTitle(tagId)).toList(),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Wrap(
                          spacing: 4,
                          children:
                              snapshot.data!
                                  .map(
                                    (title) => Chip(
                                      label: Text(title),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  )
                                  .toList(),
                        );
                      }
                      return const Text('加载中...');
                    },
                  ),
            ),
            DataCell(
              folderId == null
                  ? const Text('无')
                  : FutureBuilder<String>(
                    future: getFolderTitle(folderId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.folder, size: 16),
                            const SizedBox(width: 4),
                            Expanded(child: Text(snapshot.data!)),
                          ],
                        );
                      }
                      return const Text('加载中...');
                    },
                  ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.label, size: 16),
                    tooltip: '设置标签',
                    onPressed: () => onSetTag(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder, size: 16),
                    tooltip: '设置文件夹',
                    onPressed: () => onSetFolder(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    tooltip: '删除',
                    onPressed: () => onDelete(index),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return AsyncRowsResponse(files.length, rows);
  }
}

class _FileDropViewState extends State<FileDropView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<bool> _selectedItems = [];
  final Map<int, List<String>> _fileTags =
      {}; // Store tags for each file by index
  final Map<int, String?> _fileFolders =
      {}; // Store folder for each file by index
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  final PaginatorController _paginatorController = PaginatorController();
  int _rowsPerPage = 50;
  int _initialRow = 0;

  @override
  void initState() {
    super.initState();
    // Initialize selected items to match initial files
    _selectedItems.addAll(List.filled(widget.items.length, true));
  }

  @override
  void didUpdateWidget(FileDropView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected items when files change
    while (_selectedItems.length < widget.items.length) {
      _selectedItems.add(true);
    }
    while (_selectedItems.length > widget.items.length) {
      _selectedItems.removeLast();
    }

    // Clean up tags and folders for removed files
    final currentIndices = Set<int>.from(
      List.generate(widget.items.length, (i) => i),
    );
    _fileTags.removeWhere((index, _) => !currentIndices.contains(index));
    _fileFolders.removeWhere((index, _) => !currentIndices.contains(index));
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      widget.items.sort((a, b) {
        final aPath = a.path.replaceAll('\\', '/');
        final bPath = b.path.replaceAll('\\', '/');

        switch (columnIndex) {
          case 0: // 文件名
            return path
                    .basenameWithoutExtension(aPath)
                    .compareTo(path.basenameWithoutExtension(bPath)) *
                (ascending ? 1 : -1);
          case 1: // 格式
            return path.extension(aPath).compareTo(path.extension(bPath)) *
                (ascending ? 1 : -1);
          case 2: // 大小
            return a.lengthSync().compareTo(b.lengthSync()) *
                (ascending ? 1 : -1);
          case 3: // 标签 - 待实现
            return 0;
          case 4: // 文件夹
            return path.dirname(aPath).compareTo(path.dirname(bPath)) *
                (ascending ? 1 : -1);
          default:
            return 0;
        }
      });
    });
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result != null) {
      final files = result.paths.map((path) => File(path!)).toList();
      widget.onFileAdded(files, {}, {});
    }
  }

  Future<void> _pickDirectory() async {
    if (kIsWeb) {
      // Web platform doesn't support directory picking
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web 平台不支持选择目录。请使用拖拽或文件选择功能。')),
      );
      return;
    }

    String? directory = await FilePicker.platform.getDirectoryPath();
    if (directory != null) {
      await _scanDir(directory);
    }
  }

  // scan dir files
  Future<void> _scanDir(String path) async {
    if (kIsWeb) {
      // Web platform doesn't support directory scanning
      return;
    }

    final dir = Directory(path);
    final files =
        await dir
            .list(recursive: true)
            .where((entity) => entity is File)
            .toList();
    widget.onFileAdded(files.cast<File>(), {}, {});
  }

  void _onDone() {
    final filesToUpload = <File>[];
    final fileTags = <File, List<String>>{};
    final fileFolders = <File, String?>{};

    for (int i = 0; i < widget.items.length; i++) {
      if (i < _selectedItems.length && _selectedItems[i]) {
        final file = widget.items[i];
        filesToUpload.add(file);
        fileTags[file] = _fileTags[i] ?? [];
        fileFolders[file] = _fileFolders[i];
      }
    }

    widget.onDone(filesToUpload, fileTags, fileFolders);
    widget.onClear();
    _selectedItems.clear();
    _fileTags.clear();
    _fileFolders.clear();
  }

  Future<void> _onSetTag(int index) async {
    final library = widget.library;
    if (library != null) {
      final result = await widget.plugin.libraryUIController.showTagSelector(
        library,
        context,
        selectionMode: TreeSelectionMode.multiple,
      );
      if (result != null && result.isNotEmpty) {
        setState(() {
          _fileTags[index] = result.map((tag) => tag.id).toList();
        });
      }
    }
  }

  Future<void> _onSetFolder(int index) async {
    final library = widget.library;
    if (library != null) {
      final result = await widget.plugin.libraryUIController.showFolderSelector(
        library,
        context,
      );
      if (result != null && result.isNotEmpty) {
        setState(() {
          _fileFolders[index] = result.first.id;
        });
      }
    }
  }

  void _onDeleteFile(int index) {
    setState(() {
      widget.items.removeAt(index);
      _selectedItems.removeAt(index);

      // Shift tags and folders for indices after the deleted item
      final newFileTags = <int, List<String>>{};
      final newFileFolders = <int, String?>{};

      for (final entry in _fileTags.entries) {
        if (entry.key < index) {
          newFileTags[entry.key] = entry.value;
        } else if (entry.key > index) {
          newFileTags[entry.key - 1] = entry.value;
        }
      }

      for (final entry in _fileFolders.entries) {
        if (entry.key < index) {
          newFileFolders[entry.key] = entry.value;
        } else if (entry.key > index) {
          newFileFolders[entry.key - 1] = entry.value;
        }
      }

      _fileTags.clear();
      _fileTags.addAll(newFileTags);
      _fileFolders.clear();
      _fileFolders.addAll(newFileFolders);
    });
  }

  Future<void> _onSetAllTags() async {
    final library = widget.library;
    if (library != null) {
      final result = await widget.plugin.libraryUIController.showTagSelector(
        library,
        context,
        selectionMode: TreeSelectionMode.multiple,
      );
      if (result != null && result.isNotEmpty) {
        setState(() {
          final tagIds = result.map((tag) => tag.id).toList();
          for (int i = 0; i < widget.items.length; i++) {
            _fileTags[i] = tagIds;
          }
        });
      }
    }
  }

  Future<void> _onSetAllFolders() async {
    final library = widget.library;
    if (library != null) {
      final result = await widget.plugin.libraryUIController.showFolderSelector(
        library,
        context,
      );
      if (result != null && result.isNotEmpty) {
        setState(() {
          final folderId = result.first.id;
          for (int i = 0; i < widget.items.length; i++) {
            _fileFolders[i] = folderId;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropRegion(
              onPerformDrop: (event) async {
                for (final item in event.session.items) {
                  final reader = item.dataReader!;
                  if (reader.canProvide(Formats.fileUri)) {
                    reader.getValue<Uri>(
                      Formats.fileUri,
                      (uri) async {
                        if (uri != null) {
                          final path =
                              Platform.isWindows && uri.path.startsWith('/')
                                  ? Uri.decodeFull(uri.path.substring(1))
                                  : Uri.decodeFull(uri.path);
                          // check if is dir
                          final dir = Directory(path);
                          if (await dir.exists()) {
                            await _scanDir(path);
                          } else {
                            try {
                              final file = File(path);
                              if (await file.exists()) {
                                widget.onFileAdded([file], {}, {});
                              }
                            } catch (e) {
                              print('Error adding file: $e');
                            }
                          }
                        }
                      },
                      onError: (error) {
                        print('Error reading file URI: $error');
                      },
                    );
                  }
                }
              },
              onDropOver: (event) {
                return Future.value(DropOperation.copy);
              },
              formats: [],
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, size: 48),
                      SizedBox(height: 8),
                      Text('拖拽文件到此处或点击下方按钮添加'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.insert_drive_file),
                  label: const Text('添加文件'),
                  onPressed: _pickFiles,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.folder),
                  label: const Text('添加目录'),
                  onPressed: _pickDirectory,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.items.isNotEmpty) ...[
              Expanded(
                child: AsyncPaginatedDataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 800,
                  wrapInCard: false,
                  rowsPerPage: _rowsPerPage,
                  initialFirstRowIndex: _initialRow,
                  onPageChanged: (rowIndex) {
                    _initialRow = rowIndex;
                  },
                  onRowsPerPageChanged: (value) {
                    setState(() {
                      _rowsPerPage = value ?? 10;
                    });
                  },
                  columns: [
                    DataColumn2(
                      label: const Text('文件名'),
                      onSort:
                          (columnIndex, ascending) =>
                              _sort(columnIndex, ascending),
                    ),
                    DataColumn2(
                      label: const Text('格式'),
                      onSort:
                          (columnIndex, ascending) =>
                              _sort(columnIndex, ascending),
                    ),
                    DataColumn2(
                      label: const Text('大小'),
                      numeric: true,
                      onSort:
                          (columnIndex, ascending) =>
                              _sort(columnIndex, ascending),
                    ),
                    DataColumn2(
                      label: const Text('标签'),
                      onSort:
                          (columnIndex, ascending) =>
                              _sort(columnIndex, ascending),
                    ),
                    DataColumn2(
                      label: const Text('文件夹'),
                      onSort:
                          (columnIndex, ascending) =>
                              _sort(columnIndex, ascending),
                    ),
                    DataColumn2(label: const Text('操作'), size: ColumnSize.S),
                  ],
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  source: FileDataSource(
                    files: widget.items,
                    selectedItems: _selectedItems,
                    fileTags: _fileTags,
                    fileFolders: _fileFolders,
                    onSelectChanged: (index, value) {
                      setState(() {
                        _selectedItems[index] = value;
                      });
                    },
                    onSetTag: _onSetTag,
                    onSetFolder: _onSetFolder,
                    onDelete: _onDeleteFile,
                    getTagTitle: (tagId) {
                      return widget.plugin.foldersTagsController
                          .getTagTitleById(widget.library.id, tagId);
                    },
                    getFolderTitle: (folderId) {
                      return widget.plugin.foldersTagsController
                          .getFolderTitleById(widget.library.id, folderId);
                    },
                  ),
                  controller: _paginatorController,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '共 ${widget.items.length} 个文件',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.label),
                        label: const Text('设置所有标签'),
                        onPressed: _onSetAllTags,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.folder),
                        label: const Text('设置所有文件夹'),
                        onPressed: _onSetAllFolders,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('清空'),
                        onPressed: widget.onClear,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _onDone,
                        child: Text(widget.btnOk),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
