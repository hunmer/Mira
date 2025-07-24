import 'dart:convert';
import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class BaseWebSocketHandler {
  final LibraryServerDataInterface dbService;
  final WebSocketChannel channel;
  final Map<String, dynamic> data;
  final String requestId;
  final String libraryId;

  BaseWebSocketHandler({
    required this.dbService,
    required this.channel,
    required this.data,
    required this.requestId,
    required this.libraryId,
  });

  void sendResponse(Map<String, dynamic> response) {
    channel.sink.add(
      jsonEncode({...response, 'requestId': requestId, 'libraryId': libraryId}),
    );
  }

  void sendError(String message, [dynamic details]) {
    sendResponse({
      'status': 'error',
      'message': message,
      'details': details?.toString(),
    });
  }

  void sendSuccess([Map<String, dynamic>? data]) {
    sendResponse({'status': 'success', 'data': data ?? {}});
  }

  Future<void> handle() async {}
}
