import 'dart:io';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player/video_player.dart';

class VideoPreview extends StatefulWidget {
  final String videoPath;

  const VideoPreview({required this.videoPath, super.key});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _controller = VideoPlayerController.file(
      File(widget.videoPath.replaceAll('//', '\\\\')),
    )..addListener(() {
      if (_controller.value.isInitialized) {
        setState(() {
          _currentPosition = _controller.value.position;
          _totalDuration = _controller.value.duration;
        });
      }
    });

    await _controller.initialize();
    setState(() {
      _isInitialized = true;
      _controller.setVolume(_volume);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildControls() {
    return Column(
      children: [
        // 进度条
        Slider(
          value: _currentPosition.inMilliseconds.toDouble(),
          min: 0,
          max: _totalDuration.inMilliseconds.toDouble(),
          onChanged: (value) {
            setState(() {
              _currentPosition = Duration(milliseconds: value.toInt());
            });
            _controller.seekTo(_currentPosition);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 播放/暂停按钮
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                setState(() {
                  _isPlaying = !_isPlaying;
                  _isPlaying ? _controller.play() : _controller.pause();
                });
              },
            ),
            // 倍速调节
            DropdownButton<double>(
              value: _playbackSpeed,
              items:
                  [0.5, 1.0, 1.5, 2.0].map((speed) {
                    return DropdownMenuItem<double>(
                      value: speed,
                      child: Text('${speed}x'),
                    );
                  }).toList(),
              onChanged: (speed) {
                if (speed != null) {
                  setState(() {
                    _playbackSpeed = speed;
                    _controller.setPlaybackSpeed(speed);
                  });
                }
              },
            ),
            // 音量调节
            Slider(
              value: _volume,
              min: 0,
              max: 1,
              onChanged: (value) {
                setState(() {
                  _volume = value;
                  _controller.setVolume(value);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child:
              _isInitialized
                  ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                  : const Center(child: CircularProgressIndicator()),
        ),
        _buildControls(),
      ],
    );
  }
}
