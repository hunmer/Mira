import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/widgets/file_upload_list_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:mira/plugins/libraries/widgets/library_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/library_sort_dialog.dart';
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
  final ValueNotifier<double> _uploadProgressNotifier = ValueNotifier(0);
  StreamSubscription<Map<String, int>>? _progressSubscription;
  final ValueNotifier<bool> _isSelectionModeNotifier = ValueNotifier(false);
  final ValueNotifier<Set<int>> _selectedFileIds = ValueNotifier({});
  final ValueNotifier<int> _totalItemsNotifier = ValueNotifier(0);
  final ValueNotifier<List<LibraryFile>> _items = ValueNotifier([]);
  late LibraryTabManager _tabManager;
  final ValueNotifier<bool> _showSidebarNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _isItemsLoadingNotifier = ValueNotifier(true);
  late LibraryTabData? _tabData;
  final ValueNotifier<List<LibraryFolder>> _folders = ValueNotifier([]);
  final ValueNotifier<List<LibraryTag>> _tags = ValueNotifier([]);
  bool _isFirstLoad = false;
  List<String> _eventSubscribes = [];
  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<Set<String>> _displayFieldsNotifier = ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> _filterOptionsNotifier =
      ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> _paginationOptionsNotifier =
      ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> _sortOptionsNotifier =
      ValueNotifier({'sort': 'imported_at', 'order': 'desc'});
  final ValueNotifier<LibraryFile?> _selectedFileNotifier = ValueNotifier(null);
  final ValueNotifier<int> _imagesPerRowNotifier = ValueNotifier(
    0,
  ); // 每行显示图片自动调节

  @override
  void initState() {
    super.initState();
    final tabId = widget.tabId;
    _tabManager = widget.plugin.tabManager;
    _paginationOptionsNotifier.value = Map<String, dynamic>.from(
      _tabManager.getPageOptions(tabId),
    );
    _displayFieldsNotifier.value = _tabManager.getLibraryDisplayFields(tabId);
    _filterOptionsNotifier.value = _tabManager.getLibraryFilter(tabId);
    _sortOptionsNotifier.value = Map<String, dynamic>.from(
      _tabManager.getSortOptions(tabId) ??
          {'sort': 'imported_at', 'order': 'desc'},
    );
    _uploadQueue = UploadQueueService(widget.plugin, widget.library);
    _tabData = _tabManager.getTabData(tabId);
    _progressSubscription = _uploadQueue.progressStream.listen((completed) {
      _uploadProgressNotifier.value = _uploadQueue.progress;
    });
    initEvents();
  }

  Future<void> _loadFoldersTags() async {
    final inst = widget.plugin.libraryController.getLibraryInst(
      widget.library.id,
    );
    if (inst != null) {
      _tags.value =
          (await inst.getAllTags())
              .map((item) => LibraryTag.fromMap(item))
              .toList();
      _folders.value =
          (await inst.getAllFolders())
              .map((item) => LibraryFolder.fromMap(item))
              .toList();
    }
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
      EventManager.instance.subscribe('sort::updated', _onSortUpdate),
      EventManager.instance.subscribeOnce('library::connected', _doFirstLoad),
    ]);
  }

  void _refresh() async {
    if (mounted) {
      await _loadFiles();
      await _loadFoldersTags();
    }
  }

  //  系统内广播更新过滤器
  void _onFilterUpdate(EventArgs args) {
    if (args is MapEventArgs) {
      final tabId = args.item['tabId'];
      if (widget.tabId == tabId) {
        _filterOptionsNotifier.value = Map<String, dynamic>.from(
          args.item['filter'],
        );
        _loadFiles();
      }
    }
  }

  //  系统内广播更新过滤器
  void _onSortUpdate(EventArgs args) {
    if (args is MapEventArgs) {
      final tabId = args.item['tabId'];
      if (widget.tabId == tabId) {
        _sortOptionsNotifier.value = Map<String, dynamic>.from(
          args.item['sort'],
        );
        _loadFiles();
      }
    }
  }

  Future<void> _doFirstLoad(EventArgs args) async {
    if (args is MapEventArgs && !_isFirstLoad) {
      _isFirstLoad = true;
      _tags.value =
          (args.item['tags'] as List)
              .map((item) => LibraryTag.fromMap(item))
              .toList();
      _folders.value =
          (args.item['folders'] as List)
              .map((item) => LibraryFolder.fromMap(item))
              .toList();
      await _loadFiles();
    }
  }

  void _onThumbnailGenerated(EventArgs args) {
    if (args is! ServerEventArgs) return;
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _uploadQueue.dispose();
    _scrollController.dispose();
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
    if (_selectedFileIds.value.isEmpty) {
      _selectedFileIds.value = _items.value.map((f) => f.id).toSet();
    } else {
      _selectedFileIds.value.clear();
    }
  }

  void _exitSelectionMode() {
    if (_selectedFileIds.value.isNotEmpty) {
      _selectedFileIds.value.clear();
    }
    _isSelectionModeNotifier.value = false;
  }

  Future<void> _loadFiles() async {
    if (!mounted) return;
    _isItemsLoadingNotifier.value = true;

    final filterOptions = _filterOptionsNotifier.value;
    final paginationOptions = _paginationOptionsNotifier.value;
    final sortOptions = _sortOptionsNotifier.value;

    final query = {
      'recycled': _tabData!.isRecycleBin,
      'name': filterOptions['name'] ?? '',
      'tags': filterOptions['tags'] ?? [],
      'folder': filterOptions['folder'] ?? '',
      'offset': (paginationOptions['page']! - 1) * paginationOptions['perPage'],
      'limit': paginationOptions['perPage'],
      'sort': sortOptions['sort'] ?? 'imported_at',
      'order': sortOptions['order'] ?? 'desc',
    };

    try {
      final inst = widget.plugin.libraryController.getLibraryInst(
        widget.library.id,
      );
      if (inst != null) {
        final result = await inst.findFiles(query: query);
        _items.value = result['result'];
        _totalItemsNotifier.value = result['total'] as int;
        print('Total Count: ${_totalItemsNotifier.value}');
      }
    } catch (err) {
      _items.value = [];
    } finally {
      if (mounted) {
        _isItemsLoadingNotifier.value = false;
      }
    }
  }

  void _onFileSelected(LibraryFile file) {
    _selectedFileNotifier.value = file;
    if (Platform.isAndroid || Platform.isIOS) {
      showModalBottomSheet(
        context: context,
        builder:
            (context) => LibraryFileInformationView(
              plugin: widget.plugin,
              library: widget.library,
              file: file,
            ),
      );
    }
  }

  void _onFileOpen(LibraryFile file) {
    final fileId = file.id;
    if (_isSelectionModeNotifier.value) {
      if (_selectedFileIds.value.contains(fileId)) {
        _selectedFileIds.value.remove(fileId);
      } else {
        _selectedFileIds.value.add(fileId);
      }
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => LibraryFileInformationView(
                plugin: widget.plugin,
                library: widget.library,
                file: file,
              ),
        ),
      );
    }
  }

  void _toggleSidebar() {
    _showSidebarNotifier.value = !_showSidebarNotifier.value;
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder:
          (context) =>
              LibrarySortDialog(initialSortOptions: _sortOptionsNotifier.value),
    ).then((sortOptions) {
      if (sortOptions != null && _sortOptionsNotifier.value != sortOptions) {
        _sortOptionsNotifier.value = sortOptions;
        _loadFiles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return FutureBuilder<dynamic>(
      future: () {
        // 保证library完成初始化连接
        return widget.plugin.libraryController.loadLibraryInst(widget.library);
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
    final paginationOptions = _paginationOptionsNotifier.value;
    final totalPages =
        (_totalItemsNotifier.value / paginationOptions['perPage']).ceil();
    if (totalPages > 0 && paginationOptions['page'] > totalPages) {
      _paginationOptionsNotifier.value = Map<String, dynamic>.from(
        paginationOptions,
      );
      _paginationOptionsNotifier.value['page'] = totalPages;
    }
    return Scaffold(
      bottomSheet: LibraryGalleryBottomSheet(
        uploadProgress: _uploadProgressNotifier.value,
      ),
      body: Row(
        children: [
          _buildQuickActions(),
          VerticalDivider(width: 1),
          _buildSidebarSection(screenWidth),
          VerticalDivider(width: 1),
          _buildMainContent(isRecycleBin, screenWidth),
          if (screenWidth > 800) ...[
            VerticalDivider(width: 1),
            _buildFileDetailsSection(),
          ],
          VerticalDivider(width: 1),
          _buildAppBarActions(),
        ],
      ),
    );
  }

  Widget _buildAppBarActions() {
    final isRecycleBin = _tabData!.isRecycleBin;
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Tooltip(
            message: '刷新',
            child: IconButton(icon: Icon(Icons.refresh), onPressed: _refresh),
          ),
          Tooltip(
            message: '上传',
            child: IconButton(
              icon: Icon(Icons.upload),
              onPressed: _showDropDialog,
            ),
          ),
          Tooltip(
            message: '排序',
            child: IconButton(
              icon: Icon(Icons.sort),
              onPressed: _showSortDialog,
            ),
          ),
          Tooltip(
            message: '筛选',
            child: IconButton(
              icon: Icon(Icons.filter_alt),
              onPressed: () async {
                final filterOptions = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => FileFilterDialog(),
                );
                if (filterOptions != null &&
                    _filterOptionsNotifier.value != filterOptions) {
                  _filterOptionsNotifier.value = filterOptions;
                  _tabManager.setLibraryFilter(widget.tabId, filterOptions);
                }
              },
            ),
          ),
          Tooltip(
            message: '选择模式',
            child: IconButton(
              icon: Icon(Icons.select_all),
              onPressed: () {
                if (_isSelectionModeNotifier.value) {
                  _exitSelectionMode();
                } else {
                  _isSelectionModeNotifier.value = true;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Tooltip(
            message: '显示/隐藏侧边栏',
            child: IconButton(
              icon: Icon(Icons.menu),
              onPressed: _toggleSidebar,
            ),
          ),
          Tooltip(
            message: '收藏',
            child: IconButton(icon: Icon(Icons.favorite), onPressed: () {}),
          ),
          Tooltip(
            message: '回收站',
            child: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _tabManager.addTab(widget.library, isRecycleBin: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(double screenWidth) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showSidebarNotifier,
      builder: (context, showSidebar, _) {
        if (!showSidebar) return SizedBox.shrink();

        return Expanded(
          flex: screenWidth < 600 ? 6 : (screenWidth > 1300 ? 1 : 2),
          child: ValueListenableBuilder(
            valueListenable: _tags,
            builder: (context, tags, _) {
              return ValueListenableBuilder(
                valueListenable: _folders,
                builder: (context, folders, _) {
                  return ValueListenableBuilder(
                    valueListenable: _filterOptionsNotifier,
                    builder: (context, filterOptions, _) {
                      return LibrarySidebarView(
                        plugin: widget.plugin,
                        library: widget.library,
                        tabId: widget.tabId,
                        tags: tags,
                        tagsSelected: filterOptions['tags'] ?? [],
                        folders: folders,
                        folderSelected:
                            filterOptions['folder'] is String
                                ? [filterOptions['folder']]
                                : [],
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMainContent(bool isRecycleBin, double screenWidth) {
    return Expanded(
      flex: 4,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ValueListenableBuilder(
                  valueListenable: _items,
                  builder: (context, items, _) {
                    return LibraryGalleryBody(
                      plugin: widget.plugin,
                      library: widget.library,
                      isRecycleBin: isRecycleBin,
                      displayFields: _displayFieldsNotifier.value,
                      items: items,
                      isSelectionMode: _isSelectionModeNotifier.value,
                      selectedFileIds: _selectedFileIds.value,
                      onFileSelected: _onFileSelected,
                      onFileOpen: _onFileOpen,
                      imagesPerRow: _imagesPerRowNotifier.value,
                      scrollController: _scrollController,
                    );
                  },
                ),
                ValueListenableBuilder(
                  valueListenable: _isItemsLoadingNotifier,
                  builder: (context, isLoading, _) {
                    return isLoading
                        ? Center(child: CircularProgressIndicator())
                        : SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return ValueListenableBuilder<int>(
      valueListenable: _totalItemsNotifier,
      builder: (context, totalItems, _) {
        final paginationOptions = _paginationOptionsNotifier.value;
        final totalPages = (totalItems / paginationOptions['perPage']).ceil();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: NumberPagination(
            currentPage: paginationOptions['page'],
            totalPages: totalPages,
            onPageChanged: (page) {
              _paginationOptionsNotifier.value = {
                ..._paginationOptionsNotifier.value,
                'page': page,
              };
              _loadFiles().then((_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(0);
                  }
                });
              });
            },
            visiblePagesCount: MediaQuery.of(context).size.width ~/ 200 + 2,
            buttonRadius: 10.0,
            buttonElevation: 1.0,
            controlButtonSize: Size(34, 34),
            numberButtonSize: Size(34, 34),
            selectedButtonColor: Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildFileDetailsSection() {
    return Expanded(
      flex: 1,
      child: ValueListenableBuilder(
        valueListenable: _selectedFileNotifier,
        builder: (context, selectedFile, _) {
          return selectedFile != null
              ? LibraryFileInformationView(
                plugin: widget.plugin,
                library: widget.library,
                file: selectedFile,
              )
              : const Center(child: Text('请选择一个文件查看详情'));
        },
      ),
    );
  }
}
