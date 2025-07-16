import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class Md5Util {
  static Future<String> calculateFileMd5(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    // 使用try/finally确保流正确释放
    final stream = file.openRead();
    var digest = await md5.bind(stream).first;
    return digest.toString();
  }

  static String calculateStringMd5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }
}
