import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:mira/plugins/libraries/services/websocket_server.dart';

class ServerEventManager {
  final WebSocketServer _server;
  final LibraryServerDataInterface _db;

  ServerEventManager(this._server, this._db);

  /// 广播事件给所有连接的客户端
  void broadcastToClients(String eventName, ServerEventArgs args) {
    _server.broadcastLibraryEvent(_db.getLibraryId(), eventName, args);
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
