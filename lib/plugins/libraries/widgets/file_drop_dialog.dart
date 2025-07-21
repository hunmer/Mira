// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';

class FileDropDialog extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Function(List<File>) onFilesSelected;

  const FileDropDialog({
    super.key,
    required this.plugin,
    required this.onFilesSelected,
  });

  @override
  _FileDropDialogState createState() => _FileDropDialogState();
}

class _FileDropDialogState extends State<FileDropDialog> {
  final List<File> _selectedFiles = [];
  final List<bool> _selectedItems = [];

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
    return Dialog(
      insetPadding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
      child: SizedBox(
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
                        (uri) {
                          if (uri != null) {
                            setState(() async {
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
                            });
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
              if (_selectedFiles.isNotEmpty) ...[
                const Text('已选择文件:'),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _selectedFiles.length,
                    itemBuilder: (context, index) {
                      return CheckboxListTile(
                        value: _selectedItems[index],
                        onChanged: (value) {
                          setState(() {
                            _selectedItems[index] = value!;
                          });
                        },
                        title: Text(
                          _selectedFiles[index].path
                              .replaceAll('\\', '/')
                              .split('/')
                              .last,
                        ),
                        subtitle: FutureBuilder<int>(
                          future: () async {
                            try {
                              final length =
                                  await _selectedFiles[index].length();
                              return length;
                            } catch (e) {
                              return 0;
                            }
                          }(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(formatFileSize(snapshot.data!));
                            }
                            return const Text('计算大小中...');
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _onDone, child: const Text('确认选择')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
