// Stub implementation for shelf_web_socket package for web compatibility
import 'package:web_socket_channel/web_socket_channel.dart';

/// Stub implementation of webSocketHandler for web
dynamic webSocketHandler(
  Function(WebSocketChannel, String?) onConnection, {
  Duration? pingInterval,
  Iterable<String>? protocols,
  Map<String, dynamic>? headers,
}) {
  // Stub implementation for web - returns a simple handler function
  return (dynamic request) {
    // On web, WebSocket servers aren't typically implemented this way
    // This is a placeholder that will never actually be called
    throw UnsupportedError('WebSocket server is not supported on web platform');
  };
}
