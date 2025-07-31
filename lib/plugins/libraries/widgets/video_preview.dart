import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPreview extends StatefulWidget {
  final String videoPath;

  const VideoPreview({required this.videoPath, super.key});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late final Player _player;
  late final VideoController _videoController;
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
    _player = Player();
    _videoController = VideoController(_player);

    _player.stream.position.listen((position) {
      setState(() => _currentPosition = position);
    });

    _player.stream.duration.listen((duration) {
      setState(() => _totalDuration = duration);
    });

    _player.stream.playing.listen((playing) {
      setState(() => _isPlaying = playing);
    });

    await _player.open(Media(widget.videoPath));
    setState(() {
      _isInitialized = true;
      _player.setVolume(_volume);
    });
  }

  @override
  void dispose() {
    _player.dispose();
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
            _player.seek(_currentPosition);
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
                  _isPlaying ? _player.pause() : _player.play();
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
                    _player.setRate(speed);
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
                  _player.setVolume(value);
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
                  ? Video(controller: _videoController)
                  : const Center(child: CircularProgressIndicator()),
        ),
        _buildControls(),
      ],
    );
  }
}
