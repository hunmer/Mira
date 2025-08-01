import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/widgets/icon_chip.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:path/path.dart' as path;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player/video_player.dart';
import 'package:rxdart/rxdart.dart';

// Conditional imports for web compatibility
import 'dart:io' show File if (dart.library.html) 'dart:html';

class LibraryItem extends StatefulWidget {
  const LibraryItem({
    required this.file,
    this.isSelected = false,
    this.useThumbnail = false,
    required this.getFolderTitle,
    required this.getTagTilte,
    this.onTap,
    this.onDoubleTap,
    required this.onLongPress,
    required this.displayFields,
    super.key,
  });

  final LibraryFile file;
  final bool isSelected;
  final bool useThumbnail;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Function(dynamic) onLongPress;
  final Future<String> Function(String) getFolderTitle;
  final Future<String> Function(String) getTagTilte;
  final Set<String> displayFields;

  @override
  State<LibraryItem> createState() => _LibraryItemState();
}

class _LibraryItemState extends State<LibraryItem> {
  VideoPlayerController? _videoController;
  bool _isHovering = false;
  bool _isVideoReady = false;
  Timer? _hoverTimer;
  bool _isLoadError = false;
  double _volume = 0;
  final GlobalKey _mouseRegionKey = GlobalKey();

  Widget _buildFileIcon() {
    if (_isHovering) {
      if (_isLoadError) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 36),
              SizedBox(height: 8),
              Text('加载失败', style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
        );
      }
      if (!_isVideoReady || _videoController == null) {
        return const Center(child: CircularProgressIndicator());
      } else {
        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _volume = _volume == 0 ? 1 : 0;
                    _videoController?.setVolume(_volume);
                  });
                },
                child: Icon(
                  _volume == 0 ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              padding: const EdgeInsets.all(2),
            ),
          ],
        );
      }
    } else {
      return widget.useThumbnail && widget.file.thumb != null
          ? buildImageFromUrl(widget.file.thumb!)
          : Icon(Icons.insert_drive_file, size: 48);
    }
  }

  Widget _buildFileInfo(BuildContext context, bool isCompact) {
    if (isCompact) return const SizedBox.shrink();
    final file = widget.file;
    final displayFields = widget.displayFields;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayFields.contains('title'))
            Text(
              path.basenameWithoutExtension(file.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (displayFields.contains('notes') && file.notes != null)
            Text(
              file.notes!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (displayFields.contains('createdAt'))
            Text(
              '创建: ${file.createdAt.toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (displayFields.contains('size'))
            Text(
              '大小: ${formatFileSize(file.size)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _buildFileTags(String folderTitle, List<String> tagTitles) {
    final displayFields = widget.displayFields;
    if (!displayFields.any(
      (field) => ['rating', 'folder', 'tags'].contains(field),
    )) {
      return const SizedBox.shrink();
    }
    final file = widget.file;
    return Wrap(
      spacing: 4,
      children: [
        if (displayFields.contains('rating') &&
            file.rating != null &&
            file.rating! > 0)
          IconChip(
            icon: Icons.star,
            label: '${file.rating}/5',
            iconColor: Colors.amber,
          ),
        if (displayFields.contains('folder') && folderTitle.isNotEmpty)
          IconChip(icon: Icons.folder, label: folderTitle),
        if (displayFields.contains('tags') && file.tags.isNotEmpty)
          ...tagTitles
              .where((t) => t.isNotEmpty)
              .map((tag) => IconChip(icon: Icons.label, label: tag)),
      ],
    );
  }

  Widget _buildFileExtensionBadge() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, size: 14, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              path.extension(widget.file.name).toUpperCase(),
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedIndicator() {
    if (!widget.isSelected) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _hoverTimer?.cancel();
    _positionSubscription?.cancel();
    _positionSubject.close();
    super.dispose();
  }

  void closeVideo() {
    setState(() {
      _isHovering = false;
      _isVideoReady = false;
      _videoController?.dispose();
      _videoController = null;
    });
  }

  Future<void> _initializeVideo() async {
    final filePath = widget.file.path;
    if (filePath == null) return;
    try {
      if (filePath.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(filePath),
        );
      } else {
        // Only use File for non-web platforms
        if (kIsWeb) {
          // For web, treat local paths as network URLs
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(filePath),
          );
        } else {
          _videoController = VideoPlayerController.file(
            File(filePath.replaceAll('//', '\\\\')),
          );
        }
      }
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoReady = true;
        });
        await _videoController!.setLooping(true);
        await _videoController!.setVolume(_volume);
        await _videoController!.play();
      }
    } catch (err) {
      _isLoadError = true;
    }
  }

  final _positionSubject = BehaviorSubject<double>();
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    // 使用throttleTime控制位置更新频率为50ms
    _positionSubscription = _positionSubject.stream
        .throttleTime(const Duration(milliseconds: 50))
        .listen(_updateVideoPosition);
  }

  void _updateVideoPosition(double position) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final duration = _videoController!.value.duration;
      _videoController!.fastSeekTo(duration * position);
      _videoController!.play();
    }
  }

  void _handleMousePosition(PointerHoverEvent event) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final renderBox =
        _mouseRegionKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(event.position);
    final width = renderBox.size.width;
    final position = (localPosition.dx / width).clamp(0.0, 1.0);

    // 将位置更新事件发送到subject
    _positionSubject.add(position);
  }

  void _handleHover(bool isHovering) {
    _hoverTimer?.cancel();

    if (isHovering) {
      _hoverTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isHovering = true;
            _initializeVideo();
          });
        }
      });
    } else {
      closeVideo();
    }
  }

  Widget _buildDragItem(
    BuildContext context,
    String folderTitle,
    List<String> tagTitles,
  ) {
    final isMedia =
        ['video', 'audio'].contains(widget.file.fileType) && !kIsWeb;
    var filePath = widget.file.path;
    return DragItemWidget(
      dragItemProvider: (request) async {
        final item = DragItem(
          localData: {'fileId': widget.file.id},
          suggestedName: widget.file.name,
        );
        if (!kIsWeb && filePath != null) {
          filePath = filePath!.replaceAll('//', '\\\\');
          if (filePath!.startsWith('\\')) {
            // windows smb路径需要转义
            filePath = filePath!.replaceAll('\\', '\\\\');
          } else {
            filePath = filePathToUri(filePath!);
          }
          final uri = Uri.parse(filePath!);
          final fileUri = Formats.fileUri(uri);
          item.add(fileUri);
        }
        return item;
      },
      allowedOperations: () => [DropOperation.copy],
      child: DraggableWidget(
        child: MouseRegion(
          key: _mouseRegionKey,
          onEnter: (_) => isMedia ? _handleHover(true) : null,
          onExit: (_) => isMedia ? _handleHover(false) : null,
          onHover: (event) => isMedia ? _handleMousePosition(event) : null,
          child: GestureDetector(
            onSecondaryTapDown: (details) => widget.onLongPress(details),
            onLongPressDown:
                kIsWeb ? widget.onLongPress(LongPressDownDetails) : null,
            child: Card(
              child: Stack(
                children: [
                  InkWell(
                    onTap: widget.onTap,
                    onDoubleTap: widget.onDoubleTap,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 100;
                        return SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              Expanded(child: _buildFileIcon()),
                              _buildFileInfo(context, isCompact),
                              _buildFileTags(folderTitle, tagTitles),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  _buildFileExtensionBadge(),
                  _buildSelectedIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        widget.getFolderTitle(widget.file.folderId),
        Future.wait(
          widget.file.tags.map((tag) => widget.getTagTilte(tag)).toList(),
        ),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        final folderTitle = snapshot.data![0] as String;
        final tagTitles = snapshot.data![1] as List<String>;
        return _buildDragItem(context, folderTitle, tagTitles);
      },
    );
  }
}
