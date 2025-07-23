import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/controllers/library_data_interface.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
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
  late LibraryTabData? _tabData;
  late List<LibraryFolder> _folders = [];
  late List<LibraryTag> _tags = [];
  bool _isFirstLoad = false;
  List<String> _eventSubscribes = [];

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
    initEvents();
  }

  Future<void> _loadFoldersTags() async {
    // final tags =
    //     (await widget.plugin.foldersTagsController
    //             .getTagCache(widget.library.id)
    //             .getAll())
    //         .cast<LibraryTag>();
    // final folders =
    //     (await widget.plugin.foldersTagsController
    //             .getFolderCache(widget.library.id)
    //             .getAll())
    //         .cast<LibraryFolder>();
    final inst =
        widget.plugin.libraryController.getLibraryInst(widget.library.id)!;
    final tags =
        (await inst.getAllTags())
            .map((item) => LibraryTag.fromMap(item))
            .toList();
    final folders =
        (await inst.getAllFolders())
            .map((item) => LibraryFolder.fromMap(item))
            .toList();
    _tags = tags;
    _folders = folders;
  }

  void initEvents() async {
    _eventSubscribes.addAll([
      EventManager.instance.subscribe(
        'thumbnail::generated',
        _onThumbnailGenerated,
      ),
      EventManager.instance.subscribe('tab::doUpdate', (EventArgs args) {
        if (args is MapEventArgs) {
          if (args.item['tabId'] == widget.tabId) {
            _refresh();
            print('updated Tab ${widget.tabId}');
          }
        }
      }),
      EventManager.instance.subscribe('filter::updated', _onFilterUpdate),
    ]);
  }

  void _refresh() async {
    if (mounted) {
      setState(() {
        _loadFiles();
        // _loadFoldersTags();
      });
    }
  }

  //  系统内广播更新过滤器
  void _onFilterUpdate(EventArgs args) {
    if (args is MapEventArgs) {
      final tabId = args.item['tabId'];
      if (widget.tabId == tabId) {
        _filterOptions = Map<String, dynamic>.from(args.item['filter']);
        setState(() {
          _loadFiles();
        });
      }
    }
  }

  void _onThumbnailGenerated(EventArgs args) {
    if (args is! ServerEventArgs) return;
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _uploadQueue.dispose();
    for (final key in _eventSubscribes) {
      EventManager.instance.unsubscribe(key);
    }
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
    setState(() {
      if (_selectedFileIds.isEmpty) {
        _selectedFileIds = _items.map((f) => f.id).toSet();
      } else {
        _selectedFileIds.clear();
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      if (_selectedFileIds.isNotEmpty) {
        _selectedFileIds.clear();
      }
      _isSelectionMode = false;
    });
  }

  Future<void> _loadFiles() async {
    // todo 完善更多过滤器
    _isLoading = true;
    final query = {
      'recycled': _tabData!.isRecycleBin,
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

    try {
      final inst = widget.plugin.libraryController.getLibraryInst(
        widget.library.id,
      );
      if (inst != null) {
        final result = await inst.findFiles(query: query);
        if (result != null && result.isNotEmpty) {
          _items = result['results'] as List<LibraryFile>;
          _totalItems = result['total'] as int;
        }
      }
    } catch (err) {
      _items = [];
    } finally {
      _isLoading = false;
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

  Future<void> _doFirstLoad() async {
    if (!_isFirstLoad) {
      _isFirstLoad = true;
      await _loadFiles();
      await _loadFoldersTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: () {
        // 保证library完成初始化连接
        return widget.plugin.libraryController
            .loadLibraryInst(widget.library)
            .then((_) => _doFirstLoad());
      }(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(child: CircularProgressIndicator());
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Text('加载数据出错: ${snapshot.error}');
            }
            return buildContent();
        }
      },
    );
  }

  Widget buildContent() {
    final isRecycleBin = _tabData!.isRecycleBin;
    final screenWidth = MediaQuery.of(context).size.width;
    final totalPages = (_totalItems / _paginationOptions['perPage']).ceil();
    if (totalPages > 0 && _paginationOptions['page'] > totalPages) {
      _paginationOptions = Map<String, dynamic>.from(_paginationOptions);
      _paginationOptions['page'] = totalPages;
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
        onRefresh: _refresh,
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
                tabId: widget.tabId,
                tags: _tags,
                tagsSelected: _filterOptions['tags'] ?? [],
                folders: _folders,
                folderSelected:
                    _filterOptions['folder'] is String
                        ? [_filterOptions['folder']]
                        : [],
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
                      _paginationOptions = Map<String, dynamic>.from(
                        _paginationOptions,
                      );
                      _paginationOptions['page'] = page;
                      setState(() {
                        _loadFiles();
                      });
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
