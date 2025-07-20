import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager.dart';
import 'package:number_pagination/number_pagination.dart';
import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
import 'package:mira/plugins/libraries/widgets/file_drop_dialog.dart';
import 'package:mira/plugins/libraries/widgets/file_filter_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_file_preview_view.dart';
import 'package:mira/plugins/libraries/widgets/upload_queue_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_app_bar.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_bottom_sheet.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_body.dart';
import '../l10n/libraries_localizations.dart';

class LibraryGalleryView extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Library library;
  final String tabId;

  const LibraryGalleryView({
    required this.plugin,
    required this.library,
    required this.tabId,
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
  late int _totalItems = 0;
  late List<LibraryFile> _items = [];
  late LibraryTabManager _tabManager;

  late Set<String> _displayFields = {};
  Map<String, dynamic> _filterOptions = {};
  Map<String, dynamic> _paginationOptions = {};
  final ValueNotifier<LibraryFile?> _selectedFileNotifier = ValueNotifier(null);
  int _imagesPerRow = 3; // 默认每行显示3张图片

  @override
  void initState() {
    super.initState();
    _tabManager = widget.plugin.tabManager;
    _paginationOptions = _tabManager.getPageOptions(widget.tabId);
    _displayFields = _tabManager.getLibraryDisplayFields(widget.tabId);
    _filterOptions = _tabManager.getLibraryFilter(widget.tabId);
    _uploadQueue = UploadQueueService(widget.plugin, widget.library);
    _progressSubscription = _uploadQueue.progressStream.listen((completed) {
      if (mounted) {
        setState(() {
          _uploadProgress = _uploadQueue.progress;
        });
      }
    });
    EventManager.instance.subscribe(
      'thumbnail_generated',
      _onThumbnailGenerated,
    );
    EventManager.instance.subscribe('library::filter_updated', _onFilterUpdate);
    _loadFiles();
  }

  //  使用广播更新
  void _onFilterUpdate(EventArgs args) {
    if (args is! MapEventArgs) return;
    final library = args.item['library'];
    if (library == null || library.id != widget.library.id) return;
    setState(() {
      _filterOptions = Map<String, dynamic>.from(args.item['filter']);
      _loadFiles();
    });
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
      // await _uploadQueue.onComplete;
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(const SnackBar(content: Text('开始上传')));
      // setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.uploadFailed}: $e')),
      );
    } finally {
      // setState(() {
      //   _uploadProgress = 0;
      // });
    }
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
    widget.plugin.libraryController
        .getLibraryInst(widget.library)!
        .getFiles()
        .then((fileList) {
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

  Future<void> _loadFiles() async {
    final query = {
      'name': _filterOptions['name'] ?? '',
      'tags': _filterOptions['tags'] ?? [],
      'folder': _filterOptions['folder'] ?? '',
      // 'dateRange': _filterOptions['dateRange'] ?? [],
      // 'minSize': _filterOptions['minSize'] ?? 0,
      // 'maxSize': _filterOptions['maxSize'] ?? 0,
      // 'tags': _filterOptions['tags'] ?? [],
      // 'minRating': _filterOptions['minRating'] ?? 0,
      // 'type': _filterOptions['type'] ?? '',
      'offset':
          (_paginationOptions['page']! - 1) * _paginationOptions['perPage'],
      'limit': _paginationOptions['perPage'],
    };

    final result = await widget.plugin.libraryController
        .getLibraryInst(widget.library)!
        .findFiles(query: query);

    setState(() {
      if (result == null || result.isEmpty) {
        _items = [];
      } else {
        _items = result['results'] as List<LibraryFile>;
        _totalItems = result['total'] as int;
      }
    });
  }

  void _onFileSelected(LibraryFile file) {
    _selectedFileNotifier.value = file;
    if (Platform.isAndroid || Platform.isIOS) {
      showModalBottomSheet(
        context: context,
        builder: (context) => LibraryFileInformationView(file: file),
      );
    }
  }

  void _onFileOpen(LibraryFile file) {
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
    final totalPages = (_totalItems / _paginationOptions['perPage']).ceil();
    return Scaffold(
      appBar: LibraryGalleryAppBar(
        isSelectionMode: _isSelectionMode,
        selectedCount: _selectedFileIds.length,
        onSelectAll: _toggleSelectAll,
        onExitSelection: _exitSelectionMode,
        onFilter: () async {
          final filterOptions = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => FileFilterDialog(),
          );
          if (filterOptions != null) {
            setState(() {
              _filterOptions = filterOptions;
            });
            _tabManager.setLibraryFilter(widget.tabId, _filterOptions);
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
          widget.plugin.libraryController
              .getLibraryInst(widget.library)!
              .getFolders()
              .then((folders) async {
                await widget.plugin.libraryUIController.showFolderSelector(
                  widget.library,
                  context,
                );
              });
        },
        onTag: () async {
          await widget.plugin.libraryUIController.showTagSelector(
            widget.library,
            context,
          );
        },
        pendingUploadCount: _uploadQueue.pendingFiles.length,
        displayFields: _displayFields,
        onDisplayFieldsChanged: (newFields) {
          setState(() {
            _displayFields = newFields;
          });
          _tabManager.setLibraryDisplayFields(widget.tabId, _displayFields);
        },
        imagesPerRow: _imagesPerRow,
        onImagesPerRowChanged: (count) {
          setState(() {
            _imagesPerRow = count;
          });
        },
        onRefresh: () => _loadFiles(),
      ),
      bottomSheet: LibraryGalleryBottomSheet(uploadProgress: _uploadProgress),
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: LibraryGalleryBody(
                    plugin: widget.plugin,
                    library: widget.library,
                    displayFields: _displayFields,
                    items: ValueNotifier(_items),
                    isSelectionMode: _isSelectionMode,
                    selectedFileIds: _selectedFileIds,
                    onFileSelected: _onFileSelected,
                    onFileOpen: _onFileOpen,
                    imagesPerRow: _imagesPerRow,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: NumberPagination(
                    currentPage: _paginationOptions['page'],
                    totalPages: totalPages,
                    onPageChanged: (page) {
                      _paginationOptions['page'] = page;
                      _loadFiles();
                    },
                    visiblePagesCount:
                        MediaQuery.of(context).size.width ~/ 200 + 2,
                    buttonRadius: 10.0,
                    buttonElevation: 1.0,
                    controlButtonSize: Size(34, 34),
                    numberButtonSize: Size(34, 34),
                    selectedButtonColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (!Platform.isAndroid &&
              !Platform.isIOS &&
              MediaQuery.of(context).size.width > 800) ...[
            VerticalDivider(width: 1),
            Expanded(
              flex: 1,
              child: ValueListenableBuilder<LibraryFile?>(
                valueListenable: _selectedFileNotifier,
                builder: (context, selectedFile, _) {
                  return selectedFile != null
                      ? LibraryFileInformationView(file: selectedFile)
                      : const Center(child: Text('请选择一个文件查看详情'));
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
