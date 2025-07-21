import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
import '../l10n/libraries_localizations.dart';

class UploadQueueDialog extends StatelessWidget {
  final UploadQueueService uploadQueue;

  const UploadQueueDialog({required this.uploadQueue, super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = LibrariesLocalizations.of(context);
    if (localizations == null) return Container();
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.uploadQueue,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          StreamBuilder<int>(
            stream: uploadQueue.progressStream,
            builder: (context, snapshot) {
              final pendingCount = uploadQueue.pendingFiles.length;
              final completedCount = uploadQueue.completedFiles.length;
              final failedCount = uploadQueue.failedFiles.length;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pendingCount > 0)
                    ListTile(
                      leading: Icon(Icons.hourglass_top, color: Colors.blue),
                      title: Text('${localizations.pending}: $pendingCount'),
                    ),
                  if (completedCount > 0)
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text(
                        '${localizations.completed}: $completedCount',
                      ),
                    ),
                  if (failedCount > 0)
                    ListTile(
                      leading: Icon(Icons.error, color: Colors.red),
                      title: Text('${localizations.failed}: $failedCount'),
                    ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: uploadQueue.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
