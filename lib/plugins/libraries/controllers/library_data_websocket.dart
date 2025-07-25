import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mira/core/event/event.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'library_data_interface.dart';

enum LibraryStatus { open, closed, error, connected }

class LibraryDataWebSocket implements LibraryDataInterface {
  final StreamController<LibraryStatus> _event =
      StreamController<LibraryStatus>.broadcast();

  LibraryDataWebSocket(this.library) {
    connect();
    channel.stream.listen(
      _handleResponse,
      onError: (error) {
        _event.add(LibraryStatus.error);
        print('连接出错: $error');
        reconnect();
      },
      onDone: () {
        _event.add(LibraryStatus.closed);
        print('连接已关闭');
        reconnect();
      },
    );
  }

  void connect() {
    channel = WebSocketChannel.connect(Uri.parse(library.url));
  }

  void reconnect() {
    print('重新连接');
    connect();
  }

  final Library library;
  late final WebSocketChannel channel;
  final Map<String, Completer<dynamic>> _responseHandlers = {};
  final LibrariesPlugin _plugin =
      PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
  Future<dynamic> _sendRequest({
    required String action,
    required String type,
    dynamic data,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final requestId = _generateRequestId();
    final completer = Completer<dynamic>();
    _responseHandlers[requestId] = completer;

    final message = {
      'action': action,
      'requestId': requestId,
      'libraryId': library.id,
      'payload': {'type': type, 'data': data ?? {}},
    };

    channel.sink.add(jsonEncode(message));
    debugPrint('Sending WebSocket message: ${jsonEncode(message)}');

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          _responseHandlers.remove(requestId);
          completer.completeError(
            TimeoutException(
              '$action request timed out after ${timeout.inSeconds} seconds',
            ),
          );
          throw TimeoutException(
            '$action request timed out after ${timeout.inSeconds} seconds',
          );
        },
      );
    } catch (e) {
      _responseHandlers.remove(requestId);
      if (e is TimeoutException) {
        debugPrint('WebSocket request timeout: ${e.toString()}');
      } else {
        debugPrint('WebSocket request error: ${e.toString()}');
      }
      rethrow;
    }
  }

  @override
  void checkConnection() {
    // 发送给服务端，需要保证library已经加载
    // 服务端会返回connected消息并且被客户端获取，所有这里不需要获取结果
    _sendRequest(
      action: 'open',
      type: 'library',
      data: {'library': library.toJson()},
    );
  }

  String _generateRequestId() {
    return Uuid().v4();
  }

  void _handleResponse(dynamic message) {
    _event.add(LibraryStatus.open);
    try {
      debugPrint('Received WebSocket message: $message');
      final response = jsonDecode(message);

      if (response.containsKey('requestId')) {
        // 返回给函数的响应结果
        if (_responseHandlers.containsKey(response['requestId'])) {
          final completer = _responseHandlers.remove(response['requestId']);
          if (response['status'] == 'success') {
            completer?.complete(response['data']);
          } else {
            completer?.completeError(Exception(response['message']));
          }
        }
      } else {
        final status = response['status'];
        if (status == 'error') {
          // response['msg'];
          return;
        }

        final eventName = response['eventName'];
        final data = response['data'];
        final id = data['id'];
        final libraryId = data['libraryId'];
        switch (eventName) {
          case 'connected': // 初次连接
            print('连接成功');
            _event.add(LibraryStatus.connected);
            EventManager.instance.broadcast(
              'library::connected',
              MapEventArgs({
                'libraryId': libraryId,
                'tags': data['tags'],
                'folders': data['folders'],
              }),
            );
            EventManager.instance.broadcast(
              'tags::update',
              MapEventArgs({'libraryId': libraryId, 'tags': data['tags']}),
            );
            EventManager.instance.broadcast(
              'folders::update',
              MapEventArgs({
                'libraryId': libraryId,
                'folders': data['folders'],
              }),
            );
            break;
          case 'tag::created': // 标签创建
          case 'tag::delete': // 标签删除
          case 'tag::updated': // 标签更新
            EventManager.instance.broadcast(
              'tags::updated',
              MapEventArgs({'libraryId': libraryId, 'tags': data['tags']}),
            );
            break;
          case 'folder::updated': // 文件夹创建
          case 'folder::created': // 文件夹创建
          case 'folder::deleted': // 文件夹删除
            EventManager.instance.broadcast(
              'folder::updated',
              MapEventArgs({
                'libraryId': libraryId,
                'folders': data['folders'],
              }),
            );
          case 'thumbnail::generated': // 文件生成缩略图
          case 'file::uploaded': // 文件上传结果
            EventManager.instance.broadcast(eventName, MapEventArgs(data));
            break;

          case 'file::created': // 文件添加
          case 'file::deleted': // 文件删除
          case 'file::folder': // 设置文件文件夹
          case 'file::tags': // 设置文件标签
            EventManager.instance.broadcast(
              'file::changed',
              MapEventArgs({
                ...data,
                ...{'type': eventName.split('::').last},
              }),
            );
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
      data: query ?? {},
    );
  }

  @override
  void close() {
    channel.sink.close();
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
  Future<void> deleteFile(int id, {bool moveToRecycleBin = false}) async {
    await _sendRequest(
      action: 'delete',
      type: 'file',
      data: {'id': id, 'moveToRecycleBin': moveToRecycleBin},
    );
  }

  @override
  Future<void> recoverFile(int id) async {
    await _sendRequest(action: 'recover', type: 'file', data: {'id': id});
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
  Future<dynamic> findFiles({Map<String, dynamic>? query}) async {
    try {
      final result = await _sendRequest(
        action: 'read',
        type: 'file',
        data: {'query': query ?? {}},
      );
      if (result == null || result['result'] == null) {
        return {'result': [], 'total': 0, 'offset': 0, 'limit': 0};
      }
      return {
        'result':
            (result['result'] as List)
                .map((json) => LibraryFile.fromMap(json))
                .toList(),
        'total': result['total'] as int? ?? 0,
        'offset': result['offset'] as int? ?? 0,
        'limit': result['limit'] as int? ?? 0,
      };
    } catch (e) {
      debugPrint('Error in findFiles: ${e.toString()}');
      return {'result': [], 'total': 0, 'offset': 0, 'limit': 0};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> findFolders({
    Map<String, dynamic>? query,
  }) async {
    return await _sendRequest(
      action: 'read',
      type: 'folder',
      data: query ?? {},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> findTags({
    Map<String, dynamic>? query,
  }) async {
    return await _sendRequest(action: 'read', type: 'tag', data: query ?? {});
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
  Future<List<Map<String, dynamic>>> getAllFolders() async {
    final response = await _sendRequest(action: 'all', type: 'folder');
    return List<Map<String, dynamic>>.from(response['folders']);
  }

  @override
  Future<List<Map<String, dynamic>>> getTags() async {
    final response = await _sendRequest(action: 'read', type: 'tag');
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  @override
  Future<List<Map<String, dynamic>>> getAllTags() async {
    final response = await _sendRequest(action: 'all', type: 'tag');
    return List<Map<String, dynamic>>.from(response['tags']);
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
  // ignore: override_on_non_overriding_member
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
      data: {'id': id},
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
      data: {'id': id},
    );
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  @override
  Future<List<Map<String, dynamic>>> getFileTags(int id) async {
    final response = await _sendRequest(
      action: 'read',
      type: 'file_tag',
      data: {'id': id},
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

  @override
  Future<String> getFolderTitle(String folderId) async {
    // 使用缓存读取
    return await _plugin.foldersTagsController.getFolderTitleById(
      library.id,
      folderId,
    );
  }

  @override
  Future<String> getTagTitle(String tagId) async {
    // 使用缓存读取
    return await _plugin.foldersTagsController.getTagTitleById(
      library.id,
      tagId,
    );
  }
}
