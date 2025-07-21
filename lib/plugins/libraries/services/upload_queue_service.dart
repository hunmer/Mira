// ignore_for_file: unused_field

import 'dart:async';
import 'dart:io';
import 'package:mira/core/event/event_args.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:queue_it/queue_it.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';

enum UploadStatus { pending, uploading, completed, failed }

class QueueTask {
  final String id;
  final DateTime createdAt;
  final File file;
  UploadStatus status; // 'pending', 'uploading', 'completed', 'failed'
  QueueTask({required this.id, required this.file, required this.status})
    : createdAt = DateTime.now();
}

class UploadQueueService {
  final LibrariesPlugin plugin;
  final Library library;
  final StreamController<int> _progressController =
      StreamController<int>.broadcast();
  final StreamController<QueueTask> _taskStatusController =
      StreamController<QueueTask>.broadcast();
  int _totalFiles = 0;
  int _completedFiles = 0;
  int _failedFiles = 0;
  final List<File> _completedFileList = [];
  final List<File> _failedFileList = [];
  final List<QueueTask> pendingFileList = [];
  late final QueueIt _queue; // 同时上传3个文件

  UploadQueueService(this.plugin, this.library) {
    _queue = QueueIt(
      parallel: 3,
      itemHandler: (QueueItem<dynamic> item) async {
        final task = item as QueueTask;
        task.status = UploadStatus.uploading;
        _taskStatusController.add(task);
        try {
          await plugin.libraryController
              .getLibraryInst(library)!
              .addFileFromPath(task.file.path);

          _completedFiles++;
          // pendingFileList.remove(task);
          _completedFileList.add(task.file);
        } catch (e) {
          // 错误处理
          _completedFiles++;
          // pendingFileList.remove(task);
          _failedFiles++;
          _failedFileList.add(task.file);
          task.status = UploadStatus.failed;
        } finally {
          _progressController.add(_completedFiles);
        }
      },
    );
    // 监听广播获取上传结果
    EventManager.instance.subscribe('file::uploaded', _onFileUploaded);
  }

  void _onFileUploaded(EventArgs args) {
    if (args is! MapEventArgs) return;
    final item = args.item['data'];
    if (item is! Map) return;
    final filePath = item['path'];
    for (final task in pendingFileList) {
      if (task.file.path == filePath) {
        task.status = UploadStatus.completed;
        _taskStatusController.add(task);
        break;
      }
    }
  }

  Stream<int> get progressStream => _progressController.stream;
  Stream<QueueTask> get taskStatusStream => _taskStatusController.stream;
  List<File> get completedFiles => _completedFileList;
  List<File> get failedFiles => _failedFileList;

  Future<List<QueueTask>> addFiles(List<File> files) async {
    _totalFiles += files.length;
    final tasks =
        files
            .map(
              (file) => QueueTask(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                file: file,
                status: UploadStatus.pending,
              ),
            )
            .toList();
    pendingFileList.addAll(tasks);
    _progressController.add(_completedFiles);

    for (final task in tasks) {
      _queue.add(task, id: task.id);
    }
    return tasks;
  }

  void toggle() {
    if (_queue.isStarted) {
      stop();
    } else {
      start();
    }
  }

  void start() => _queue.start();
  void stop() => _queue.stop();
  void dispose() {
    _progressController.close();
    _taskStatusController.close();
    _queue.dispose();
  }

  // clear
  void clear() {
    _totalFiles = 0;
    _completedFiles = 0;
    _failedFiles = 0;
    pendingFileList.clear();
    _progressController.add(0);
  }

  // cancel task
  void cancelTask(QueueTask task) {}

  double get progress {
    return _totalFiles == 0 ? 0 : _completedFiles / _totalFiles;
  }

  List<File> get pendingFiles {
    return pendingFileList.map((task) => task.file).toList();
  }
}
