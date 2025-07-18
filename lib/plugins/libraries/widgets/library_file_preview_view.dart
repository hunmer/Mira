import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:video_player/video_player.dart';

class LibraryFilePreviewView extends StatefulWidget {
  final LibraryFile file;

  const LibraryFilePreviewView({required this.file, super.key});

  @override
  State<LibraryFilePreviewView> createState() => _LibraryFilePreviewViewState();
}

class _LibraryFilePreviewViewState extends State<LibraryFilePreviewView> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    fvp.registerWith();
  }

  Future<void> _initPlayer() async {
    final fileType = _getFileType(widget.file.name);
    if (fileType == 'video' || fileType == 'audio') {
      _controller = VideoPlayerController.file(File(widget.file.path!));
      await _controller.initialize();
      setState(() => _isInitialized = true);
    }
  }

  String _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'aac', 'flac'].contains(ext)) return 'audio';
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return 'image';
    if (['pdf'].contains(ext)) return 'pdf';
    return 'other';
  }

  Widget _buildPlayer() {
    final fileType = _getFileType(widget.file.name);

    switch (fileType) {
      case 'video':
        return _isInitialized
            ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
            : const Center(child: CircularProgressIndicator());
      case 'audio':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack, size: 64),
            const SizedBox(height: 16),
            _isInitialized
                ? IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                      _isPlaying ? _controller.play() : _controller.pause();
                    });
                  },
                )
                : const CircularProgressIndicator(),
          ],
        );
      case 'image':
        return InteractiveViewer(
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
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.file.name)),
      body: Center(child: _buildPlayer()),
      floatingActionButton:
          _getFileType(widget.file.name) == 'video'
              ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                    _isPlaying ? _controller.play() : _controller.pause();
                  });
                },
                child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              )
              : null,
    );
  }
}
