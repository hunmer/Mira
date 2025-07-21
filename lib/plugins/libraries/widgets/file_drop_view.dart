// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';

class FileDropView extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Function(List<File>) onFilesSelected;

  const FileDropView({
    super.key,
    required this.plugin,
    required this.onFilesSelected,
  });

  @override
  _FileDropViewState createState() => _FileDropViewState();
}

class FileDataSource extends AsyncDataTableSource {
  final List<File> files;
  final List<bool> selectedItems;
  final Function(int, bool) onSelectChanged;

  FileDataSource({
    required this.files,
    required this.selectedItems,
    required this.onSelectChanged,
  }) {
    addListener(() {});
  }

  @override
  Future<int> getRowCount() async {
    return files.length;
  }

  @override
  Future<int> getSelectedRowCount() async {
    return selectedItems.where((element) => element).length;
  }

  @override
  DataRow? getRow(int index) {
    if (index >= files.length) return null;
    final file = files[index];
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
        DataCell(const Text('无')), // 标签 - 待实现
        DataCell(const Text('无')), // 文件夹 - 待实现
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
      rows.add(
        DataRow2(
          selected: selectedItems[index],
          onSelectChanged: (value) {
            onSelectChanged(index, value ?? false);
            notifyListeners(); // 添加这行以确保UI更新
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
            DataCell(const Text('无')), // 标签 - 待实现
            DataCell(const Text('无')), // 文件夹 - 待实现
          ],
        ),
      );
    }
    return AsyncRowsResponse(files.length, rows);
  }
}

class _FileDropViewState extends State<FileDropView> {
  final List<File> _selectedFiles = [];
  final List<bool> _selectedItems = [];
  late FileDataSource _fileDataSource;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  final PaginatorController _paginatorController = PaginatorController();
  int _rowsPerPage = 50;
  int _initialRow = 0;
  @override
  void initState() {
    super.initState();
    _fileDataSource = FileDataSource(
      files: _selectedFiles,
      selectedItems: _selectedItems,
      onSelectChanged: (index, value) {
        setState(() {
          _selectedItems[index] = value;
          _fileDataSource.notifyListeners();
        });
      },
    );
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      _selectedFiles.sort((a, b) {
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
    );
    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.paths.map((path) => File(path!)).toList());
        _selectedItems.addAll(List.filled(result.paths.length, true));
      });
    }
  }

  Future<void> _pickDirectory() async {
    String? directory = await FilePicker.platform.getDirectoryPath();
    if (directory != null) {
      await _scanDir(directory);
    }
  }

  // scan dir files
  Future<void> _scanDir(String path) async {
    final dir = Directory(path);
    final files =
        await dir
            .list(recursive: true)
            .where((entity) => entity is File)
            .toList();
    setState(() {
      _selectedFiles.addAll(files.cast<File>());
      _selectedItems.addAll(List.filled(files.length, true));
      _fileDataSource = FileDataSource(
        files: _selectedFiles,
        selectedItems: _selectedItems,
        onSelectChanged: (index, value) {
          setState(() {
            _selectedItems[index] = value;
            _fileDataSource.notifyListeners(); // 确保数据源通知监听器
          });
        },
      );
    });
  }

  void _onDone() {
    final filesToUpload = <File>[];
    for (int i = 0; i < _selectedFiles.length; i++) {
      if (_selectedItems[i]) {
        filesToUpload.add(_selectedFiles[i]);
      }
    }
    widget.onFilesSelected(filesToUpload);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                                _selectedFiles.add(file);
                                _selectedItems.add(true);
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
                setState(() {});
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
            if (_selectedFiles.isNotEmpty) ...[
              const Text('已选择文件:'),
              const SizedBox(height: 8),
              Expanded(
                child: AsyncPaginatedDataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 800,
                  wrapInCard: false,
                  header: const Text('已选择文件'),
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
                  ],
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  source: _fileDataSource,
                  controller: _paginatorController,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '共 ${_selectedFiles.length} 个文件',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  ElevatedButton(onPressed: _onDone, child: const Text('确认选择')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
