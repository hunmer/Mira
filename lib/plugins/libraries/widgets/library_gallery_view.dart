import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mira/core/event/event.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
import 'package:mira/plugins/libraries/widgets/file_drop_dialog.dart';
import 'package:mira/plugins/libraries/widgets/file_filter_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_file_preview_view.dart';
import 'package:mira/plugins/libraries/widgets/library_item.dart';
import 'package:mira/plugins/libraries/widgets/upload_queue_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_app_bar.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_bottom_sheet.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_body.dart';
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
  Map<String, dynamic> _filterOptions = {};

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

  void _onThumbnailGenerated(EventArgs args) {
    if (args is! ItemEventArgs) return;
    if (mounted) {
      setState(() {});
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
      ).showSnackBar(const SnackBar(content: Text('开始上传')));
      setState(() {});
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

  void _toggleSelectAll() {
    widget.plugin.libraryController.getFiles().then((fileList) {
      setState(() {
        final allFileIds = fileList.map((f) => f.id).toSet();
        if (_selectedFileIds.length == allFileIds.length) {
          _selectedFileIds.clear();
        } else {
          _selectedFileIds = allFileIds;
        }
      });
    });
  }

  void _exitSelectionMode() {
    if (_selectedFileIds.isNotEmpty) {
      setState(() {
        _selectedFileIds.clear();
      });
    }
    setState(() {
      _isSelectionMode = false;
    });
  }

  void _onFileSelected(LibraryFile file) {
    final fileId = file.id;
    if (_isSelectionMode) {
      setState(() {
        if (_selectedFileIds.contains(fileId)) {
          _selectedFileIds.remove(fileId);
        } else {
          _selectedFileIds.add(fileId);
        }
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LibraryFilePreviewView(file: file),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LibraryGalleryAppBar(
        isSelectionMode: _isSelectionMode,
        selectedCount: _selectedFileIds.length,
        onSelectAll: _toggleSelectAll,
        onExitSelection: _exitSelectionMode,
        onSearch: () {}, // TODO: 实现搜索功能
        onFilter: () async {
          final filterOptions = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => FileFilterDialog(),
          );
          if (filterOptions != null) {
            setState(() {
              _filterOptions = filterOptions;
            });
          }
        },
        onEnterSelection: () {
          setState(() {
            _isSelectionMode = true;
          });
        },
        onUpload: _showUploadDialog,
        onShowUploadQueue: () {
          showDialog(
            context: context,
            builder: (context) => UploadQueueDialog(uploadQueue: _uploadQueue),
          );
        },
        onFolder: () {
          widget.plugin.libraryController.getFolders().then((folders) async {
            await widget.plugin.libraryUIController.showFolderSelector(context);
          });
        },
        onTag: () async {
          await widget.plugin.libraryUIController.showTagSelector(context);
        },
        pendingUploadCount: _uploadQueue.pendingFiles.length,
      ),
      bottomSheet: LibraryGalleryBottomSheet(uploadProgress: _uploadProgress),
      body: LibraryGalleryBody(
        plugin: widget.plugin,
        filterOptions: _filterOptions,
        isSelectionMode: _isSelectionMode,
        selectedFileIds: _selectedFileIds,
        onFileSelected: _onFileSelected,
      ),
    );
  }
}
