import 'dart:async';

import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_queue_it/flutter_queue_it.dart';
import 'package:mira/core/utils/taskbar.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
import 'package:path/path.dart' as path;

class UploadQueueView extends StatefulWidget {
  final UploadQueueService queueServer;

  const UploadQueueView({super.key, required this.queueServer});

  @override
  State<UploadQueueView> createState() => _UploadQueueViewState();
}

class _UploadQueueViewState extends State<UploadQueueView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _queueRunning = false;
  StreamSubscription<Map<String, int>>? _progressSubscription;
  StreamSubscription<QueueTask>? _taskStatusSubscription;

  @override
  void initState() {
    super.initState();
    _progressSubscription = widget.queueServer.progressStream.listen((
      progress,
    ) {
      Taskbar.setProgress(progress['total'] as int, progress['done'] as int);
    });
    _taskStatusSubscription = widget.queueServer.taskStatusStream.listen((
      task,
    ) {
      final taskId = task.id;
      final status = task.status;
      if (taskId != null && status != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _taskStatusSubscription?.cancel();
    _progressSubscription?.cancel();
    super.dispose();
  }

  void _toggleRunning() {
    setState(() {
      _queueRunning = widget.queueServer.toggle();
    });
  }

  void _clearQueue() {
    setState(() {
      widget.queueServer.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return QueueItWidget(
      queue: widget.queueServer.queue,
      builder: (context, snapshot) {
        final items = widget.queueServer.queue.items().toList();
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (items.isNotEmpty)
                Expanded(
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 800,
                    columns: const [
                      DataColumn2(label: Text('文件名')),
                      DataColumn2(label: Text('大小'), numeric: true),
                      DataColumn2(label: Text('状态')),
                    ],
                    rows:
                        items.map((item) {
                          final task = item.data as QueueTask;
                          return DataRow2(
                            color: WidgetStateProperty.all(
                              getStatusColor(task.status),
                            ),
                            cells: [
                              DataCell(Text(path.basename(task.file.path))),
                              DataCell(
                                FutureBuilder<int>(
                                  future: task.file.length(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Text(
                                        formatFileSize(snapshot.data!),
                                      );
                                    }
                                    return const Text('计算中...');
                                  },
                                ),
                              ),
                              DataCell(Text(_getStatusText(task.status))),
                            ],
                          );
                        }).toList(),
                  ),
                )
              else
                const Expanded(child: Center(child: Text('暂无待上传文件'))),
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
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
                        child: const Text('清空队列'),
                      ),
                      ElevatedButton(
                        onPressed: _toggleRunning,
                        child: Text(_queueRunning ? '停止上传' : '开始上传'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getStatusText(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return '等待上传';
      case UploadStatus.uploading:
        return '上传中';
      case UploadStatus.completed:
        return '已完成';
      case UploadStatus.failed:
        return '失败';
    }
  }

  // getstatuscolor
  Color getStatusColor(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return Colors.grey;
      case UploadStatus.uploading:
        return Colors.blue;
      case UploadStatus.completed:
        return Colors.green;
      case UploadStatus.failed:
        return Colors.red;
    }
  }
}
