import 'package:mira/plugins/libraries/services/websocket_handlers/common_handler.dart';

class ConnectionHandler extends BaseWebSocketHandler {
  final String action;
  ConnectionHandler({
    required super.dbService,
    required super.channel,
    required super.data,
    required this.action,
    required super.requestId,
    required super.libraryId,
  });

  @override
  Future<void> handle() async {
    switch (action) {
      case 'open':
        try {
          final tags = await dbService.getAllTags();
          final folders = await dbService.getAllFolders();
          sendSuccess({
            'libraryId': libraryId,
            'tags': tags,
            'folders': folders,
          });
        } catch (err) {
          sendError('Library load error', err.toString());
        }
        break;
    }
  }
}
