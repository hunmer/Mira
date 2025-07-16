import 'dart:io';
import 'dart:convert';
import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_sqlite5.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

class WebSocketServer {
  final int port;
  final LibraryServerDataInterface _dbService;
  late final _basePath;
  HttpServer? _server;

  WebSocketServer(this.port, {Map<String, dynamic>? dbConfig})
    : _dbService = LibraryServerDataSQLite5() {
    if (dbConfig != null) {
      _dbService.initialize(dbConfig);
    }
  }

  Future<void> start(String basePath) async {
    _basePath = basePath;
    _server = await HttpServer.bind(InternetAddress.anyIPv6, port);
    await _dbService.initialize({'path': '$basePath\\library_data.db'});

    print('WebSocket server running on ws://localhost:$port');

    await for (HttpRequest request in _server!) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final shelfRequest = Request(
          request.method,
          Uri.parse(request.uri.toString()),
        );
        await handler(
          shelfRequest.change(
            context: {'shelf.io.connection_info': request.connectionInfo},
          ),
        );
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.close();
      }
    }
  }

  void _handleConnection(WebSocketChannel channel) {
    channel.stream.listen(
      (message) async {
        try {
          final data = jsonDecode(message);
          await _handleMessage(channel, data);
        } catch (e) {
          channel.sink.add(
            jsonEncode({
              'error': 'Invalid message format',
              'details': e.toString(),
            }),
          );
        }
      },
      onDone: () => print('Client disconnected'),
      onError: (error) => print('Error: $error'),
    );
  }

  Handler get handler => webSocketHandler(
    (WebSocketChannel channel, String? protocol) {
      _handleConnection(channel);
    },
    // protocols: ['library-protocol-v1'],
    // allowedOrigins: ['http://localhost:8080'],
    pingInterval: Duration(seconds: 30),
  );

  Future<void> _handleMessage(
    WebSocketChannel channel,
    Map<String, dynamic> data,
  ) async {
    try {
      final action = data['action'] as String;
      final payload = data['payload'] as Map<String, dynamic>;

      switch (action) {
        case 'create':
          final id = await _dbService.createRecord(payload);
          channel.sink.add(jsonEncode({'status': 'success', 'id': id}));
          break;
        case 'read':
          if (payload.containsKey('id')) {
            final record = await _dbService.getRecord(payload['id'] as int);
            channel.sink.add(jsonEncode({'status': 'success', 'data': record}));
          } else {
            final records = await _dbService.getRecords(
              limit: payload['limit'] as int? ?? 100,
              offset: payload['offset'] as int? ?? 0,
            );
            channel.sink.add(
              jsonEncode({'status': 'success', 'data': records}),
            );
          }
          break;
        case 'update':
          final success = await _dbService.updateRecord(
            payload['id'] as int,
            payload['data'] as Map<String, dynamic>,
          );
          channel.sink.add(
            jsonEncode({
              'status': success ? 'success' : 'failed',
              'message': success ? 'Record updated' : 'Update failed',
            }),
          );
          break;
        case 'delete':
          final success = await _dbService.deleteRecord(payload['id'] as int);
          channel.sink.add(
            jsonEncode({
              'status': success ? 'success' : 'failed',
              'message': success ? 'Record deleted' : 'Delete failed',
            }),
          );
          break;
        case 'beginTransaction':
          await _dbService.beginTransaction();
          channel.sink.add(jsonEncode({'status': 'success'}));
          break;
        case 'commitTransaction':
          await _dbService.commitTransaction();
          channel.sink.add(jsonEncode({'status': 'success'}));
          break;
        case 'rollbackTransaction':
          await _dbService.rollbackTransaction();
          channel.sink.add(jsonEncode({'status': 'success'}));
          break;
        default:
          channel.sink.add(
            jsonEncode({'status': 'error', 'message': 'Unknown action'}),
          );
      }
    } catch (e) {
      channel.sink.add(
        jsonEncode({
          'status': 'error',
          'message': 'Operation failed',
          'details': e.toString(),
        }),
      );
    }
  }

  Future<void> stop() async {
    await _dbService.close();
    await _server?.close();
    print('WebSocket server stopped');
  }
}
