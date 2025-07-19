import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_sqlite5.dart';
import 'package:mira/plugins/libraries/services/server_event_manager.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

class WebSocketServer {
  final int port;
  final Map<String, List<WebSocketChannel>> _libraryClients = {};
  late bool _connecting = false;
  late List<LibraryServerDataInterface> _libraryServices = [];
  late HttpServer? _server;
  late final ServerEventManager eventManager;

  WebSocketServer(this.port) {}

  Future<LibraryServerDataInterface> loadLibrary(
    Map<String, dynamic> dbConfig,
  ) async {
    final dbServer = LibraryServerDataSQLite5(this, dbConfig);
    await dbServer.initialize({'path': '${dbConfig['path']}\\library_data.db'});

    _libraryServices.add(dbServer);
    return dbServer;
  }

  LibraryServerDataInterface? findLibrary(String libraryId) {
    return _libraryServices.firstWhere(
      (library) => library.getLibraryId() == libraryId,
    );
  }

  // isStaring
  bool get connecting => _connecting;

  Future<void> start(String basePath) async {
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
      _connecting = true;
    } catch (err) {
      _connecting = false;
    }

    print('Serving at ws://${_server?.address.host}:${_server?.port}');
  }

  void _handleConnection(WebSocketChannel channel) async {
    channel.stream.listen(
      (message) async {
        try {
          debugPrint('Incoming message: $message');
          final data = jsonDecode(message);
          await _handleMessage(channel, data);

          // 如果有libraryId，添加到_libraryClients
          if (data is Map && data.containsKey('libraray')) {
            final libraryId = data['libraray'] as String;
            if (!_libraryClients.containsKey(libraryId)) {
              _libraryClients[libraryId] = [];
            }
            if (!_libraryClients[libraryId]!.contains(channel)) {
              _libraryClients[libraryId]!.add(channel);
            }
          }
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
        // 从所有library的客户端列表中移除
        for (final entry in _libraryClients.entries) {
          entry.value.remove(channel);
        }
      },
      onError: (error) => print('Error: $error'),
    );
  }

  Future<void> _handleMessage(
    WebSocketChannel channel,
    Map<String, dynamic> row,
  ) async {
    try {
      final payload = row['payload'] as Map<String, dynamic>;
      final action = row['action'] as String;
      final libraryId = row['library'] as String;
      final data = payload['data'] as Map<String, dynamic>;
      final recordType = payload['type'] as String;
      var dbService = findLibrary(libraryId);
      if (dbService == null && action != 'connected') {
        channel.sink.add(
          jsonEncode({'status': 'error', 'msg': 'Library not founded!'}),
        );
        return;
      }
      switch (action) {
        case 'connected':
          final library = data['libraray'];
          try {
            dbService = await loadLibrary(library);
            channel.sink.add(
              jsonEncode({
                'event': 'connected',
                'data': {
                  'tags': await dbService!.getAllTags(),
                  'folders': await dbService!.getAllFolders(),
                },
              }),
            );
          } catch (err) {
            channel.sink.add(
              jsonEncode({
                'status': 'error',
                'msg': 'Library load error: ${err.toString()}',
              }),
            );
          }
          break;
        case 'create':
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
                item = await dbService!.createFileFromPath(filePath, fileMeta);
              } else {
                item = await dbService!.createFile({
                  'reference': data['reference'],
                  'url': data['url'],
                  'path': data['path'],
                  ...data,
                });
              }
              id = item['id'];
              dbService.getEventManager().broadcastToClients(
                'file_created',
                ItemEventArgs({'id': id}),
              );
              dbService.getEventManager().broadcast(
                'file_created',
                ItemEventArgs(item),
              );
              break;
            case 'folder':
              id = await dbService!.createFolder(data);
              dbService.getEventManager().broadcastToClients(
                'folder_created',
                ItemEventArgs({'id': id}),
              );
              break;
            case 'tag':
              id = await dbService!.createTag(data);
              dbService.getEventManager().broadcastToClients(
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
          if (payload.containsKey('id')) {
            final id = payload['id'] as int;
            Map<String, dynamic>? record;
            switch (recordType) {
              case 'file':
                record = await dbService!.getFile(id);
                if (record != null) {
                  record['thumb'] =
                      record['thumb'] == 1
                          ? dbService.getItemThumbPath(record)
                          : '';
                }
                break;
              case 'folder':
                record = await dbService!.getFolder(id);
                break;
              case 'tag':
                record = await dbService!.getTag(id);
                break;
              case 'file_folder':
                final folders = await dbService!.getFileFolders(id);
                channel.sink.add(
                  jsonEncode({
                    'status': 'success',
                    'data': folders,
                    'requestId': data['requestId'],
                  }),
                );
                break;
              case 'file_tag':
                final tags = await dbService!.getFileTags(id);
                channel.sink.add(
                  jsonEncode({
                    'status': 'success',
                    'data': tags,
                    'requestId': data['requestId'],
                  }),
                );
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
                records = await dbService!.getFiles(
                  limit: payload['limit'] as int? ?? 100,
                  offset: payload['offset'] as int? ?? 0,
                  select: payload['select'] as String? ?? '*',
                  filters: payload['query'] as Map<String, dynamic>?,
                );
                for (var record in records) {
                  if (record['thumb'] == 1) {
                    record['thumb'] = dbService.getItemThumbPath(record);
                  }
                }
                break;
              case 'folder':
                records = await dbService!.getFolders(
                  limit: payload['limit'] as int? ?? 100,
                  offset: payload['offset'] as int? ?? 0,
                );
                break;
              case 'tag':
                records = await dbService!.getTags(
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
          final id = data['id'];
          final values = data['data'];
          bool success;
          switch (recordType) {
            case 'file':
              success = await dbService!.updateFile(id, values);
              if (success) {
                dbService.getEventManager().broadcastToClients(
                  'file_updated',
                  ItemEventArgs({'id': id}),
                );
              }
              break;
            case 'folder':
              success = await dbService!.updateFolder(id, values);
              if (success) {
                dbService.getEventManager().broadcastToClients(
                  'folder_updated',
                  ItemEventArgs({'id': id}),
                );
              }
              break;
            case 'tag':
              success = await dbService!.updateTag(id, values);
              if (success) {
                dbService.getEventManager().broadcastToClients(
                  'tag_updated',
                  ItemEventArgs({'id': id}),
                );
              }
              break;
            case 'file_folder':
              success = await dbService!.setFileFolders(id, values as String);
              channel.sink.add(
                jsonEncode({
                  'status': success ? 'success' : 'failed',
                  'message': success ? 'File folders updated' : 'Update failed',
                  'requestId': data['requestId'],
                }),
              );
              break;
            case 'file_tag':
              success = await dbService!.setFileTags(id, values.cast<String>());
              channel.sink.add(
                jsonEncode({
                  'status': success ? 'success' : 'failed',
                  'message': success ? 'File tags updated' : 'Update failed',
                  'requestId': data['requestId'],
                }),
              );
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
          final id = data['payload']['data']['id'];
          bool success;
          switch (recordType) {
            case 'file':
              success = await dbService!.deleteFile(id);
              if (success) {
                dbService.getEventManager().broadcastToClients(
                  'file_deleted',
                  ItemEventArgs({'id': id}),
                );
                dbService.getEventManager().broadcast(
                  'file_deleted',
                  ItemEventArgs({'id': id}),
                );
              }
              break;
            case 'folder':
              success = await dbService!.deleteFolder(id);
              if (success) {
                dbService.getEventManager().broadcastToClients(
                  'folder_deleted',
                  ItemEventArgs({'id': id}),
                );
              }
              break;
            case 'tag':
              success = await dbService!.deleteTag(id);
              if (success) {
                dbService.getEventManager().broadcastToClients(
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
          'requestId': row.containsKey('requestId') ? row['requestId'] : null,
        }),
      );
    }
  }

  /// 广播事件给指定library的客户端
  void broadcastLibraryEvent(
    String libraryId,
    String eventName,
    EventArgs args,
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
    _libraryServices.forEach((dbService) => dbService.close());
    await _server?.close();
    _connecting = false;
    _libraryServices = [];
    print('WebSocket server stopped');
  }
}
