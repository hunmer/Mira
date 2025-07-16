import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mira/core/services/tingwu_meetings_dialog.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

class TingWuService {
  // final String baseUrl = 'http://127.0.0.1:8000';
  final String baseUrl = 'http://185.242.234.93:8000';
  WebSocketChannel? _channel;
  TingWuService();

  Future<Map<String, dynamic>> createTaskRequest({
    required String sourceLanguage,
    required String fileUrl,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/CreateTaskRequestInput').replace(
        queryParameters: {
          'source_language': sourceLanguage,
          'file_url': fileUrl,
        },
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create task request');
    }
  }

  Future<Map<String, dynamic>> createLiveMeeting({
    int speakerCount = 1,
    String title = '',
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/createLiveMeeting').replace(
        queryParameters: {
          'speakerCount': speakerCount.toString(),
          'title': title,
          'creator': 'user1',
        },
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create live meeting');
  }

  Future<Map<String, dynamic>> stopLiveMeeting(String taskId) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/stopLiveMeeting',
      ).replace(queryParameters: {'taskId': taskId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to stop live meeting');
    }
  }

  Future<Map<String, dynamic>> getTaskInfo({required String taskId}) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/getTaskInfo',
      ).replace(queryParameters: {'taskId': taskId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get task info');
    }
  }

  Future<Map<String, dynamic>> getTasksInfo({required List<String> ids}) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/getTasksInfo',
      ).replace(queryParameters: {'ids': ids.join(',')}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get tasks info');
    }
  }

  Future<Map<String, dynamic>> getTaskByMd5({required String md5}) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/getTaskByMd5',
        ).replace(queryParameters: {'md5': md5}),
      );
      return jsonDecode(response.body);
    } catch (err) {
      throw Exception('Failed to get task by md5: $err');
    }
  }

  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    Function(double)? onProgress,
    int speakerCount = 1,
    String sourceLanguage = 'zh',
    String targetLanguage = 'en',
    bool chapterSummary = true,
    List<String> assistance = const [],
    List<String> summarizationList = const [],
    List<String> customPrompts = const [],
    bool polishText = true,
  }) async {
    await Future.delayed(Duration(milliseconds: 100));

    final file = File(filePath);
    final length = await file.length();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/uploadFile').replace(
        queryParameters: {
          'speakerCount': speakerCount.toString(),
          'sourceLanguage': sourceLanguage,
          'targetLanguage': targetLanguage,
          'chapterSummary': chapterSummary.toString(),
          'polishText': polishText.toString(),
          'assistance': assistance.join(','),
          'summarizationList': summarizationList.join(','),
          'customPrompts': customPrompts.join('|'),
        },
      ),
    );

    final stream = file.openRead();
    final multipartFile = http.MultipartFile(
      'file',
      stream,
      length,
      filename: file.path.split('/').last,
    );
    request.files.add(multipartFile);

    final completer = Completer<Map<String, dynamic>>();
    final response = await request.send();

    int bytesReceived = 0;
    final List<int> allBytes = [];
    DateTime? lastProgressUpdate;

    response.stream.listen(
      (List<int> chunk) {
        bytesReceived += chunk.length;
        allBytes.addAll(chunk);
        debugPrint('Upload progress: $bytesReceived/$length bytes');

        final progress = bytesReceived / length;
        final now = DateTime.now();
        if (lastProgressUpdate == null ||
            now.difference(lastProgressUpdate!) > Duration(milliseconds: 200)) {
          onProgress?.call(progress.clamp(0.0, 1.0));
          lastProgressUpdate = now;
        }
      },
      onDone: () {
        if (response.statusCode == 200) {
          final responseBody = utf8.decode(allBytes);
          completer.complete(jsonDecode(responseBody));
        } else {
          completer.completeError(
            Exception('Failed to upload file: ${response.statusCode}'),
          );
        }
      },
      onError: completer.completeError,
      cancelOnError: true,
    );

    return completer.future;
  }

  Future<void> connectWebSocket(
    String url,
    Function onRespone,
    Function onError,
    Function onDone,
  ) async {
    debugPrint(url);
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen(
      (data) {
        try {
          final decodedData = data is String ? jsonDecode(data) : data;
          if (decodedData is Map<String, dynamic>) {
            onRespone.call(decodedData);
          } else {
            throw FormatException(
              'Invalid data format: expected Map<String, dynamic>',
            );
          }
        } catch (e) {
          onError.call('Data parsing error: ${e.toString()}');
        }
      },
      onError: (error) {
        onError.call(error.toString());
      },
      onDone: () {
        onDone.call();
      },
    );

    // Send start transcription message
    _channel!.sink.add(
      jsonEncode({
        'header': {
          'name': 'StartTranscription',
          'namespace': 'SpeechTranscriber',
        },
        'payload': {'format': 'pcm'},
      }),
    );
  }

  Future<void> sendAudioData(List<int> audioBytes) async {
    if (_channel == null) {
      return;
    }

    // Send audio data in chunks of 1024 bytes
    for (var i = 0; i < audioBytes.length; i += 1024) {
      final end = i + 1024 > audioBytes.length ? audioBytes.length : i + 1024;
      final chunk = audioBytes.sublist(i, end);
      _channel!.sink.add(chunk);
    }
  }

  Future<void> disconnectWebSocket() async {
    if (_channel != null) {
      // Send stop transcription message
      _channel!.sink.add(
        jsonEncode({
          'header': {
            'name': 'StopTranscription',
            'namespace': 'SpeechTranscriber',
          },
          'payload': {},
        }),
      );

      await Future.delayed(Duration(seconds: 2));
      await _channel!.sink.close();
      _channel = null;
    }
  }

  void dispose() {
    _channel?.sink.close();
  }

  Future<Map<String, dynamic>> getLiveMeetings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getLiveMeetingsList'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to get live meetings: ${response.statusCode}');
    } catch (e) {
      debugPrint('获取会议列表失败: $e');
      rethrow;
    }
  }

  Future<bool> clearCompletedMeetings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/clearCompletedMeetings'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      throw Exception(
        'Failed to clear completed meetings: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('清空已完成会议失败: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> showListMeetingsDialog(
    BuildContext context,
  ) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => TingWuMeetingsDialog(
            service: this,
            onConfirm: (selectedMeeting) {},
          ),
    );
  }
}
