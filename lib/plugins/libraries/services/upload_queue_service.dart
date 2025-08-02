// ignore_for_file: unused_field

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mira/core/event/event_args.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/file_drop_view.dart';
import 'package:queue_it/queue_it.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';

enum UploadStatus { pending, uploading, completed, failed }

class QueueTask {
  final String id;
  final DateTime createdAt;
  final FileItem fileItem;
  final List<String> tags;
  final String? folderId;
  UploadStatus status;

  QueueTask({
    required this.id,
    required this.fileItem,
    required this.status,
    this.tags = const [],
    this.folderId,
  }) : createdAt = DateTime.now();

  // Backward compatibility - get File object if available
  File? get file => fileItem.nativeFile;
}

class UploadQueueService {
  final LibrariesPlugin plugin;
  final Library library;
  final StreamController<Map<String, int>> _progressController =
      StreamController<Map<String, int>>.broadcast();
  final StreamController<QueueTask> _taskStatusController =
      StreamController<QueueTask>.broadcast();
  int _totalFiles = 0;
  int _completedFiles = 0;
  int _failedFiles = 0;
  final List<FileItem> _completedFileList = [];
  final List<FileItem> _failedFileList = [];
  late final QueueIt queue;

  UploadQueueService(this.plugin, this.library) {
    queue = QueueIt(
        parallel: 3, // 同时上传3个文件
        itemHandler: (QueueItem<dynamic> item) async {
          final task = item.data as QueueTask;
          task.status = UploadStatus.uploading;
          _taskStatusController.add(task);
          try {
            final inst = plugin.libraryController.getLibraryInst(library.id)!;
            final metaData = {'tags': task.tags, 'folder_id': task.folderId};

            if (kIsWeb) {
              // Web platform - handle FileItem with bytes
              await _handleWebFileUpload(inst, task.fileItem, metaData);
            } else {
              // Native platform - use file path
              if (task.fileItem.nativeFile != null) {
                if (library.isLocal) {
                  inst.addFileFromPath(
                    task.fileItem.nativeFile!.path,
                    metaData,
                  );
                } else {
                  inst.uploadFile(task.fileItem.nativeFile!.path, metaData);
                }
              } else {
                throw Exception(
                  'Native file not available on non-web platform',
                );
              }
            }

            _completedFiles++;
            _completedFileList.add(task.fileItem);
          } catch (e) {
            // 错误处理
            _completedFiles++;
            _failedFiles++;
            _failedFileList.add(task.fileItem);
            task.status = UploadStatus.failed;
            print('Upload failed for ${task.fileItem.name}: $e');
          } finally {
            boradcastProgress();
          }
        },
      )
      ..onUpdate.listen((snapshot) {
        // print('Queue updated: ${snapshot.event.name}');
      });
    // 监听广播获取上传结果
    EventManager.instance.subscribe('file::uploaded', _onFileUploaded);
  }

  /// Handle web file upload with bytes
  Future<void> _handleWebFileUpload(
    dynamic inst,
    FileItem fileItem,
    Map<String, dynamic> metaData,
  ) async {
    if (fileItem.bytes == null) {
      throw Exception('File bytes not available for web upload');
    }

    // For web platform, we need to create a file entry with bytes
    final fileData = {
      'name': fileItem.name,
      'size': fileItem.bytes!.length,
      'bytes': fileItem.bytes,
      'path': fileItem.filePath, // Use the filename as path for web
    };

    if (library.isLocal) {
      // For local libraries on web, we might need special handling
      await inst.addFile(fileData, metaData);
    } else {
      // For remote libraries, upload the bytes
      final result = await inst.uploadFileBytes(fileData, metaData);

      // Check if upload was successful
      if (result is Map<String, dynamic> && result['success'] == false) {
        throw Exception('Upload failed: ${result['message']}');
      }
    }
  }

  void boradcastProgress() {
    _progressController.add({
      'done': _completedFiles,
      'total': _totalFiles,
      'failed': _failedFiles,
    });
  }

  void _onFileUploaded(EventArgs args) {
    if (args is! MapEventArgs) return;
    final filePath = args.item['path'];
    for (final item in queue.items()) {
      final task = item.data as QueueTask;
      if (areFilePathsEqual(task.fileItem.filePath, filePath)) {
        task.status = UploadStatus.completed;
        _taskStatusController.add(task);
        break;
      }
    }
  }

  Stream<Map<String, int>> get progressStream => _progressController.stream;
  Stream<QueueTask> get taskStatusStream => _taskStatusController.stream;
  List<FileItem> get completedFiles => _completedFileList;
  List<FileItem> get failedFiles => _failedFileList;

  Future<List<QueueTask>> addFiles(
    List<FileItem> fileItems, {
    Map<FileItem, List<String>>? fileTags,
    Map<FileItem, String?>? fileFolders,
  }) async {
    _totalFiles += fileItems.length;
    final tasks =
        fileItems
            .map(
              (fileItem) => QueueTask(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                fileItem: fileItem,
                status: UploadStatus.pending,
                tags: fileTags?[fileItem] ?? [],
                folderId: fileFolders?[fileItem],
              ),
            )
            .toList();

    for (final task in tasks) {
      queue.add(task, id: task.id);
    }
    queue.start(); // 自动开始
    return tasks;
  }

  bool toggle() {
    if (queue.isStarted) {
      stop();
      return false;
    } else {
      start();
      return true;
    }
  }

  void start() => queue.start();
  void stop() => queue.stop();
  void dispose() {
    queue.dispose();
    _progressController.close();
    _taskStatusController.close();
  }

  void clear() {
    _totalFiles = 0;
    _completedFiles = 0;
    _failedFiles = 0;
    _completedFileList.clear();
    _failedFileList.clear();
    queue.cancelAll();
    queue.removeAll();
    if (!_progressController.isClosed) {
      boradcastProgress();
    }
  }

  double get progress {
    return _totalFiles == 0 ? 0 : _completedFiles / _totalFiles;
  }
}
