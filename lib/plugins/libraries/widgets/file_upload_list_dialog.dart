import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
import 'dart:io';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/file_drop_view.dart';
import 'package:mira/plugins/libraries/widgets/upload_queue_view.dart';

class FileUploadListDialog extends StatefulWidget {
  final LibrariesPlugin plugin;
  final UploadQueueService uploadQueue;
  final List<File> initialFiles;

  const FileUploadListDialog({
    super.key,
    required this.plugin,
    required this.uploadQueue,
    this.initialFiles = const [],
  });

  @override
  _FileUploadListDialogState createState() => _FileUploadListDialogState();
}

// UploadStatus and UploadItem moved to upload_queue_view.dart

class _FileUploadListDialogState extends State<FileUploadListDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<File> _receivedFiles = [];
  final List<File> _uploadList = [];
  List<QueueTask> _queueTasks = [];
  StreamSubscription<int>? _progressSubscription;
  StreamSubscription<QueueTask>? _taskStatusSubscription;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _uploadList.addAll(widget.initialFiles);
    _progressSubscription = widget.uploadQueue.progressStream.listen((
      completed,
    ) {
      setState(() {
        _uploadProgress = widget.uploadQueue.progress;
      });
    });
    _taskStatusSubscription = widget.uploadQueue.taskStatusStream.listen((
      task,
    ) {
      final taskId = task.id;
      final status = task.status;
      if (taskId != null && status != null) {
        setState(() {
          _queueTasks = widget.uploadQueue.pendingFileList;
        });
      }
    });
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onFilesSelected(List<File> files) {
    setState(() {
      _uploadList.addAll(files);
      _receivedFiles.clear();
      _queueTasks = widget.uploadQueue.pendingFileList;
      _startUpload(); // 自动开始上传
    });
  }

  Future<void> _uploadFiles(List<File> filesToUpload) async {
    await widget.uploadQueue.addFiles(filesToUpload);
  }

  void _startUpload() {
    // 重置所有任务状态为pending
    _uploadFiles(_uploadList); // 上传接收到的文件
  }

  void _toggleUpload() {}

  void _clearQueue() {
    setState(() {
      _uploadList.clear();
      widget.uploadQueue.clear();
      _queueTasks = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [Tab(text: '文件接收'), Tab(text: '上传队列')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 文件接收Tab
                  FileDropView(
                    plugin: widget.plugin,
                    onFilesSelected: _onFilesSelected,
                    btnOk: '开始上传',
                    key: const PageStorageKey('fileDropView'), // 保持状态
                  ),
                  // 上传队列Tab
                  UploadQueueView(
                    uploadQueue: _queueTasks,
                    onClearQueue: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('确认清空队列'),
                            content: const Text('确定要清空上传队列吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _clearQueue();
                                  Navigator.pop(context);
                                },
                                child: const Text('确定'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onStartUpload: _startUpload,
                    key: const PageStorageKey('uploadQueueView'), // 保持状态
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '共 ${_uploadList.length} 个文件待上传',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _getStatusText moved to upload_queue_view.dart
}

extension on QueueTask {
  operator [](String other) {}
}
