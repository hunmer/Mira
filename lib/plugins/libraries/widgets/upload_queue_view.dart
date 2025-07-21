import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

enum UploadStatus { pending, uploading, completed, failed }

class UploadItem {
  final File file;
  UploadStatus status;
  double progress;

  UploadItem({
    required this.file,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
  });
}

class UploadQueueView extends StatefulWidget {
  final List<UploadItem> uploadQueue;
  final VoidCallback onClearQueue;
  final VoidCallback onStartUpload;

  const UploadQueueView({
    super.key,
    required this.uploadQueue,
    required this.onClearQueue,
    required this.onStartUpload,
  });

  @override
  State<UploadQueueView> createState() => _UploadQueueViewState();
}

class _UploadQueueViewState extends State<UploadQueueView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (widget.uploadQueue.isNotEmpty)
            Expanded(
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 800,
                columns: const [
                  DataColumn2(label: Text('文件名')),
                  DataColumn2(label: Text('大小'), numeric: true),
                  DataColumn2(label: Text('状态')),
                  DataColumn2(label: Text('进度')),
                ],
                rows:
                    widget.uploadQueue.map((item) {
                      return DataRow2(
                        cells: [
                          DataCell(Text(path.basename(item.file.path))),
                          DataCell(
                            FutureBuilder<int>(
                              future: item.file.length(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(formatFileSize(snapshot.data!));
                                }
                                return const Text('计算中...');
                              },
                            ),
                          ),
                          DataCell(Text(_getStatusText(item.status))),
                          DataCell(
                            LinearProgressIndicator(
                              value: item.progress,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                item.status == UploadStatus.completed
                                    ? Colors.green
                                    : item.status == UploadStatus.failed
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            )
          else
            const Expanded(child: Center(child: Text('暂无待上传文件'))),
          if (widget.uploadQueue.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: widget.onClearQueue,
                    child: const Text('清空队列'),
                  ),
                  ElevatedButton(
                    onPressed: widget.onStartUpload,
                    child: const Text('开始上传'),
                  ),
                ],
              ),
            ),
        ],
      ),
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
}
