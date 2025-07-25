// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:io';
import 'dart:convert';
import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_sqlite5.dart';
import 'package:mira/plugins/libraries/services/library_service.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:mira/plugins/libraries/services/websocket_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// ignore: depend_on_referenced_packages
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

class WebSocketServer {
  final int port;
  final Map<String, List<WebSocketChannel>> _libraryClients = {};
  late bool _connecting = false;
  late List<LibraryServerDataInterface> _libraryServices = [];
  late HttpServer? _server;

  WebSocketServer(this.port);

  Future<LibraryServerDataInterface> loadLibrary(
    Map<String, dynamic> dbConfig,
  ) async {
    final dbServer = LibraryServerDataSQLite5(this, dbConfig);
    await dbServer.initialize();
    _libraryServices.add(dbServer);
    return dbServer;
  }

  bool libraryExists(String libraryId) {
    return _libraryServices.any(
      (library) => library.getLibraryId() == libraryId,
    );
  }

  // isStaring
  bool get connecting => _connecting;

  Future<void> start(String basePath) async {
    try {
      _server = await shelf_io.serve(
        webSocketHandler((WebSocketChannel channel, String? protocol) {
          _handleConnection(channel);
        }, pingInterval: Duration(seconds: 30)),
        InternetAddress.anyIPv6,
        port,
      );
      _connecting = true;
    } catch (err) {
      _connecting = false;
    }

    print('Serving at ws://${_server?.address.host}:${_server?.port}');
  }

  void broadcastToClients(String eventName, Map<String, dynamic> eventData) {
    final dbService = _libraryServices.firstWhere(
      (library) => library.getLibraryId() == eventData['libraryId'],
    );
    dbService.getEventManager().broadcastToClients(
      eventName,
      ServerEventArgs(eventData),
    );
  }

  void sendToWebsocket(WebSocketChannel channel, Map<String, dynamic> data) {
    channel.sink.add(jsonEncode(data));
  }

  void broadcastPluginEvent(String eventName, Map<String, dynamic> data) {
    final dbService = _libraryServices.firstWhere(
      (library) => library.getLibraryId() == data['libraryId'],
    );
    dbService.getEventManager().broadcast(eventName, ServerEventArgs(data));
  }

  void _handleConnection(WebSocketChannel channel) async {
    channel.stream.listen(
      (message) async {
        try {
          // debugPrint('Incoming message: $message');
          final data = jsonDecode(message);
          await _handleMessage(channel, data);
          if (data is Map && data.containsKey('libraryId')) {
            final libraryId = data['libraryId'] as String;
            if (!_libraryClients.containsKey(libraryId)) {
              _libraryClients[libraryId] = [];
            }
            if (!_libraryClients[libraryId]!.contains(channel)) {
              _libraryClients[libraryId]!.add(channel);
            }
          }
        } catch (e) {
          sendToWebsocket(channel, {
            'error': 'Invalid message format',
            'details': e.toString(),
          });
        }
      },
      onDone: () {
        print('Client disconnected');
        // 从所有library的客户端列表中移除
        for (final entry in _libraryClients.entries) {
          entry.value.remove(channel);
        }
      },
      onError: (error) => print('Error: $error'),
    );
  }

  LibraryServerDataInterface getLibraray(String libraryId) {
    return _libraryServices.firstWhere(
      (library) => library.getLibraryId() == libraryId,
    );
  }

  Future<void> _handleMessage(
    WebSocketChannel channel,
    Map<String, dynamic> row,
  ) async {
    final payload = row['payload'] as Map<String, dynamic>;
    final action = row['action'] as String;
    final requestId = row['requestId'] as String;
    final libraryId = row['libraryId'] as String;
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    final recordType = payload['type'] as String;
    final exists = libraryExists(libraryId);

    if (action == 'open' && recordType == 'library') {
      final library = data['library'];
      try {
        final service = LibraryService(
          exists ? getLibraray(libraryId) : await loadLibrary(library),
        );
        final result = await service.connectLibrary(library);
        sendToWebsocket(channel, {'event': 'connected', 'data': result});
      } catch (err) {
        sendToWebsocket(channel, {
          'status': 'error',
          'msg': 'Library load error: ${err.toString()}',
        });
      }
      return;
    }

    if (!exists) {
      sendToWebsocket(channel, {
        'status': 'error',
        'msg': 'Library not founded!',
      });
      return;
    }

    final dbService = _libraryServices.firstWhere(
      (library) => library.getLibraryId() == libraryId,
    );

    final handler = await WebSocketRouter.route(dbService, channel, {
      ...row,
      'payload': payload,
    });

    if (handler != null) {
      await handler.handle();
    } else {
      sendToWebsocket(channel, {
        'status': 'error',
        'message':
            'Unsupported action: $action '
            'and record type: $recordType ',
        'requestId': requestId,
      });
    }
  }

  /// 广播事件给指定library的客户端
  void broadcastLibraryEvent(
    String libraryId,
    String eventName,
    ServerEventArgs args,
  ) {
    final message = jsonEncode({'event': eventName, 'data': args});

    // 广播给指定library的客户端
    if (_libraryClients.containsKey(libraryId)) {
      for (final client in _libraryClients[libraryId]!) {
        if (client.closeCode == null) {
          client.sink.add(message);
        }
      }
    }
  }

  Future<void> stop() async {
    for (var dbService in _libraryServices) {
      dbService.close();
    }
    await _server?.close();
    _connecting = false;
    _libraryServices = [];
    print('WebSocket server stopped');
  }
}
