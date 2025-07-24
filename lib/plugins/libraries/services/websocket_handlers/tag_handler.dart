import 'package:mira/plugins/libraries/services/websocket_handlers/common_handler.dart';

class TagHandler extends BaseWebSocketHandler {
  final String action;
  final Map<String, dynamic> payload;

  TagHandler({
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
          return sendSuccess({'tags': await dbService.getAllTags()});
        case 'read':
          if (payload.containsKey('id')) {
            final record = await dbService.getTag(payload['id'] as int);
            sendSuccess({'record': record});
          } else {
            final records = await dbService.getTags(
              limit: payload['limit'] as int? ?? 100,
              offset: payload['offset'] as int? ?? 0,
            );
            sendSuccess({'records': records});
          }
          break;

        case 'create':
          final id = await dbService.createTag(data);
          final tags = await dbService.getAllTags();
          sendSuccess({'id': id, 'tags': tags});
          break;

        case 'update':
          final success = await dbService.updateTag(
            data['id'] as int,
            data['data'] as Map<String, dynamic>,
          );
          if (success) {
            final tags = await dbService.getAllTags();
            sendSuccess({'tags': tags});
          } else {
            sendError('Update failed');
          }
          break;

        case 'delete':
          final success = await dbService.deleteTag(data['id'] as int);
          if (success) {
            final tags = await dbService.getAllTags();
            sendSuccess({'tags': tags});
          } else {
            sendError('Delete failed');
          }
          break;

        case 'file_tag':
          if (action == 'update') {
            final success = await dbService.setFileTags(
              data['id'] as int,
              (data['data'] as List).cast<String>(),
            );
            sendSuccess({'success': success});
          } else if (action == 'read') {
            final tags = await dbService.getFileTags(data['id'] as int);
            sendSuccess({'tags': tags});
          }
          break;

        default:
          sendError('Unknown action for tags');
      }
    } catch (e) {
      sendError('Tag operation failed', e.toString());
    }
  }
}
