import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
// 移除 video_player 相关依赖，使用 media_kit

class LibraryFilePreviewView extends StatefulWidget {
  final LibraryFile file;
  final Library library;
  final LibrariesPlugin plugin;

  const LibraryFilePreviewView({
    required this.file,
    required this.library,
    required this.plugin,
    super.key,
  });

  @override
  State<LibraryFilePreviewView> createState() => _LibraryFilePreviewViewState();
}

class _LibraryFilePreviewViewState extends State<LibraryFilePreviewView> {
  Player? _player;
  VideoController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final fileType = _getFileType(widget.file.name);
    if (fileType == 'video' || fileType == 'audio') {
      _player = Player();
      await _player!.open(Media(widget.file.path!));
      if (fileType == 'video') {
        _videoController = VideoController(_player!);
      }
      setState(() => _isInitialized = true);
    }
  }

  String _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'aac', 'flac'].contains(ext)) return 'audio';
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['pdf'].contains(ext)) return 'pdf';
    return 'other';
  }

  Widget _buildPlayer() {
    final fileType = _getFileType(widget.file.name);

    switch (fileType) {
      case 'video':
        return _isInitialized && _videoController != null
            ? AspectRatio(
              aspectRatio: 16 / 9,
              child: Video(controller: _videoController!),
            )
            : const Center(child: CircularProgressIndicator());
      case 'audio':
        return _isInitialized && _player != null
            ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.audiotrack, size: 64),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => _player!.play(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.pause),
                      onPressed: () => _player!.pause(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: () => _player!.stop(),
                    ),
                  ],
                ),
              ],
            )
            : const Center(child: CircularProgressIndicator());
      case 'image':
        return InteractiveViewer(
          maxScale: 5.0,
          minScale: 0.5,
          boundaryMargin: EdgeInsets.all(20),
          child:
              widget.file.path!.startsWith('http')
                  ? Image.network(widget.file.path!)
                  : Image.file(File(widget.file.path!)),
        );
      case 'pdf':
        return const Center(child: Text('PDF预览将在未来版本支持'));
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insert_drive_file, size: 64),
              const SizedBox(height: 16),
              Text('不支持预览此文件类型'),
            ],
          ),
        );
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.file.path!);
    final fileExists = file.existsSync();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder:
                    (context) => LibraryFileInformationView(
                      plugin: widget.plugin,
                      library: widget.library,
                      file: widget.file,
                    ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              if (fileExists) {
                await Share.shareUri(file.uri);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('文件不存在，无法分享')));
              }
            },
          ),
        ],
      ),
      body: Center(child: _buildPlayer()),
    );
  }
}
