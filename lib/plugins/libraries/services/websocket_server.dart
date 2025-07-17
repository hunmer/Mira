import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_sqlite5.dart';
import 'package:mira/plugins/libraries/services/plugins/thumb_generator.dart';
import 'package:mira/plugins/libraries/services/server_event_manager.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

class WebSocketServer {
  final int port;
  final LibraryServerDataInterface _dbService;
  late final _basePath;
  HttpServer? _server;
  late final ServerEventManager _eventManager;

  final Set<WebSocketChannel> _connectedClients = {};

  ServerEventManager get eventManager => _eventManager;

  late final ThumbGenerator _thumbGenerator;

  WebSocketServer(this.port, {Map<String, dynamic>? dbConfig})
    : _dbService = LibraryServerDataSQLite5() {
    if (dbConfig != null) {
      _dbService.initialize(dbConfig);
    }
    _eventManager = ServerEventManager(this);
    _thumbGenerator = ThumbGenerator(this, _dbService);
  }

  Future<void> start(String basePath) async {
    _basePath = basePath;
    await _dbService.initialize({'path': '$basePath\\library_data.db'});
    // TODO 保持ws服务后台运行
    try {
      _server = await shelf_io.serve(
        webSocketHandler(
          (WebSocketChannel channel, String? protocol) {
            _handleConnection(channel);
          },
          // protocols: ['library-protocol-v1'],
          // allowedOrigins: ['http://localhost:8080'],
          pingInterval: Duration(seconds: 30),
        ),
        InternetAddress.anyIPv6,
        port,
      );
    } catch (err) {}

    print('Serving at ws://${_server?.address.host}:${_server?.port}');
  }

