import 'package:mira/plugins/libraries/services/websocket_handlers/common_handler.dart';

class FileHandler extends BaseWebSocketHandler {
  final String action;
  final Map<String, dynamic> payload;

  FileHandler({
    required super.dbService,
    required super.channel,
    required super.data,
    required super.requestId,
    required super.libraryId,
    required this.action,
    required this.payload,
  });

  @override
  Future<void> handle() async {
    try {
      switch (action) {
        case 'read':
          if (payload.containsKey('id')) {
            final record = await dbService.getFile(payload['id'] as int);
            if (record != null) {
              record['thumb'] =
                  record['thumb'] == 1
                      ? await dbService.getItemThumbPath(record)
                      : '';
            }
            sendSuccess({'record': record});
          } else {
            final result = await dbService.getFiles(
              select: payload['select'] as String? ?? '*',
              filters: payload['data'] as Map<String, dynamic>?,
            );
            for (var record in result['result']) {
              record['thumb'] = await dbService.getItemThumbPath(record);
            }
            sendSuccess(result);
          }
          break;

        case 'create':
          if (data.containsKey('path')) {
            final fileMeta = {
              'reference': data['reference'],
              'path': data['path'],
              ...data,
            };
            final item = await dbService.createFileFromPath(
              data['path'],
              fileMeta,
            );
            sendSuccess({'id': item['id'], 'path': data['path']});
          } else {
            sendError('Binary upload is not supported in this version');
          }
          break;

        case 'update':
          final success = await dbService.updateFile(
            data['id'] as int,
            data['data'] as Map<String, dynamic>,
          );
          sendSuccess({'success': success});
          break;

        case 'recover':
          final success = await dbService.recoverFile(data['id'] as int);
          sendSuccess({'success': success});
          break;

        case 'delete':
          final success = await dbService.deleteFile(
            data['id'] as int,
            moveToRecycleBin: data['moveToRecycleBin'],
          );
          sendSuccess({'success': success});
          break;

        default:
          sendError('Unknown action for files');
      }
    } catch (e) {
      sendError('File operation failed', e.toString());
    }
  }
}
