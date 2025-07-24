import 'package:mira/plugins/libraries/services/websocket_handlers/common_handler.dart';
import 'package:mira/plugins/libraries/services/websocket_handlers/connection_handler.dart';
import 'package:mira/plugins/libraries/services/websocket_handlers/file_handler.dart';
import 'package:mira/plugins/libraries/services/websocket_handlers/folder_handler.dart';
import 'package:mira/plugins/libraries/services/websocket_handlers/tag_handler.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketRouter {
  static Future<BaseWebSocketHandler?> route(
    LibraryServerDataInterface dbService,
    WebSocketChannel channel,
    Map<String, dynamic> row,
  ) async {
    final requestId = row['requestId'] as String;
    final libraryId = row['libraryId'] as String;
    final action = row['action'] as String;
    final payload = row['payload'] as Map<String, dynamic>;
    final recordType = payload['type'] as String;
    final data = payload['data'];
    switch (recordType) {
      case 'tag':
        return TagHandler(
          dbService: dbService,
          channel: channel,
          data: payload['data'],
          requestId: requestId,
          libraryId: libraryId,
          action: action,
          payload: payload,
        );
      case 'folder':
        return FolderHandler(
          dbService: dbService,
          channel: channel,
          data: payload['data'] as Map<String, dynamic>,
          requestId: requestId,
          libraryId: libraryId,
          action: action,
          payload: payload,
        );
      case 'library':
        return ConnectionHandler(
          dbService: dbService,
          channel: channel,
          action: action,
          data: payload['data'] as Map<String, dynamic>,
          requestId: requestId,
          libraryId: libraryId,
        );
      case 'file':
        return FileHandler(
          dbService: dbService,
          channel: channel,
          data: payload['data'] as Map<String, dynamic>,
          requestId: requestId,
          libraryId: libraryId,
          action: action,
          payload: payload,
        );
    }
    return null;
  }
}
