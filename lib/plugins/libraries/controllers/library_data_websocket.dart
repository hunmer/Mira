import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'library_data_interface.dart';

class LibraryDataWebSocket implements LibraryDataInterface {
  final WebSocketChannel _channel;
  final Map<String, Completer<dynamic>> _responseHandlers = {};
  static int _requestCounter = 0;

  Future<dynamic> _sendRequest({
    required String action,
    required String type,
    dynamic data,
    Map<String, dynamic>? query,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final requestId = _generateRequestId();
    final completer = Completer<dynamic>();
    _responseHandlers[requestId] = completer;

    final message = {
      'action': action,
      'requestId': requestId,
      'payload': {
        'type': type,
        if (data != null) 'data': data,
        if (query != null) 'query': query,
      },
    };

    _channel.sink.add(jsonEncode(message));
    debugPrint('Sending WebSocket message: ${jsonEncode(message)}');

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          _responseHandlers.remove(requestId);
          print('$action request timed out after ${timeout.inSeconds} seconds');
        },
      );
    } catch (e) {
      _responseHandlers.remove(requestId);
      rethrow;
    }
  }

  LibraryDataWebSocket(this._channel) {
    _channel.stream.listen(
      _handleResponse,
      onError: (error) {
        print('连接出错: $error');
      },
      onDone: () {
        print('连接已关闭');
      },
    );
  }

  String _generateRequestId() {
    return Uuid().v4();
  }

  void _handleResponse(dynamic message) {
    try {
      debugPrint('Received WebSocket message: $message');
      final response = jsonDecode(message);
      if (response.containsKey('requestId')) {
        if (_responseHandlers.containsKey(response['requestId'])) {
          final completer = _responseHandlers.remove(response['requestId']);
          if (response['status'] == 'success') {
            completer?.complete(response['data']);
          } else {
            completer?.completeError(Exception(response['message']));
          }
        }
      } else {
        final eventName = response['event'];
        final data = response['data'];
        switch (eventName) {
          case 'connected':
            break;
          case 'thumbnail_generated':
            EventManager.instance.broadcast(eventName, ItemEventArgs(data));
            break;
        }
      }
    } catch (e) {
      print('Error handling response: $e');
    }
  }

  @override
  Future<void> addLibrary(Map<String, dynamic> library) async {
    await _sendRequest(action: 'create', type: 'library', data: library);
  }

  @override
  Future<void> deleteLibrary(String id) async {
    await _sendRequest(
      action: 'delete',
      type: 'library',
      data: {'id': int.parse(id)},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> findLibraries({
    Map<String, dynamic>? query,
  }) async {
    return await _sendRequest(
      action: 'read',
      type: 'library',
      query: query ?? {},
    );
  }

  @override
  void close() {
    _channel.sink.close();
  }

  @override
  Future<void> addFile(Map<String, dynamic> file) async {
    await _sendRequest(action: 'create', type: 'file', data: file);
  }

  @override
  Future<void> addFolder(Map<String, dynamic> folder) async {
    await _sendRequest(action: 'create', type: 'folder', data: folder);
  }

  @override
  Future<void> addTag(Map<String, dynamic> tag) async {
    await _sendRequest(action: 'create', type: 'tag', data: tag);
  }

  @override
  Future<void> deleteFile(int id) async {
    await _sendRequest(action: 'delete', type: 'file', data: {'id': id});
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _sendRequest(
      action: 'delete',
      type: 'folder',
      data: {'id': int.parse(id)},
    );
  }

  @override
  Future<void> deleteTag(String id) async {
    await _sendRequest(
      action: 'delete',
      type: 'tag',
      data: {'id': int.parse(id)},
    );
  }

  @override
  Future<List<LibraryFile>> getFiles() async {
    final result = await _sendRequest(action: 'read', type: 'file');
    return (result as List).map((json) => LibraryFile.fromMap(json)).toList();
  }

  @override
  Future<List<LibraryFile>> findFiles({Map<String, dynamic>? query}) async {
    final result = await _sendRequest(
      action: 'read',
      type: 'file',
      query: query ?? {},
    );
    return (result as List).map((json) => LibraryFile.fromMap(json)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> findFolders({
    Map<String, dynamic>? query,
  }) async {
    return await _sendRequest(
      action: 'read',
      type: 'folder',
      query: query ?? {},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> findTags({
    Map<String, dynamic>? query,
  }) async {
    return await _sendRequest(action: 'read', type: 'tag', query: query ?? {});
  }

  @override
  Future<void> updateLibrary(String id, Map<String, dynamic> updates) async {
    await _sendRequest(
      action: 'update',
      type: 'library',
      data: {'id': int.parse(id), 'data': updates},
    );
  }

  @override
  Future<void> addFileFromPath(String filePath) async {
    await _sendRequest(
      action: 'create',
      type: 'file',
      data: {'path': filePath},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getFolders() async {
    final response = await _sendRequest(action: 'read', type: 'folder');
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  @override
  Future<List<Map<String, dynamic>>> getTags() async {
    final response = await _sendRequest(action: 'read', type: 'tag');
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  @override
  Future<void> updateFolder({
    required String id,
    bool? deleted,
    String? name,
  }) async {
    final updateData = <String, dynamic>{};
    if (deleted != null) updateData['deleted'] = deleted;
    if (name != null) updateData['name'] = name;

    await _sendRequest(
      action: 'update',
      type: 'folder',
      data: {'id': id, 'data': updateData},
    );
  }

  @override
  Future<void> updateTag({
    required String id,
    bool? deleted,
    String? name,
  }) async {
    final updateData = <String, dynamic>{};
    if (deleted != null) updateData['deleted'] = deleted;
    if (name != null) updateData['name'] = name;

    await _sendRequest(
      action: 'update',
      type: 'tag',
      data: {'id': id, 'data': updateData},
    );
  }

  @override
  Future<LibraryFile> getFile(int id) async {
    final result = await _sendRequest(
      action: 'read',
      type: 'file',
      query: {'id': id},
    );
    return LibraryFile.fromMap(result);
  }

  @override
  Future<void> updateFile(int id, Map<String, dynamic> updates) async {
    await _sendRequest(
      action: 'update',
      type: 'file',
      data: {'id': id, 'data': updates},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getFileFolders(int id) async {
    final response = await _sendRequest(
      action: 'read',
      type: 'file_folder',
      query: {'id': id},
    );
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  @override
  Future<List<Map<String, dynamic>>> getFileTags(int id) async {
    final response = await _sendRequest(
      action: 'read',
      type: 'file_tag',
      query: {'id': id},
    );
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  @override
  Future<void> setFileFolders(int id, String folderId) async {
    await _sendRequest(
      action: 'update',
      type: 'file_folder',
      data: {'id': id, 'data': folderId},
    );
  }

  @override
  Future<void> setFileTags(int id, List<String> tagIds) async {
    await _sendRequest(
      action: 'update',
      type: 'file_tag',
      data: {'id': id, 'data': tagIds},
    );
  }
}
