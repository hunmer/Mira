import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'library_data_interface.dart';

class LibraryDataWebSocket implements LibraryDataInterface {
  final WebSocketChannel _channel;
  final Map<String, Completer<dynamic>> _responseHandlers = {};
  static int _requestCounter = 0;

  void _sendMessage(dynamic message) {
    final jsonMessage = jsonEncode(message);
    debugPrint('Sending WebSocket message: $jsonMessage');
    _channel.sink.add(jsonMessage);
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
    return 'req_${_requestCounter++}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _waitForResponse(String operation) async {
    final completer = Completer<void>();
    final requestId = _generateRequestId();
    _responseHandlers[requestId] = completer;
    return completer.future;
  }

  void _handleResponse(dynamic message) {
    try {
      debugPrint('Received WebSocket message: $message');
      final response = jsonDecode(message);
      if (response.containsKey('requestId') &&
          _responseHandlers.containsKey(response['requestId'])) {
        final completer = _responseHandlers.remove(response['requestId']);
        if (response['status'] == 'success') {
          completer?.complete(response['data']);
        } else {
          completer?.completeError(Exception(response['message']));
        }
      }
    } catch (e) {
      print('Error handling response: $e');
    }
  }

  @override
  Future<void> addLibrary(Map<String, dynamic> library) async {
    _sendMessage({
      'action': 'create',
      'payload': {'type': 'library', 'data': library},
    });
    await _waitForResponse('add_library');
  }

  @override
  Future<void> deleteLibrary(String id) async {
    _sendMessage({
      'action': 'delete',
      'payload': {'type': 'library', 'id': int.parse(id)},
    });
    await _waitForResponse('delete_library');
  }

  @override
  Future<List<Map<String, dynamic>>> findLibraries({
    Map<String, dynamic>? query,
  }) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    final requestId = _generateRequestId();
    _responseHandlers[requestId] = completer;

    _sendMessage({
      'action': 'read',
      'payload': {'type': 'library', 'query': query ?? {}},
    });

    return await completer.future;
  }

  @override
  void close() {
    _channel.sink.close();
  }

  @override
  Future<void> addFile(Map<String, dynamic> file) async {
    _sendMessage({
      'action': 'create',
      'payload': {'type': 'file', 'data': file},
    });
    await _waitForResponse('add_file');
  }

  @override
  Future<void> addFolder(Map<String, dynamic> folder) async {
    _sendMessage({
      'action': 'create',
      'payload': {'type': 'folder', 'data': folder},
    });
    await _waitForResponse('add_folder');
  }

  @override
  Future<void> addTag(Map<String, dynamic> tag) async {
    _sendMessage({
      'action': 'create',
      'payload': {'type': 'tag', 'data': tag},
    });
    await _waitForResponse('add_tag');
  }

  @override
  Future<void> deleteFile(String id) async {
    _sendMessage({
      'action': 'delete',
      'payload': {'type': 'file', 'id': int.parse(id)},
    });
    await _waitForResponse('delete_file');
  }

  @override
  Future<void> deleteFolder(String id) async {
    _sendMessage({
      'action': 'delete',
      'payload': {'type': 'folder', 'id': int.parse(id)},
    });
    await _waitForResponse('delete_folder');
  }

  @override
  Future<void> deleteTag(String id) async {
    _sendMessage({
      'action': 'delete',
      'payload': {'type': 'tag', 'id': int.parse(id)},
    });
    await _waitForResponse('delete_tag');
  }

  @override
  Future<List<Map<String, dynamic>>> findFiles({
    Map<String, dynamic>? query,
  }) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    final requestId = _generateRequestId();
    _responseHandlers[requestId] = completer;

    _sendMessage({
      'action': 'read',
      'payload': {'type': 'file', 'query': query ?? {}},
    });

    return await completer.future;
  }

  @override
  Future<List<Map<String, dynamic>>> findFolders({
    Map<String, dynamic>? query,
  }) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    final requestId = _generateRequestId();
    _responseHandlers[requestId] = completer;

    _sendMessage({
      'action': 'read',
      'payload': {'type': 'folder', 'query': query ?? {}},
    });

    return await completer.future;
  }

  @override
  Future<List<Map<String, dynamic>>> findTags({
    Map<String, dynamic>? query,
  }) async {
    final completer = Completer<List<Map<String, dynamic>>>();
    final requestId = _generateRequestId();
    _responseHandlers[requestId] = completer;

    _sendMessage({
      'action': 'read',
      'payload': {'type': 'tag', 'query': query ?? {}},
    });

    return await completer.future;
  }

  @override
  Future<void> updateLibrary(String id, Map<String, dynamic> updates) async {
    _sendMessage({
      'action': 'update',
      'payload': {'type': 'library', 'id': int.parse(id), 'data': updates},
    });
    await _waitForResponse('update_library');
  }

  @override
  Future<void> addFileFromPath(String filePath) async {
    _sendMessage({
      'action': 'create',
      'payload': {
        'type': 'file',
        'data': {'path': filePath},
      },
    });
    await _waitForResponse('add_file');
  }

  @override
  Future<List<LibraryFile>> getFiles() async {
    final completer = Completer<List<Map<String, dynamic>>>();
    final requestId = _generateRequestId();
    _responseHandlers[requestId] = completer;

    _sendMessage({
      'action': 'read',
      'payload': {'type': 'file', 'query': {}},
    });

    try {
      // 临时解决方案：同步等待异步操作
      // 注意：这不是最佳实践，但在WebSocket场景下是必要的
      final files = await completer.future.timeout(Duration(seconds: 5));
      return files.map((file) => LibraryFile.fromMap(file)).toList();
    } catch (e) {
      print('Error getting files: $e');
      return [];
    }
  }
}
