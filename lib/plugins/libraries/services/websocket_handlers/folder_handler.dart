import 'package:mira/plugins/libraries/services/websocket_handlers/common_handler.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';

class FolderHandler extends BaseWebSocketHandler {
  final String action;
  final Map<String, dynamic> payload;

  FolderHandler({
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
        case 'all':
          sendSuccess({'folders': await dbService.getAllFolders()});
          break;
        case 'read':
          if (payload.containsKey('id')) {
            final record = await dbService.getFolder(payload['id'] as int);
            sendSuccess({'record': record});
          } else {
            final records = await dbService.getFolders(
              limit: payload['limit'] as int? ?? 100,
              offset: payload['offset'] as int? ?? 0,
            );
            sendSuccess({'records': records});
          }
          break;

        case 'create':
          final id = await dbService.createFolder(data);
          final folders = await dbService.getAllFolders();
          sendSuccess({'id': id, 'folders': folders});
          break;

        case 'update':
          final success = await dbService.updateFolder(
            data['id'] as int,
            data['data'] as Map<String, dynamic>,
          );
          if (success) {
            final folders = await dbService.getAllFolders();
            sendSuccess({'folders': folders});
          } else {
            sendError('Update failed');
          }
          break;

        case 'delete':
          final success = await dbService.deleteFolder(data['id'] as int);
          if (success) {
            final folders = await dbService.getAllFolders();
            sendSuccess({'folders': folders});
          } else {
            sendError('Delete failed');
          }
          break;

        default:
          sendError('Unknown action for folders');
      }
    } catch (e) {
      sendError('Folder operation failed', e.toString());
    }
  }
}
