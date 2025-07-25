import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mira/core/utils/taskbar.dart';
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
  // ignore: library_private_types_in_public_api
  _FileUploadListDialogState createState() => _FileUploadListDialogState();
}

class _FileUploadListDialogState extends State<FileUploadListDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ValueNotifier<List<File>> _filesNotifier = ValueNotifier([]);
  StreamSubscription<Map<String, int>>? _progressSubscription;
  StreamSubscription<QueueTask>? _taskStatusSubscription;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filesNotifier.value = List.from(widget.initialFiles);
    _progressSubscription = widget.uploadQueue.progressStream.listen((
      progress,
    ) {
      _uploadProgress = widget.uploadQueue.progress;
      Taskbar.setProgress(progress['total'] as int, progress['done'] as int);
    });
    _taskStatusSubscription = widget.uploadQueue.taskStatusStream.listen((
      task,
    ) {
      final taskId = task.id;
      final status = task.status;
      if (taskId != null && status != null) {}
    });
  }

  @override
  void dispose() {
    _taskStatusSubscription?.cancel();
    _progressSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onUploadFiles(List<File> files) async {
    await widget.uploadQueue.addFiles(files);
    _filesNotifier.value = [];
  }

  Future<void> _onFileAdded(List<File> files) async {
    _filesNotifier.value = [..._filesNotifier.value, ...files];
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
                  ValueListenableBuilder<List<File>>(
                    valueListenable: _filesNotifier,
                    builder: (context, files, child) {
                      return FileDropView(
                        plugin: widget.plugin,
                        items: _filesNotifier.value,
                        onFileAdded: _onFileAdded,
                        onDone: _onUploadFiles,
                        onClear: () {
                          setState(() {
                            _filesNotifier.value = [];
                          });
                        },
                        btnOk: '开始上传',
                        key: const PageStorageKey('fileDropView'),
                      );
                    },
                  ),
                  // 上传队列Tab
                  UploadQueueView(
                    queueServer: widget.uploadQueue,
                    key: const PageStorageKey('uploadQueueView'), // 保持状态
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
