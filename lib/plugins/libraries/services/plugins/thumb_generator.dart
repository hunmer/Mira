import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:mira/plugins/libraries/services/websocket_server.dart';
import 'package:mira/plugins/libraries/services/interface/library_server_data_interface.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
// ignore: depend_on_referenced_packages
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbGenerator {
  // ignore: unused_field
  final WebSocketServer _server;
  final LibraryServerDataInterface _dbService;

  ThumbGenerator(this._server, this._dbService) {
    // 注册事件监听
    _dbService.getEventManager().subscribe('file::created', _onFileCreated);
    _dbService.getEventManager().subscribe('file::deleted', _onFileDeleted);
  }

  Future<void> _onFileCreated(EventArgs args) async {
    if (args is! ServerEventArgs) return;

    try {
      final item = args.item['result'];
      final path = item['path'];

      final fileType = _getFileType(path);
      if (fileType == null) return;

      final thumbPath = await _dbService.getItemThumbPath(item);
      final thumbFile = File(thumbPath);

      if (!thumbFile.parent.existsSync()) {
        thumbFile.parent.createSync(recursive: true);
      }

      switch (fileType) {
        case FileType.image:
          await _generateImageThumbnail(path, thumbPath);
          break;
        case FileType.video:
          await _generateVideoThumbnail(path, thumbPath);
          break;
      }

      item['thumbPath'] = thumbPath;
      // 更新数据库中的thumb字段
      await _dbService.updateFile(item['id'], {'thumb': 1});
      // 通知客户端缩略图已生成
      _dbService.getEventManager().broadcastToClients(
        'thumbnail::generated',
        args,
      );
    } catch (e) {
      debugPrint('Failed to generate thumbnail: $e');
    }
  }

  Future<void> _onFileDeleted(EventArgs args) async {
    if (args is! ServerEventArgs) return;

    try {
      final thumbPath = path.join(
        await _dbService.getItemPath(args.item),
        'preview.png',
      );
      final thumbFile = File(thumbPath);

      if (thumbFile.existsSync()) {
        thumbFile.deleteSync();
      }
      // 更新数据库中的thumb字段
      await _dbService.updateFile(args.item['id'], {'thumb': 0});
    } catch (e) {
      debugPrint('Failed to delete thumbnail: $e');
    }
  }

  Future<void> _generateImageThumbnail(String srcPath, String destPath) async {
    try {
      final bytes = await File(srcPath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return;

      // 缩放到最大200px宽或高
      final thumbnail = img.copyResize(image, width: 200, height: 200);
      await File(destPath).writeAsBytes(img.encodePng(thumbnail));
    } catch (e) {
      debugPrint('Image thumbnail generation error: $e');
    }
  }

  Future<void> _generateVideoThumbnail(String srcPath, String destPath) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final thumbnail = await VideoThumbnail.thumbnailFile(
          video: srcPath,
          thumbnailPath: destPath,
          imageFormat: ImageFormat.PNG,
          maxWidth: 200,
          quality: 75,
        );

        if (thumbnail == null) {
          debugPrint('Failed to generate video thumbnail');
        }
      } else {
        // 桌面端使用ffmpeg生成缩略图
        final process = await Process.run('ffmpeg', [
          '-i',
          srcPath,
          '-ss',
          '00:00:01',
          '-vframes',
          '1',
          '-vf',
          'scale=200:-1',
          destPath,
        ]);

        if (process.exitCode != 0) {
          debugPrint(
            'Failed to generate video thumbnail with ffmpeg: ${process.stderr}',
          );
        }
      }
    } catch (e) {
      debugPrint('Video thumbnail generation error: $e');
    }
  }

  FileType? _getFileType(String path) {
    final ext = path.split('.').last.toLowerCase();
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'flv', 'webm'];

    if (imageExtensions.contains(ext)) return FileType.image;
    if (videoExtensions.contains(ext)) return FileType.video;
    return null;
  }
}

enum FileType { image, video }