  void _handleConnection(WebSocketChannel channel) {
    _connectedClients.add(channel);
    channel.stream.listen(
      (message) async {
        try {
          debugPrint('Incoming message: $message');
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
      onDone: () {
        print('Client disconnected');
        _connectedClients.remove(channel);
      },
      onError: (error) => print('Error: $error'),
    );
  }

  Future<void> _handleMessage(
    WebSocketChannel channel,
    Map<String, dynamic> data,
  ) async {
    try {
      final action = data['action'] as String;
      final payload = data['payload'] as Map<String, dynamic>;

      switch (action) {
        case 'create':
          final recordType = payload['type'] as String;
          final data = payload['data'] as Map<String, dynamic>;
          int id;
          switch (recordType) {
            case 'file':
              var item;
              if (data.containsKey('path')) {
                // 处理从文件路径添加的情况
                final filePath = data['path'] as String;
                final fileMeta = {
                  'reference': data['reference'],
                  'url': data['url'],
                  'path': data['path'],
                  ...data,
                };
                item = await _dbService.createFileFromPath(filePath, fileMeta);
              } else {
                item = await _dbService.createFile({
                  'reference': data['reference'],
                  'url': data['url'],
                  'path': data['path'],
                  ...data,
                });
              }
              id = item['id'];
              _eventManager.broadcastToClients(
                'file_created',
                ItemEventArgs({'id': id}),
              );
              _eventManager.broadcast('file_created', ItemEventArgs(item));
              break;
            case 'folder':
              id = await _dbService.createFolder(data);
              _eventManager.broadcastToClients(
                'folder_created',
                ItemEventArgs({'id': id}),
              );
              break;
            case 'tag':
              id = await _dbService.createTag(data);
              _eventManager.broadcastToClients(
                'tag_created',
                ItemEventArgs({'id': id}),
              );
              break;
            default:
              throw ArgumentError('Invalid record type: $recordType');
          }
          channel.sink.add(
            jsonEncode({
              'status': 'success',
              'id': id,
              'requestId':
                  data.containsKey('requestId') ? data['requestId'] : null,
            }),
          );
          break;
        case 'read':
          final recordType = payload['type'] as String;
          if (payload.containsKey('id')) {
            final id = payload['id'] as int;
            Map<String, dynamic>? record;
            switch (recordType) {
              case 'file':
                record = await _dbService.getFile(id);
                if (record != null && record['thumb'] == 1) {
                  record['thumb'] = getItemThumbPath(record);
                }
                break;
              case 'folder':
                record = await _dbService.getFolder(id);
                break;
              case 'tag':
                record = await _dbService.getTag(id);
                break;
              default:
                throw ArgumentError('Invalid record type: $recordType');
            }
            channel.sink.add(
              jsonEncode({
                'status': 'success',
                'data': record,
                'requestId':
                    data.containsKey('requestId') ? data['requestId'] : null,
              }),
            );
          } else {
            List<Map<String, dynamic>> records;
            switch (recordType) {
              case 'file':
                records = await _dbService.getFiles(
                  limit: payload['limit'] as int? ?? 100,
                  offset: payload['offset'] as int? ?? 0,
                  select: payload['select'] as String? ?? '*',
                  filters: payload['query'] as Map<String, dynamic>?,
                );
                for (var record in records) {
                  if (record['thumb'] == 1) {
                    record['thumb'] = getItemThumbPath(record);
                  }
                }
                break;
              case 'folder':
                records = await _dbService.getFolders(
                  limit: payload['limit'] as int? ?? 100,
                  offset: payload['offset'] as int? ?? 0,
                );
                break;
              case 'tag':
                records = await _dbService.getTags(
                  limit: payload['limit'] as int? ?? 100,
                  offset: payload['offset'] as int? ?? 0,
                );
                break;
              default:
                throw ArgumentError('Invalid record type: $recordType');
            }
            channel.sink.add(
              jsonEncode({
                'status': 'success',
                'data': records,
                'requestId':
                    data.containsKey('requestId') ? data['requestId'] : null,
              }),
            );
          }
          break;
        case 'update':
          final recordType = payload['type'] as String;
          final id = payload['id'] as int;
          final data = payload['data'] as Map<String, dynamic>;
          bool success;
          switch (recordType) {
            case 'file':
              success = await _dbService.updateFile(id, data);
              if (success) {
                _eventManager.broadcastToClients(
                  'file_updated',
                  ItemEventArgs({'id': id}),
                );
              }
              break;
            case 'folder':
              success = await _dbService.updateFolder(id, data);
              if (success) {
                _eventManager.broadcastToClients(
                  'folder_updated',
                  ItemEventArgs({'id': id}),
                );
              }
              break;
            case 'tag':
              success = await _dbService.updateTag(id, data);
              if (success) {
                _eventManager.broadcastToClients(
                  'tag_updated',
                  ItemEventArgs({'id': id}),
                );
              }
              break;
            default:
              throw ArgumentError('Invalid record type: $recordType');
          }
          channel.sink.add(
            jsonEncode({
              'status': success ? 'success' : 'failed',
              'message': success ? 'Record updated' : 'Update failed',
              'requestId':
                  data.containsKey('requestId') ? data['requestId'] : null,
            }),
          );
          break;
        case 'delete':
          final recordType = payload['type'] as String;
          final id = data['payload']['data']['id'];
          bool success;
          switch (recordType) {
            case 'file':
              success = await _dbService.deleteFile(id);
              if (success) {
                _eventManager.broadcastToClients(
                  'file_deleted',
                  ItemEventArgs({'id': id}),
                );
                _eventManager.broadcast(
                  'file_deleted',
                  ItemEventArgs({'id': id}),
                );
              }
              break;
            case 'folder':
              success = await _dbService.deleteFolder(id);
              if (success) {
                _eventManager.broadcastToClients(
                  'folder_deleted',
                  ItemEventArgs({'id': id}),
                );
              }
              break;
            case 'tag':
              success = await _dbService.deleteTag(id);
              if (success) {
                _eventManager.broadcastToClients(
                  'tag_deleted',
                  ItemEventArgs({'id': id}),
                );
              }
              break;
            default:
              throw ArgumentError('Invalid record type: $recordType');
          }
          channel.sink.add(
            jsonEncode({
              'status': success ? 'success' : 'failed',
              'message': success ? 'Record deleted' : 'Delete failed',
              'requestId':
                  data.containsKey('requestId') ? data['requestId'] : null,
            }),
          );
          break;
        default:
          channel.sink.add(
            jsonEncode({
              'status': 'error',
              'message': 'Unknown action',
              'requestId':
                  data.containsKey('requestId') ? data['requestId'] : null,
            }),
          );
      }
    } catch (e) {
      channel.sink.add(
        jsonEncode({
          'status': 'error',
          'message': 'Operation failed',
          'details': e.toString(),
          'requestId': data.containsKey('requestId') ? data['requestId'] : null,
        }),
      );
    }
  }

  /// 广播事件给所有客户端
  void broadcastEvent(String eventName, EventArgs args) {
    final message = jsonEncode({'event': eventName, 'data': args});
    for (final client in _connectedClients) {
      client.sink.add(message);
    }
  }

  /// 获取项目路径
  String getItemPath(item) {
    return '$_basePath\\${item['hash']}\\';
  }

  String getItemThumbPath(item) {
    return '${getItemPath(item)}preview.png';
  }

  Future<void> stop() async {
    await _dbService.close();
    await _server?.close();
    _connectedClients.clear();
    print('WebSocket server stopped');
  }
}
