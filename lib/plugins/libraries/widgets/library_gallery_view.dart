import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/models/folder.dart';
import 'package:mira/plugins/libraries/models/tag.dart';
import 'package:mira/plugins/libraries/widgets/file_upload_list_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_file_information_view.dart';
import 'package:mira/plugins/libraries/widgets/library_file_preview_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_app_bar.dart';
import 'package:mira/plugins/libraries/widgets/library_sidebar_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';
import 'package:number_pagination/number_pagination.dart';
import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/services/server_item_event.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
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
  final List<String> _eventSubscribes = [];
  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<Set<String>> _displayFieldsNotifier = ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> _filterOptionsNotifier =
      ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> _paginationOptionsNotifier =
      ValueNotifier({});
  final ValueNotifier<Map<String, dynamic>> _sortOptionsNotifier =
      ValueNotifier({'sort': 'id', 'order': 'desc'});
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
      _tabManager.getStoredValue(tabId, 'paginationOptions', {
        'page': 1,
        'perPage': 1000,
      }),
    );
    _displayFieldsNotifier.value = Set<String>.from(
      _tabManager.getStoredValue(tabId, 'displayFields', <String>{}),
    );
    _filterOptionsNotifier.value = Map<String, dynamic>.from(
      _tabManager.getStoredValue(tabId, 'filter', {
        'name': '',
        'tags': [],
        'folder': '',
      }),
    );
    _sortOptionsNotifier.value = Map<String, dynamic>.from(
      _tabManager.getStoredValue(tabId, 'sortOptions', {
        'sort': 'imported_at',
        'order': 'desc',
      }),
    );
    _imagesPerRowNotifier.value =
        _tabManager.getStoredValue(tabId, 'imagesPerRow', 0) as int;
    _displayFieldsNotifier.value = Set<String>.from(
      _tabManager.getStoredValue(tabId, 'displayFields', <String>{}),
    );
    _sortOptionsNotifier.value = Map<String, dynamic>.from(
      _tabManager.getStoredValue(tabId, 'sortOptions', {
        'sort': 'imported_at',
        'order': 'desc',
      }),
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
        // 重置页面
        _paginationOptionsNotifier.value = {
          ..._paginationOptionsNotifier.value,
          'page': 1,
        };
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
    final fileId = file.id;
    if (_isSelectionModeNotifier.value) {
      final currentSelection = Set<int>.from(_selectedFileIds.value);
      if (currentSelection.contains(fileId)) {
        currentSelection.remove(fileId);
      } else {
        currentSelection.add(fileId);
      }
      _selectedFileIds.value = currentSelection;
    }
    _selectedFileNotifier.value = file;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => LibraryFilePreviewView(
              plugin: widget.plugin,
              library: widget.library,
              file: file,
            ),
      ),
    );
  }

  void _toggleSidebar() {
    _showSidebarNotifier.value = !_showSidebarNotifier.value;
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
    final color = Theme.of(context).primaryColor;
    return Scaffold(
      bottomSheet: LibraryGalleryBottomSheet(
        uploadProgress: _uploadProgressNotifier.value,
      ),
      body: Row(
        children: [
          // Quick Actions
          Card(
            elevation: 4,
            margin: const EdgeInsets.all(6),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: _buildQuickActions(),
            ),
          ),
          // Sidebar Section
          Flexible(
            flex: screenWidth < 600 ? 6 : (screenWidth > 1300 ? 1 : 2),
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.all(6),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: _buildSidebarSection(screenWidth),
              ),
            ),
          ),
          // Main Content
          Flexible(
            flex: 4,
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.all(6),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: _buildMainContent(isRecycleBin, screenWidth),
              ),
            ),
          ),
          // File Details Section (only for wide screens)
          if (screenWidth > 800)
            Flexible(
              flex: 1,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: _buildMoreDetailsPage(),
                ),
              ),
            ),
          // AppBar Actions
          Card(
            elevation: 4,
            margin: const EdgeInsets.all(6),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: _buildAppBarActions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarActions() {
    return LibraryGalleryAppBar(
      title: widget.library.name,
      getItems: () {
        return _items.value;
      },
      getSelected: () {
        return _selectedFileIds.value;
      },
      isSelectionMode: _isSelectionModeNotifier.value,
      onToggleSelection:
          (bool enable) => _isSelectionModeNotifier.value = enable,
      isRecycleBin: _tabData!.isRecycleBin,
      onSelectionChanged: (Set<int> selected) {
        _selectedFileIds.value = selected;
      },
      filterOptions: Map<String, dynamic>.from(_filterOptionsNotifier.value),
      onFilterChanged: (Map<String, dynamic> filterOptions) {
        if (filterOptions != null &&
            _filterOptionsNotifier.value != filterOptions) {
          _filterOptionsNotifier.value = filterOptions;
          _tabManager.updateFilter(widget.tabId, filterOptions);
        }
      },

      onUpload: _showDropDialog,
      uploadProgress: _uploadProgressNotifier.value,
      displayFields: Set<String>.from(_displayFieldsNotifier.value),
      onDisplayFieldsChanged: (Set<String> fields) {
        _displayFieldsNotifier.value = fields;
        _tabManager.setStoreValue(widget.tabId, 'displayFields', fields);
      },
      imagesPerRow: _imagesPerRowNotifier.value,
      onImagesPerRowChanged: (count) {
        _imagesPerRowNotifier.value = count;
        _tabManager.setStoreValue(widget.tabId, 'imagesPerRow', count);
      },
      onRefresh: _refresh,
      sortOptions: _sortOptionsNotifier.value,
      onSortChanged: (sortOptions) {
        if (sortOptions != null && _sortOptionsNotifier.value != sortOptions) {
          _sortOptionsNotifier.value = sortOptions;
          _tabManager.setStoreValue(widget.tabId, 'sortOptions', sortOptions);
          _loadFiles();
        }
      },
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
            message: '文件夹列表',
            child: IconButton(
              icon: Icon(Icons.folder),
              onPressed: () async {
                final result = await widget.plugin.libraryUIController
                    .showFolderSelector(widget.library, context);
                if (result != null && result.isNotEmpty) {}
              },
            ),
          ),
          Tooltip(
            message: '标签列表',
            child: IconButton(
              icon: Icon(Icons.label),
              onPressed: () async {
                final result = await widget.plugin.libraryUIController
                    .showTagSelector(widget.library, context);
                if (result != null && result.isNotEmpty) {}
              },
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
                _tabManager.addTab(
                  widget.library,
                  isRecycleBin: true,
                  title: '回收站',
                );
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

        return MultiValueListenableBuilder(
          valueListenables: [_tags, _folders, _filterOptionsNotifier],
          builder: (context, values, _) {
            final tags = values[0] as List<LibraryTag>;
            final folders = values[1] as List<LibraryFolder>;
            final filterOptions = values[2] as Map<String, dynamic>;

            return LibrarySidebarView(
              plugin: widget.plugin,
              library: widget.library,
              tabId: widget.tabId,
              tags: tags,
              tagsSelected: List<String>.from(filterOptions['tags'] ?? []),
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
  }

  Widget _buildMainContent(bool isRecycleBin, double screenWidth) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MultiValueListenableBuilder(
                valueListenables: [
                  _items,
                  _isSelectionModeNotifier,
                  _selectedFileIds,
                  _displayFieldsNotifier,
                  _imagesPerRowNotifier,
                ],
                builder: (context, values, _) {
                  return LibraryGalleryBody(
                    plugin: widget.plugin,
                    library: widget.library,
                    isRecycleBin: isRecycleBin,
                    displayFields: values[3] as Set<String>,
                    items: values[0] as List<LibraryFile>,
                    isSelectionMode: values[1] as bool,
                    selectedFileIds: values[2] as Set<int>,
                    onFileSelected: _onFileSelected,
                    onFileOpen: _onFileOpen,
                    imagesPerRow: values[4] as int,
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
    );
  }

  void _toPage(int page) {
    print('Page changed to: $page');
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
              _toPage(page);
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

  Widget _buildMoreDetailsPage() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tooltip(
                message: '文件信息',
                child: Tab(icon: Icon(Icons.info_outline)),
              ),
              Tooltip(
                message: '选中文件列表',
                child: Tab(icon: Icon(Icons.list_alt)),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 文件信息 Tab
                ValueListenableBuilder<LibraryFile?>(
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
                // 选中文件列表 Tab
                ValueListenableBuilder<Set<int>>(
                  valueListenable: _selectedFileIds,
                  builder: (context, selectedIds, _) {
                    final selectedFiles =
                        _items.value
                            .where((file) => selectedIds.contains(file.id))
                            .toList();
                    if (selectedFiles.isEmpty) {
                      return const Center(child: Text('未选中文件'));
                    }
                    return ListView.builder(
                      itemCount: selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = selectedFiles[index];
                        return ListTile(
                          leading: Icon(Icons.insert_drive_file),
                          title: Text(file.name),
                          subtitle: Text('ID: ${file.id}'),
                          onTap: () {
                            _selectedFileNotifier.value = file;
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
