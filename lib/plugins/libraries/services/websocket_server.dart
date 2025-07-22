// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_sqlite5.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
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
      serverEventArgs(eventData),
    );
  }

  void sendToWebsocket(WebSocketChannel channel, Map<String, dynamic> data) {
    channel.sink.add(jsonEncode(data));
  }

  void broadcastPluginEvent(String eventName, Map<String, dynamic> data) {
    final dbService = _libraryServices.firstWhere(
      (library) => library.getLibraryId() == data['libraryId'],
    );
    dbService.getEventManager().broadcast(eventName, serverEventArgs(data));
  }

  void _handleRespnes(
    String eventName,
    Map<String, dynamic> data, {
    WebSocketChannel? channel,
    bool isPluginEvent = true,
    bool isServerEvent = true,
  }) {
    if (channel != null) {
      data['event'] = eventName;
      sendToWebsocket(channel, data);
    }
    if (isPluginEvent) {
      broadcastPluginEvent(eventName, data);
    }
    if (isServerEvent) {
      broadcastToClients(eventName, data);
    }
  }

  void _handleConnection(WebSocketChannel channel) async {
    channel.stream.listen(
      (message) async {
        try {
          debugPrint('Incoming message: $message');
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
    if (action == 'connected') {
      if (!exists) {
        final library = data['library'];
        try {
          final dbService = await loadLibrary(library);
          sendToWebsocket(channel, {
            'event': 'connected',
            'data': {
              'libraryId': libraryId,
              'tags': await dbService.getAllTags(),
              'folders': await dbService.getAllFolders(),
            },
          });
        } catch (err) {
          sendToWebsocket(channel, {
            'status': 'error',
            'msg': 'Library load error: ${err.toString()}',
          });
        }
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
    try {
      switch (action) {
        case 'create':
          int id;
          switch (recordType) {
            case 'file':
              var item;
              if (data.containsKey('path')) {
                // 处理从文件路径添加的情况
                final fileMeta = {
                  'reference': data['reference'],
                  'path': data['path'],
                  ...data,
                };
                item = await dbService.createFileFromPath(
                  data['path'],
                  fileMeta,
                );
              } else {
                item = await dbService.createFile({
                  'reference': data['reference'],
                  'path': data['path'],
                  ...data,
                });
              }
              id = item['id'];
              sendToWebsocket(channel, {
                'event': 'file::uploaded',
                'data': {
                  'id': id,
                  'libraryId': libraryId,
                  'path': data['path'],
                },
              });
              broadcastToClients('file::created', ({
                'id': id,
                'libraryId': libraryId,
              }));
              broadcastPluginEvent('file::created', {
                ...item,
                'libraryId': libraryId,
              });
              break;
            case 'folder':
              id = await dbService.createFolder(data);
              final folders = await dbService.getAllFolders();
              broadcastToClients('folder::update', ({
                'id': id,
                'folders': folders,
                'libraryId': libraryId,
              }));
              break;
            case 'tag':
              id = await dbService.createTag(data);
              final tags = await dbService.getAllTags();
              broadcastToClients('tag::created', {
                'id': id,
                'tags': tags,
                'libraryId': libraryId,
              });
              break;
            default:
              throw ArgumentError('Invalid record type: $recordType');
          }
          sendToWebsocket(channel, {
            'status': 'success',
            'id': id,
            'requestId': requestId,
          });
          break;
        case 'read':
          if (payload.containsKey('id')) {
            final id = payload['id'] as int;
            Map<String, dynamic>? record;
            switch (recordType) {
              case 'file':
                record = await dbService.getFile(id);
                if (record != null) {
                  record['thumb'] =
                      record['thumb'] == 1
                          ? await dbService.getItemThumbPath(
                            record,
                            checkExists: true,
                          )
                          : '';
                }
                break;
              case 'folder':
                record = await dbService.getFolder(id);
                break;
              case 'tag':
                record = await dbService.getTag(id);
                break;
              case 'file_folder':
                final folders = await dbService.getFileFolders(id);
                sendToWebsocket(channel, {
                  'status': 'success',
                  'data': folders,
                  'requestId': requestId,
                });
                break;
              case 'file_tag':
                final tags = await dbService.getFileTags(id);
                sendToWebsocket(channel, {
                  'status': 'success',
                  'data': tags,
                  'requestId': requestId,
                });
                break;
              default:
                throw ArgumentError('Invalid record type: $recordType');
            }
            sendToWebsocket(channel, {
              'status': 'success',
              'data': record,
              'requestId': requestId,
            });
          } else {
            var records;
            switch (recordType) {
              case 'file':
                final result = await dbService.getFiles(
                  select: payload['select'] as String? ?? '*',
                  filters: payload['query'] as Map<String, dynamic>?,
                );
                for (var record in result['result']) {
                  record['thumb'] =
                      record['thumb'] == 1
                          ? await dbService.getItemThumbPath(
                            record,
                            checkExists: true,
                          )
                          : '';
                }
                records = result;
                break;
              case 'folder':
                records = await dbService.getFolders(
                  limit: payload['limit'] as int? ?? 100,
                  offset: payload['offset'] as int? ?? 0,
                );
                break;
              case 'tag':
                records = await dbService.getTags(
                  limit: payload['limit'] as int? ?? 100,
                  offset: payload['offset'] as int? ?? 0,
                );
                break;
              default:
                throw ArgumentError('Invalid record type: $recordType');
            }
            sendToWebsocket(channel, {
              'status': 'success',
              'data': records,
              'requestId': requestId,
            });
          }
          break;
        case 'update':
          final id = data['id'];
          final values = data['data'];
          bool success;
          switch (recordType) {
            case 'file':
              success = await dbService.updateFile(id, values);
              if (success) {
                broadcastToClients('file::updated', {
                  'id': id,
                  'libraryId': libraryId,
                });
              }
              break;
            case 'folder':
              success = await dbService.updateFolder(id, values);
              if (success) {
                broadcastToClients('folder::updated', {
                  'id': id,
                  'libraryId': libraryId,
                });
              }
              break;
            case 'tag':
              success = await dbService.updateTag(id, values);
              if (success) {
                broadcastToClients('tag::updated', {
                  'id': id,
                  'libraryId': libraryId,
                });
              }
              break;
            case 'file_folder':
              final folderId = values as String;
              success = await dbService.setFileFolders(id, folderId);
              _handleRespnes('file::folder', channel: channel, {
                'id': id,
                'folderId': folderId,
                'libraryId': libraryId,
              });
              break;
            case 'file_tag':
              final tagIds = values.cast<String>();
              success = await dbService.setFileTags(id, tagIds);
              _handleRespnes('file::tags', channel: channel, {
                'id': id,
                'tagIds': tagIds,
                'libraryId': libraryId,
              });
              break;
            default:
              throw ArgumentError('Invalid record type: $recordType');
          }
          sendToWebsocket(channel, {
            'status': success ? 'success' : 'failed',
            'requestId': requestId,
          });
          break;

        case 'recover':
          final id = data['id'];
          bool success;
          switch (recordType) {
            case 'file':
              success = await dbService.recoverFile(id);
              if (success) {
                broadcastToClients('file::recover', {
                  'id': id,
                  'libraryId': libraryId,
                });
              }
              break;
          }
          break;
        case 'delete':
          final id = data['id'];
          bool success;
          switch (recordType) {
            case 'file':
              success = await dbService.deleteFile(
                id,
                moveToRecycleBin: data['moveToRecycleBin'],
              );
              if (success) {
                broadcastToClients('file::deleted', {
                  'id': id,
                  'libraryId': libraryId,
                });
                broadcastPluginEvent('file::deleted', {
                  'id': id,
                  'libraryId': libraryId,
                });
              }
              break;
            case 'folder':
              success = await dbService.deleteFolder(id);
              if (success) {
                broadcastToClients('folder_deleted', {
                  'id': id,
                  'libraryId': libraryId,
                });
              }
              break;
            case 'tag':
              success = await dbService.deleteTag(id);
              if (success) {
                broadcastToClients('tag_deleted', {
                  'id': id,
                  'libraryId': libraryId,
                });
              }
              break;
            default:
              throw ArgumentError('Invalid record type: $recordType');
          }
          sendToWebsocket(channel, {
            'status': success ? 'success' : 'failed',
            'message': success ? 'Record deleted' : 'Delete failed',
            'requestId': requestId,
          });
          break;

        default:
          sendToWebsocket(channel, {
            'status': 'error',
            'message': 'Unknown action',
            'requestId': requestId,
          });
      }
    } catch (e) {
      sendToWebsocket(channel, {
        'status': 'error',
        'message': 'Operation failed',
        'details': e.toString(),
        'requestId': requestId,
      });
    }
  }

  /// 广播事件给指定library的客户端
  void broadcastLibraryEvent(
    String libraryId,
    String eventName,
    serverEventArgs args,
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
