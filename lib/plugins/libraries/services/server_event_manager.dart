import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/services/websocket_server.dart';

class ServerEventManager {
  final WebSocketServer _server;

  ServerEventManager(this._server);

  /// 广播事件给所有连接的客户端
  void broadcastToClients(String eventName, EventArgs args) {
    _server.broadcastEvent(eventName, args);
  }

  void subscribe(String eventName, handler) {
    eventManager.subscribe(eventName, handler);
  }

  void unsubscribe(String eventName, handler) {
    eventManager.unsubscribe(eventName, handler);
  }

  void broadcast(String eventName, EventArgs args) {
    eventManager.broadcast(eventName, args);
  }
}
