// Stub implementation for video_thumbnail package for web compatibility
import 'dart:typed_data';

/// Stub implementation of VideoThumbnail class for web
class VideoThumbnail {
  /// Generate a thumbnail file from a video (stub implementation for web)
  static Future<String?> thumbnailFile({
    required String video,
    required String thumbnailPath,
    required ImageFormat imageFormat,
    int maxWidth = 0,
    int maxHeight = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    // Stub implementation for web - returns null since video thumbnail generation
    // is not supported on web platform
    return null;
  }

  /// Generate thumbnail data from a video (stub implementation for web)
  static Future<Uint8List?> thumbnailData({
    required String video,
    required ImageFormat imageFormat,
    int maxWidth = 0,
    int maxHeight = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    // Stub implementation for web - returns null since video thumbnail generation
    // is not supported on web platform
    return null;
  }
}

/// Stub implementation of ImageFormat enum for web
// ignore: constant_identifier_names
enum ImageFormat { JPEG, PNG, WEBP }
