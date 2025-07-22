import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mira/core/event/event_debounce.dart';
import 'package:mira/core/event/event_throttle.dart';
import 'package:rxdart/rxdart.dart';
import 'package:mira/plugins/libraries/widgets/file_upload_list_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:mira/plugins/libraries/widgets/library_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager.dart';
import 'package:number_pagination/number_pagination.dart';
import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
import 'package:mira/plugins/libraries/widgets/file_filter_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_file_preview_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_app_bar.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_bottom_sheet.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_body.dart';

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
  late bool _showSidebar = true;
  late bool _isLoading = true;
  late Map<String, dynamic>? _tabData;

  late Set<String> _displayFields = {};
  Map<String, dynamic> _filterOptions = {};
  Map<String, dynamic> _paginationOptions = {};
  final ValueNotifier<LibraryFile?> _selectedFileNotifier = ValueNotifier(null);
  int _imagesPerRow = 0; // 每行显示图片自动调节

  @override
  void initState() {
    super.initState();
    final tabId = widget.tabId;
    _tabManager = widget.plugin.tabManager;
    _paginationOptions = _tabManager.getPageOptions(tabId);
    _displayFields = _tabManager.getLibraryDisplayFields(tabId);
    _filterOptions = _tabManager.getLibraryFilter(tabId);
    _uploadQueue = UploadQueueService(widget.plugin, widget.library);
    _tabData = _tabManager.getTabData(tabId);
    _progressSubscription = _uploadQueue.progressStream.listen((completed) {
      setState(() {
        _uploadProgress = _uploadQueue.progress;
      });
    });
    final updateStream = EventThrottle(duration: Duration(seconds: 2));
    updateStream.stream.listen((EventArgs args) {
      //  服务器广播更新列表
      if (args is MapEventArgs) {
        final libraryId = args.item['libraryId'];
        if (libraryId != widget.library.id) return;
        final type = args.item['type'];
        if (type == 'deleted') {
          // 是否有在当前列表
          final id = args.item['id'];
          final file = _items.firstWhereOrNull((f) => f.id == id);
          if (file == null) return;
          _items.remove(file);
        }
        _loadFiles();
      }
    });
    EventManager.instance.subscribe(
      'thumbnail::generated',
      _onThumbnailGenerated,
    );
    EventManager.instance.subscribe(
      'file::changed',
      (args) => updateStream.onCall(args),
    );
    EventManager.instance.subscribe('library::filter_updated', _onFilterUpdate);
    _loadFiles();
  }

  //  系统内广播更新过滤器
  void _onFilterUpdate(EventArgs args) {
    if (args is MapEventArgs) {
      final libraryId = args.item['libraryId'];
      if (libraryId != widget.library.id) return;
      _filterOptions = Map<String, dynamic>.from(args.item['filter']);
      _loadFiles();
    }
  }

  void _onThumbnailGenerated(EventArgs args) {
    if (args is! serverEventArgs) return;
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

  void _showDropDialog() {
    showDialog(
      context: context,
      builder:
          (context) => FileUploadListDialog(
            plugin: widget.plugin,
            uploadQueue: _uploadQueue,
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
    // todo 完善更多过滤器
    final query = {
      'recycled': _tabData?['isRecycleBin'],
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

    final inst = await widget.plugin.libraryController.getLibraryInst(
      widget.library,
    );
    if (inst == null) return;
    final result = await inst.findFiles(query: query);

    if (mounted) {
      setState(() {
        if (result == null || result.isEmpty) {
          _items = [];
        } else {
          _items = result['results'] as List<LibraryFile>;
          _totalItems = result['total'] as int;
        }
        _isLoading = false;
      });
    }
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

  void _toggleSidebar() {
    setState(() {
      _showSidebar = !_showSidebar;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRecycleBin = _tabData?['isRecycleBin'];
    final screenWidth = MediaQuery.of(context).size.width;
    final totalPages = (_totalItems / _paginationOptions['perPage']).ceil();
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: LibraryGalleryAppBar(
        title: widget.library.name,
        isRecycleBin: isRecycleBin,
        isSelectionMode: _isSelectionMode,
        selectedCount: _selectedFileIds.length,
        onSelectAll: _toggleSelectAll,
        onExitSelection: _exitSelectionMode,
        toggleSidebar: _toggleSidebar,
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
        onUpload: _showDropDialog,
        uploadProgress: _uploadProgress,
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
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // 收藏
                Tooltip(
                  message: '收藏',
                  child: IconButton(
                    icon: Icon(Icons.favorite),
                    onPressed: () {},
                  ),
                ),
                // 回收站
                Tooltip(
                  message: '回收站',
                  child: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _tabManager.addTab(widget.library, isRecycleBin: true);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1),
          if (_showSidebar) ...[
            Expanded(
              flex: screenWidth < 600 ? 6 : (screenWidth > 1300 ? 1 : 2),
              child: LibrarySidebarView(
                plugin: widget.plugin,
                library: widget.library,
              ),
            ),
            VerticalDivider(width: 1),
          ],

          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(
                  child: LibraryGalleryBody(
                    plugin: widget.plugin,
                    library: widget.library,
                    isRecycleBin: isRecycleBin,
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
          if (screenWidth > 800) ...[
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
