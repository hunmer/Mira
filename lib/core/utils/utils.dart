// 电话号码正则验证
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

bool isValidPhoneNumber(String phone) {
  final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
  return phoneRegex.hasMatch(phone);
}

String filePathToUri(String windowsPath) {
  // 替换反斜杠为正斜杠
  String uriPath = windowsPath.replaceAll(r'\', '/');
  // 确保路径以file://开头
  if (!uriPath.startsWith('file://')) {
    uriPath = 'file:///$uriPath';
  }
  return uriPath;
}

String formatFileSize(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
}

// getFileName
String getFileName(String path, [bool extName = false]) {
  if (path.isEmpty) return '';
  path = path.replaceAll('\\', '/');
  var index = path.lastIndexOf('/');
  index = index == -1 ? 0 : index + 1;
  return extName
      ? path.substring(index)
      : path.substring(index, path.lastIndexOf('.'));
}

Widget buildImageFromUrl(String url) {
  return url.startsWith('http')
      ? Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) =>
                Icon(Icons.insert_drive_file, size: 48),
      )
      : Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) =>
                Icon(Icons.insert_drive_file, size: 48),
      );
}

String getFileType(String filename) {
  final extension = filename.split('.').last.toLowerCase();
  switch (extension) {
    case 'mp4':
    case 'mov':
    case 'avi':
    case 'mkv':
    case 'flv':
      return 'video';
    case 'mp3':
    case 'wav':
    case 'aac':
    case 'flac':
    case 'ogg':
      return 'audio';
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'bmp':
      return 'image';
    case 'pdf':
    case 'doc':
    case 'docx':
    case 'xls':
    case 'xlsx':
    case 'ppt':
    case 'pptx':
      return 'document';
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return 'archive';
    default:
      return 'other';
  }
}
