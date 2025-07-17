import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
import 'package:mira/plugins/libraries/widgets/file_drop_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_item.dart';
import 'package:mira/plugins/libraries/widgets/upload_queue_dialog.dart';
import '../l10n/libraries_localizations.dart';

class LibraryGalleryView extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Library library;

  const LibraryGalleryView({
    required this.plugin,
    required this.library,
    super.key,
  });

  @override
  LibraryGalleryViewState createState() => LibraryGalleryViewState();
}

class LibraryGalleryViewState extends State<LibraryGalleryView> {
  late UploadQueueService _uploadQueue;
  double _uploadProgress = 0;
  StreamSubscription<int>? _progressSubscription;
  bool _isSelectionMode = false;
  Set<int> _selectedFileIds = {};

  @override
  void initState() {
    super.initState();
    _uploadQueue = UploadQueueService(widget.plugin);
    _progressSubscription = _uploadQueue.progressStream.listen((completed) {
      setState(() {
        _uploadProgress = _uploadQueue.progress;
      });
    });
    EventManager.instance.subscribe(
      'thumbnail_generated',
      _onThumbnailGenerated,
    );
  }

  void _onThumbnailGenerated(ItemEventArgs args) {
    final id = args.item['id'];
    final thumb = args.item['thumbPath'];
    if (id != null && thumb != null) {
      setState(() {
        widget.plugin.libraryController.updateFileThumb(id, thumb);
      });
    }
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _uploadQueue.dispose();
    super.dispose();
  }

  Future<void> _uploadFiles(List<File> filesToUpload) async {
    final localizations = LibrariesLocalizations.of(context);
    if (localizations == null) return;

    try {
      await _uploadQueue.addFiles(filesToUpload);
      await _uploadQueue.onComplete;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('开始上传')));
      setState(() {}); // 刷新文件列表
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.uploadFailed}: $e')),
      );
    } finally {
      setState(() {
        _uploadProgress = 0;
      });
    }
  }

  void _deleteFile(LibraryFile file) {
    widget.plugin.libraryController.deleteFile(file.id);
    setState(() {});
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder:
          (context) => FileDropDialog(
            plugin: widget.plugin,
            onFilesSelected: (files) async {
              if (files.isNotEmpty) {
                await _uploadFiles(files);
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LibrariesLocalizations.of(context);
    if (localizations == null) return Container();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '已选择 ${_selectedFileIds.length} 项'
              : localizations.filesTitle,
        ),
        actions:
            _isSelectionMode
                ? [
                  IconButton(
                    icon: Icon(Icons.select_all),
                    onPressed: () {
                      final files = widget.plugin.libraryController.getFiles();
                      files.then((fileList) {
                        setState(() {
                          final allFileIds = fileList.map((f) => f.id).toSet();
                          if (_selectedFileIds.length == allFileIds.length) {
                            _selectedFileIds.clear();
                          } else {
                            _selectedFileIds = allFileIds;
                          }
                        });
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      if (_selectedFileIds.isNotEmpty) {
                        setState(() {
                          _selectedFileIds.clear();
                        });
                      }
                      setState(() {
                        _isSelectionMode = false;
                      });
                    },
                  ),
                ]
                : [
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      // TODO: 实现搜索功能
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list),
                    onPressed: () {
                      // TODO: 实现过滤功能
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.check_box),
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = true;
                      });
                    },
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.file_upload),
                        onPressed: _showUploadDialog,
                      ),
                      StreamBuilder<int>(
                        stream: _uploadQueue.progressStream,
                        builder: (context, snapshot) {
                          final pendingCount = _uploadQueue.pendingFiles.length;
                          if (pendingCount == 0) return Container();
                          return Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$pendingCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.cloud_upload),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) =>
                                UploadQueueDialog(uploadQueue: _uploadQueue),
                      );
                    },
                  ),
                ],
      ),
      bottomSheet:
          _uploadProgress > 0
              ? LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              )
              : null,
      body: FutureBuilder<List<LibraryFile>>(
        future: widget.plugin.libraryController.getFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载文件失败: ${snapshot.error}'));
          }
          final files = snapshot.data ?? [];

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return LibraryItem(
                file: file,
                isSelected:
                    _isSelectionMode && _selectedFileIds.contains(file.id),
                useThumbnail:
                    file.thumb != null ||
                    ['audio', 'video'].contains(file.type?.toLowerCase()),
                onTap: () {
                  if (_isSelectionMode) {
                    final newSelectedIds = Set<int>.from(_selectedFileIds);
                    if (newSelectedIds.contains(file.id)) {
                      newSelectedIds.remove(file.id);
                    } else {
                      newSelectedIds.add(file.id);
                    }
                    setState(() {
                      _selectedFileIds = newSelectedIds;
                    });
                  } else {
                    // 原来的点击逻辑
                  }
                },
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(Icons.delete),
                              title: Text('删除'),
                              onTap: () {
                                Navigator.pop(context);
                                _deleteFile(file);
                              },
                            ),
                          ],
                        ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
