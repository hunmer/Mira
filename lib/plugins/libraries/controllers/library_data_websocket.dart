import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mira/core/event/event_args.dart';
import 'package:mira/core/event/event_manager.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/core/storage/storage_manager.dart';
import 'package:mira/main.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/widgets/webview_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'library_data_interface.dart';

enum LibraryStatus { open, closed, error, connected }

class LibraryDataWebSocket implements LibraryDataInterface {
  final Library library;
  final String clientId = const Uuid().v4();
  final StreamController<LibraryStatus> _event =
      StreamController<LibraryStatus>.broadcast();
  final StorageManager storage;
  late WebSocketChannel channel;
  final Map<String, Completer<dynamic>> _responseHandlers = {};
  late List<Map<String, dynamic>> _requiredFields = const [];
  late Map<String, dynamic> _fieldsData;
  late StreamSubscription _streamSubscription;
  final LibrariesPlugin _plugin =
      PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
  bool _isDialogShown = false;
  bool isConnecting = false;

  LibraryDataWebSocket(this.storage, this.library) {
    channel = createChannel();
  }

  WebSocketChannel createChannel() {
    print('开始连接');
    final newChannel = WebSocketChannel.connect(
      Uri.parse('${library.url}?clientId=$clientId&libraryId=${library.id}'),
    );
    _streamSubscription = newChannel.stream.listen(
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
    return newChannel;
  }

  void reconnect() {
    print('尝试重新连接');
    isConnecting = false;
    if (channel != null) {
      channel.sink.close();
      _streamSubscription.cancel();
    }
    Future.delayed(const Duration(seconds: 3), () {
      channel = createChannel();
      checkConnection(); // 重连需要重新确定服务器状态
    });
  }

  Future<dynamic> _sendRequest({
    required String action,
    required String type,
    dynamic data,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final libraryId = library.id;
    final requestId = _generateRequestId();
    final completer = Completer<dynamic>();
    _responseHandlers[requestId] = completer;

    final message = {
      'action': action,
      'clientId': clientId,
      'requestId': requestId,
      'libraryId': libraryId,
      'fields': await getLibraryFieldValues(action, type),
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

  Future<Map<String, dynamic>> getLibraryFieldValues(
    String action,
    String type,
  ) async {
    final fieldValues = <String, dynamic>{};
    for (final item in _requiredFields.where(
      (item) => item['action'] == action && item['type'] == type,
    )) {
      final field = item['field'];
      fieldValues[field] = getFieldValue(field);
    }
    return fieldValues;
  }

  @override
  Future<Map<String, dynamic>> loadFields() async {
    try {
      final result = await storage.readJson('library_fields/${library.id}', {});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      debugPrint('Error loading fields: $e');
      return {};
    }
  }

  @override
  dynamic getFieldValue(String field, [dynamic defaultVal]) {
    return _fieldsData.containsKey(field) ? _fieldsData[field] : defaultVal;
  }

  @override
  Future<dynamic> setFieldValues(Map<String, dynamic> fields) async {
    for (final field in fields.entries) {
      _fieldsData[field.key] = field.value;
    }
    await storage.writeJson('library_fields/${library.id}', _fieldsData);
  }

  Stream<LibraryStatus> get status => _event.stream;

  @override
  Future<void> checkConnection() async {
    // 发送给服务端，需要保证library已经加载
    // 服务端会返回connected消息并且被客户端获取，所有这里不需要获取结果
    // if (!isConnecting) { // 热重载不会重置isConnecting=false
    print('尝试连接');
    _fieldsData = await loadFields();
    await _sendRequest(
      action: 'open',
      type: 'library',
      data: {'library': library.toJson()},
    );
    // }
  }

  String _generateRequestId() {
    return Uuid().v4();
  }

  Future<void> _handleResponse(dynamic message) async {
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
        final libraryId = data?['libraryId'];
        switch (eventName) {
          case 'setFields':
            setFieldValues(Map<String, dynamic>.from(data['fields']));
            break;
          case 'dialog':
            // TODO WebViewDialog持久化，当再次收到url地址时，检查是否已经被打开，没有的话则打开新窗口页
            if (navigatorKey.currentContext != null && !_isDialogShown) {
              _isDialogShown = true;
              showDialog(
                context: navigatorKey.currentContext!,
                builder:
                    (context) => WebViewDialog(
                      title: data['title'],
                      message: data['message'],
                      url: data['url'],
                    ),
              ).then((_) {
                _isDialogShown = false;
              });
            }
            return;
          case 'try_connect': // 尝试连接
            print('连接收到服务器消息');
            _requiredFields = List<Map<String, dynamic>>.from(data['fields']);
            _sendRequest(action: 'connect', type: 'library');
            break;
          case 'connected': // 初次连接
            print('连接成功');
            isConnecting = true;
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
          case 'file::recovered': // 文件恢复结果
          case 'file::setTag': // 设置文件标签
          case 'file::setFolder': // 设置文件文件夹
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
  Future<void> addFile(
    Map<String, dynamic> file,
    Map<String, dynamic> metaData,
  ) async {
    await _sendRequest(
      action: 'create',
      type: 'file',
      data: {...metaData, ...file},
    );
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
    return (result as List).map((json) => convertLibraryFile(json)).toList();
  }

  LibraryFile convertLibraryFile(Map<String, dynamic> json) {
    return LibraryFile.fromMap({
      ...json,
      ...{
        'path': convertRelatvePath(json['path']),
        'thumb': convertRelatvePath(json['thumb']),
      },
    });
  }

  String convertRelatvePath(String filePath) {
    final relativePath = library.customFields['relativePath'];
    if (relativePath != null &&
        relativePath.isNotEmpty &&
        filePath.startsWith(relativePath)) {
      return filePath.replaceFirst(
        relativePath,
        library.customFields['smbPath'],
      );
    }
    return filePath;
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
                .map((json) => convertLibraryFile(json))
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
  Future<void> addFileFromPath(
    String filePath,
    Map<String, dynamic> metaData,
  ) async {
    await _sendRequest(
      action: 'create',
      type: 'file',
      data: {
        ...metaData,
        ...{'path': filePath},
      },
    );
  }

  @override
  Future<Map<String, dynamic>> uploadFile(
    String filePath,
    Map<String, dynamic> metaData,
  ) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return {
        'success': false,
        'message': 'File does not exist',
        'filePath': filePath,
      };
    }
    final uploadUrl = '${library.getHttpServer}/api/libraries/upload';
    try {
      final action = 'create';
      final type = 'file';
      final task = UploadTask.fromFile(
        file: file,
        url: uploadUrl,
        fileField: 'files', // 服务器接收文件的字段名
        fields: {
          // 模拟ws上传操作，方便其他插件正常处理
          'sourcePath': filePath, // 用于回调检测是否上传成功
          'libraryId': library.id,
          'clientId': clientId,
          'action': action,
          'fields': jsonEncode(await getLibraryFieldValues(action, type)),
          'payload': jsonEncode({
            'type': type,
            'data': {...metaData, 'filePath': filePath},
          }),
        }, // query字段
        updates: Updates.statusAndProgress,
      );
      final result = await LibrariesPlugin.instance.fileDownloader.upload(task);
      if (result.status == TaskStatus.complete) {
        return {
          'success': true,
          'data':
              result.responseBody != null
                  ? jsonDecode(result.responseBody!)
                  : {'status': 'success'},
          'filePath': filePath,
        };
      } else {
        return {
          'success': false,
          'message':
              'Upload failed: ${result.exception?.toString() ?? 'Unknown error'}',
          'filePath': filePath,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'filePath': filePath};
    }
  }

  /// Upload file from bytes data (for web platform)
  Future<Map<String, dynamic>> uploadFileBytes(
    Map<String, dynamic> fileData,
    Map<String, dynamic> metaData,
  ) async {
    if (!kIsWeb) {
      // On native platforms, fallback to regular file upload if possible
      return {
        'success': false,
        'message': 'uploadFileBytes is only supported on web platform',
      };
    }

    final uploadUrl = '${library.getHttpServer}/api/libraries/upload';
    try {
      final action = 'create';
      final type = 'file';
      final fileName = fileData['name'] as String;
      final bytes = fileData['bytes'] as Uint8List;

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Add the file as bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'files', // 服务器接收文件的字段名
          bytes,
          filename: fileName,
        ),
      );

      // Add form fields (same as in uploadFile method)
      request.fields.addAll({
        'sourcePath': fileName, // 用于回调检测是否上传成功
        'libraryId': library.id,
        'clientId': clientId,
        'action': action,
        'fields': jsonEncode(await getLibraryFieldValues(action, type)),
        'payload': jsonEncode({
          'type': type,
          'data': {...metaData, 'filePath': fileName, 'fileName': fileName},
        }),
      });

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData =
            response.body.isNotEmpty
                ? jsonDecode(response.body)
                : {'status': 'success'};

        return {'success': true, 'data': responseData, 'filePath': fileName};
      } else {
        return {
          'success': false,
          'message': 'Upload failed with status code: ${response.statusCode}',
          'filePath': fileName,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'filePath': fileData['name'],
      };
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllFolders() async {
    final response = await _sendRequest(action: 'all', type: 'folder');
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllTags() async {
    final response = await _sendRequest(action: 'all', type: 'tag');
    return List<Map<String, dynamic>>.from(response);
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
    return convertLibraryFile(result);
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
      action: 'file_get',
      type: 'folder',
      data: {'fileId': id},
    );
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  @override
  Future<List<Map<String, dynamic>>> getFileTags(int id) async {
    final response = await _sendRequest(
      action: 'file_get',
      type: 'tag',
      data: {'fileId': id},
    );
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  @override
  Future<void> setFileFolders(int id, String folderId) async {
    await _sendRequest(
      action: 'file_set',
      type: 'folder',
      data: {'fileId': id, 'folder': folderId},
    );
  }

  @override
  Future<void> setFileTags(int id, List<String> tagIds) async {
    await _sendRequest(
      action: 'file_set',
      type: 'tag',
      data: {'fileId': id, 'tags': tagIds},
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
