import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_builder/responsive_builder.dart';
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
  final FocusNode _keyboardFocusNode = FocusNode();

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
  int? _lastSelectedIndex; // 用于Shift范围选择的最后选中文件索引

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

    // 监听选择模式状态变化，当退出选择模式时重置最后选中索引
    _isSelectionModeNotifier.addListener(() {
      if (!_isSelectionModeNotifier.value) {
        _lastSelectedIndex = null;
      }
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
    _keyboardFocusNode.dispose();
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
    _onFileSelectedWithModifiers(file, false, false);
  }

  void _onFileSelectedWithModifiers(
    LibraryFile file,
    bool isCtrlPressed,
    bool isShiftPressed,
  ) {
    final fileId = file.id;
    final fileIndex = _items.value.indexWhere((item) => item.id == fileId);

    if (_isSelectionModeNotifier.value) {
      final currentSelection = Set<int>.from(_selectedFileIds.value);

      if (isShiftPressed && _lastSelectedIndex != null) {
        // Shift范围选择
        final startIndex = _lastSelectedIndex!;
        final endIndex = fileIndex;
        final minIndex = startIndex < endIndex ? startIndex : endIndex;
        final maxIndex = startIndex > endIndex ? startIndex : endIndex;

        // 选择范围内的所有文件
        for (int i = minIndex; i <= maxIndex; i++) {
          if (i < _items.value.length) {
            currentSelection.add(_items.value[i].id);
          }
        }
      } else if (isCtrlPressed) {
        // Ctrl多选：切换选中状态
        if (currentSelection.contains(fileId)) {
          currentSelection.remove(fileId);
        } else {
          currentSelection.add(fileId);
        }
        _lastSelectedIndex = fileIndex;
      } else {
        // 普通点击：切换选中状态
        if (currentSelection.contains(fileId)) {
          currentSelection.remove(fileId);
        } else {
          currentSelection.add(fileId);
        }
        _lastSelectedIndex = fileIndex;
      }

      _selectedFileIds.value = currentSelection;

      // 如果选中的文件数量<=1，关闭选择模式
      if (currentSelection.length <= 1) {
        _isSelectionModeNotifier.value = false;
        if (currentSelection.isEmpty) {
          _lastSelectedIndex = null;
        }
      }
    } else {
      // 非选择模式下，如果按住Ctrl或Shift，进入选择模式
      if (isCtrlPressed || isShiftPressed) {
        _isSelectionModeNotifier.value = true;
        _selectedFileIds.value = {fileId};
        _lastSelectedIndex = fileIndex;
      }
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
    final paginationOptions = _paginationOptionsNotifier.value;
    final totalPages =
        (_totalItemsNotifier.value / paginationOptions['perPage']).ceil();
    if (totalPages > 0 && paginationOptions['page'] > totalPages) {
      _paginationOptionsNotifier.value = Map<String, dynamic>.from(
        paginationOptions,
      );
      _paginationOptionsNotifier.value['page'] = totalPages;
    }

    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        return Scaffold(
          bottomSheet: LibraryGalleryBottomSheet(
            uploadProgress: _uploadProgressNotifier.value,
          ),
          body: _buildResponsiveLayout(sizingInformation, isRecycleBin),
        );
      },
    );
  }

  Widget _buildResponsiveLayout(
    SizingInformation sizingInformation,
    bool isRecycleBin,
  ) {
    // 根据设备类型决定显示哪些组件
    switch (sizingInformation.deviceScreenType) {
      case DeviceScreenType.mobile:
        // 手机：只显示主内容（画廊）
        return _buildMainContent(
          isRecycleBin,
          sizingInformation.screenSize.width,
        );

      case DeviceScreenType.tablet:
        // 平板：显示侧边栏 + 主内容
        return Row(
          children: [
            // Sidebar Section
            Flexible(
              flex: 1,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: _buildSidebarSection(
                    sizingInformation.screenSize.width,
                  ),
                ),
              ),
            ),
            // Main Content
            Flexible(
              flex: 6,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: _buildMainContent(
                    isRecycleBin,
                    sizingInformation.screenSize.width,
                  ),
                ),
              ),
            ),
          ],
        );

      case DeviceScreenType.desktop:
        // 桌面：显示所有组件
        return Row(
          children: [
            // Quick Actions (左侧信息栏)
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(6),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: _buildQuickActions(),
              ),
            ),
            // Sidebar Section (左侧栏)
            Flexible(
              flex: 1,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: _buildSidebarSection(
                    sizingInformation.screenSize.width,
                  ),
                ),
              ),
            ),
            // Main Content (主内容)
            Flexible(
              flex: 6,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: _buildMainContent(
                    isRecycleBin,
                    sizingInformation.screenSize.width,
                  ),
                ),
              ),
            ),
            // File Details Section (右侧信息栏)
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
            // AppBar Actions (右侧栏)
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(6),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: _buildAppBarActions(),
              ),
            ),
          ],
        );

      case DeviceScreenType.watch:
      default:
        // 手表或其他小屏设备：只显示主内容
        return _buildMainContent(
          isRecycleBin,
          sizingInformation.screenSize.width,
        );
    }
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
  }

  Widget _buildMainContent(bool isRecycleBin, double screenWidth) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        return Scaffold(
          // 为移动设备添加浮动操作按钮
          floatingActionButton:
              sizingInformation.deviceScreenType == DeviceScreenType.mobile
                  ? _buildMobileFloatingActions()
                  : null,
          body: Column(
            children: [
              // 为移动设备显示简化的顶部操作栏
              if (sizingInformation.deviceScreenType == DeviceScreenType.mobile)
                _buildMobileTopBar(),
              Expanded(
                child: Stack(
                  children: [
                    // 只在桌面端启用键盘监听
                    sizingInformation.deviceScreenType ==
                            DeviceScreenType.desktop
                        ? KeyboardListener(
                          focusNode: _keyboardFocusNode,
                          autofocus: true,
                          child: MultiValueListenableBuilder(
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
                                onFileSelected: (file) {
                                  final isCtrlPressed =
                                      HardwareKeyboard
                                          .instance
                                          .isControlPressed;
                                  final isShiftPressed =
                                      HardwareKeyboard.instance.isShiftPressed;
                                  _onFileSelectedWithModifiers(
                                    file,
                                    isCtrlPressed,
                                    isShiftPressed,
                                  );
                                },
                                onFileOpen: _onFileOpen,
                                imagesPerRow: values[4] as int,
                                scrollController: _scrollController,
                              );
                            },
                          ),
                        )
                        : MultiValueListenableBuilder(
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
          ),
        );
      },
    );
  }

  // 移动设备专用的浮动操作按钮
  Widget _buildMobileFloatingActions() {
    return FloatingActionButton(
      heroTag: "upload",
      onPressed: _showDropDialog,
      tooltip: '上传',
      child: Icon(Icons.add),
    );
  }

  // 移动设备专用的顶部操作栏
  Widget _buildMobileTopBar() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // 第一行：标题和基本操作
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.library.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _refresh,
                tooltip: '刷新',
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _isSelectionModeNotifier,
                builder: (context, isSelectionMode, _) {
                  return IconButton(
                    icon: Icon(isSelectionMode ? Icons.close : Icons.check_box),
                    onPressed:
                        () => _isSelectionModeNotifier.value = !isSelectionMode,
                    tooltip: isSelectionMode ? '退出选择' : '多选',
                  );
                },
              ),
            ],
          ),
          // 第二行：快捷操作图标
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => _showMobileSidebarDialog(),
                  tooltip: '侧边栏',
                ),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () => _showMobileFilterDialog(),
                  tooltip: '筛选',
                ),
                IconButton(
                  icon: Icon(Icons.folder),
                  onPressed: () async {
                    final result = await widget.plugin.libraryUIController
                        .showFolderSelector(widget.library, context);
                    if (result != null && result.isNotEmpty) {}
                  },
                  tooltip: '文件夹',
                ),
                IconButton(
                  icon: Icon(Icons.label),
                  onPressed: () async {
                    final result = await widget.plugin.libraryUIController
                        .showTagSelector(widget.library, context);
                    if (result != null && result.isNotEmpty) {}
                  },
                  tooltip: '标签',
                ),
                IconButton(
                  icon: Icon(Icons.favorite),
                  onPressed: () {},
                  tooltip: '收藏',
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _tabManager.addTab(
                      widget.library,
                      isRecycleBin: true,
                      title: '回收站',
                    );
                  },
                  tooltip: '回收站',
                ),
                IconButton(
                  icon: Icon(Icons.sort),
                  onPressed: () => _showMobileSortDialog(),
                  tooltip: '排序',
                ),
                IconButton(
                  icon: Icon(Icons.view_module),
                  onPressed: () => _showMobileDisplayDialog(),
                  tooltip: '显示选项',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 显示移动设备的侧边栏对话框
  void _showMobileSidebarDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: EdgeInsets.all(16),
                  child: MultiValueListenableBuilder(
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
                        tagsSelected: List<String>.from(
                          filterOptions['tags'] ?? [],
                        ),
                        folders: folders,
                        folderSelected:
                            filterOptions['folder'] is String
                                ? [filterOptions['folder']]
                                : [],
                      );
                    },
                  ),
                ),
          ),
    );
  }

  // 显示移动设备的简化筛选对话框
  void _showMobileFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('筛选选项', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: '文件名',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    final currentFilter = Map<String, dynamic>.from(
                      _filterOptionsNotifier.value,
                    );
                    currentFilter['name'] = value;
                    _filterOptionsNotifier.value = currentFilter;
                    _tabManager.updateFilter(widget.tabId, currentFilter);
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showMobileSidebarDialog();
                        },
                        icon: Icon(Icons.label),
                        label: Text('标签筛选'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 清除筛选
                          final defaultFilter = {
                            'name': '',
                            'tags': [],
                            'folder': '',
                          };
                          _filterOptionsNotifier.value = defaultFilter;
                          _tabManager.updateFilter(widget.tabId, defaultFilter);
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.clear),
                        label: Text('清除'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  // 显示移动设备的排序对话框
  void _showMobileSortDialog() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(16),
            child: ValueListenableBuilder<Map<String, dynamic>>(
              valueListenable: _sortOptionsNotifier,
              builder: (context, sortOptions, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('排序选项', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('按名称'),
                      leading: Radio<String>(
                        value: 'name',
                        groupValue: sortOptions['sort'],
                        onChanged:
                            (value) =>
                                _updateSort(value!, sortOptions['order']),
                      ),
                    ),
                    ListTile(
                      title: Text('按导入时间'),
                      leading: Radio<String>(
                        value: 'imported_at',
                        groupValue: sortOptions['sort'],
                        onChanged:
                            (value) =>
                                _updateSort(value!, sortOptions['order']),
                      ),
                    ),
                    ListTile(
                      title: Text('按大小'),
                      leading: Radio<String>(
                        value: 'size',
                        groupValue: sortOptions['sort'],
                        onChanged:
                            (value) =>
                                _updateSort(value!, sortOptions['order']),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => _updateSort(sortOptions['sort'], 'asc'),
                            icon: Icon(Icons.arrow_upward),
                            label: Text('升序'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  sortOptions['order'] == 'asc'
                                      ? Theme.of(context).primaryColor
                                      : null,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => _updateSort(sortOptions['sort'], 'desc'),
                            icon: Icon(Icons.arrow_downward),
                            label: Text('降序'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  sortOptions['order'] == 'desc'
                                      ? Theme.of(context).primaryColor
                                      : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  // 显示移动设备的显示选项对话框
  void _showMobileDisplayDialog() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(16),
            child: ValueListenableBuilder<int>(
              valueListenable: _imagesPerRowNotifier,
              builder: (context, imagesPerRow, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('显示选项', style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 16),
                    Text('每行图片数量'),
                    Slider(
                      value: imagesPerRow == 0 ? 3 : imagesPerRow.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      label: imagesPerRow == 0 ? '自动' : imagesPerRow.toString(),
                      onChanged: (value) {
                        _imagesPerRowNotifier.value = value.round();
                        _tabManager.setStoreValue(
                          widget.tabId,
                          'imagesPerRow',
                          value.round(),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('确定'),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  // 更新排序选项的辅助方法
  void _updateSort(String sort, String order) {
    final newSortOptions = {'sort': sort, 'order': order};
    _sortOptionsNotifier.value = newSortOptions;
    _tabManager.setStoreValue(widget.tabId, 'sortOptions', newSortOptions);
    _loadFiles();
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
