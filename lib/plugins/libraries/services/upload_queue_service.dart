// ignore_for_file: unused_field

import 'dart:async';
import 'dart:io';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:queue/queue.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';

class UploadQueueService {
  final LibrariesPlugin plugin;
  final Library library;
  final Queue _queue = Queue(parallel: 3); // 同时上传3个文件
  final StreamController<int> _progressController =
      StreamController<int>.broadcast();
  int _totalFiles = 0;
  int _completedFiles = 0;
  int _failedFiles = 0;
  final List<File> _completedFileList = [];
  final List<File> _failedFileList = [];

  UploadQueueService(this.plugin, this.library);

  Stream<int> get progressStream => _progressController.stream;
  List<File> get completedFiles => _completedFileList;
  List<File> get failedFiles => _failedFileList;

  Future<void> addFiles(List<File> files) async {
    _totalFiles += files.length;
    _progressController.add(_completedFiles);

    for (final file in files) {
      _queue.add(() async {
        try {
          await plugin.libraryController
              .getLibraryInst(library)!
              .addFileFromPath(file.path);
          _completedFiles++;
          _completedFileList.add(file);
          _progressController.add(_completedFiles);
        } catch (e) {
          // 错误处理
          _completedFiles++;
          _failedFiles++;
          _failedFileList.add(file);
          _progressController.add(_completedFiles);
        }
      });
    }
  }

  Future<void> onComplete() => _queue.onComplete;

  void cancel() => _queue.cancel();

  void dispose() {
    _progressController.close();
    _queue.dispose();
  }

  double get progress {
    return _totalFiles == 0 ? 0 : _completedFiles / _totalFiles;
  }

  List<File> get pendingFiles {
    return [];
  }
}
