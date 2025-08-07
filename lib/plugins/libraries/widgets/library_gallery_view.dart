import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
import 'package:mira/plugins/libraries/widgets/file_upload_list_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_file_preview_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_bottom_sheet.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_data.dart';

// 导入分离后的组件
import 'library_gallery_view/index.dart';

/// 图库视图主组件
class LibraryGalleryView extends StatefulWidget {
  final LibraryTabData? tabData; // 添加tabData参数
  final Map<String, ValueNotifier<dynamic>>? dockValues; // 添加dock values参数

  const LibraryGalleryView({
    super.key,
    required this.tabData, // 可选参数
    this.dockValues, // dock values参数
  });

  @override
  LibraryGalleryViewState createState() => LibraryGalleryViewState();
}

class LibraryGalleryViewState extends State<LibraryGalleryView> {
  late LibraryGalleryState _state;
  late LibraryGalleryEvents _events;
  late LibraryGalleryBuilders _builders;
  late final LibrariesPlugin plugin;
  late final Library library;
  late final String tabId;
  late final String itemId;

  @override
  void initState() {
    super.initState();
    plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
    library = widget.tabData!.library;

    // 初始化状态管理
    _state = LibraryGalleryState(tabData: widget.tabData!);
    // 初始化上传队列
    _state.uploadQueue = UploadQueueService(plugin, library);
    _state.progressSubscription = _state.uploadQueue.progressStream.listen((
      completed,
    ) {
      _state.uploadProgressNotifier.value = _state.uploadQueue.progress;
    });

    // 初始化事件处理
    _events = LibraryGalleryEvents(
      state: _state,
      tabData: widget.tabData!,
      plugin: plugin,
      library: library,
    );
    _events.initEvents();

    // 如果提供了dock values，设置值变化监听器
    if (widget.dockValues != null) {
      _events.setupValueListeners(widget.dockValues!);
    }

    _builders = LibraryGalleryBuilders(
      state: _state,
      events: _events,
      plugin: plugin,
      library: library,
      tabData: widget.tabData!,
      onShowDropDialog: _showDropDialog,
      onFileOpen: _onFileOpen,
      onFileSelected: _onFileSelected,
      onToggleSelected: _onToggleSelected,
    );
  }

  @override
  void dispose() {
    _events.dispose();
    _state.dispose();
    super.dispose();
  }

  /// 显示上传对话框
  void _showDropDialog() {
    showDialog(
      context: context,
      builder:
          (context) => FileUploadListDialog(
            plugin: plugin,
            uploadQueue: _state.uploadQueue,
          ),
    );
  }

  /// 文件打开事件处理
  void _onFileOpen(LibraryFile file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => LibraryFilePreviewView(
              plugin: plugin,
              library: library,
              file: file,
            ),
      ),
    );
  }

  /// 文件选中事件处理
  void _onToggleSelected(LibraryFile file) {
    final selectedIds = _state.selectedFileIds.value;
    if (selectedIds.contains(file.id)) {
      selectedIds.remove(file.id);
    } else {
      selectedIds.add(file.id);
    }
    _state.selectedFileIds.value = Set<int>.from(selectedIds);
  }

  /// 文件选中事件处理
  void _onFileSelected(LibraryFile file) {
    _state.selectedFileNotifier.value = file;
    // 如果不是选择模式，默认选中当前文件(bug:会触发选中模式)
    // if (!_state.isSelectionModeNotifier.value) {
    //   _state.selectedFileIds.value = {file.id};
    // }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: plugin.libraryController.loadLibraryInst(library),
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
            return _buildContent();
        }
      },
    );
  }

  /// 构建主要内容
  Widget _buildContent() {
    // 如果tabData为空，使用widget.tabData或创建默认值
    final tabData = _state.tabData;
    if (tabData == null) {
      // 如果仍然没有tabData，创建一个基于当前library的默认tabData
      print('Creating default tabData for library: ${library.name}');
      final defaultTabData = LibraryTabData(
        tabId: widget.tabData!.tabId,
        itemId: widget.tabData!.itemId,
        library: library,
        title: library.name,
        isRecycleBin: false,
        createDate: DateTime.now(),
        stored: {
          'paginationOptions': {'page': 1, 'perPage': 1000},
          'sortOptions': {'field': 'id', 'order': 'desc'},
          'imagesPerRow': 0,
          'filter': {},
          'displayFields': [
            'title',
            'rating',
            'notes',
            'createdAt',
            'tags',
            'folder',
            'size',
            'ext',
          ],
        },
      );
      _state.tabData = defaultTabData;
    }

    final isRecycleBin = (_state.tabData).isRecycleBin;
    final paginationOptions = _state.paginationOptionsNotifier.value;
    final totalPages =
        (_state.totalItemsNotifier.value / paginationOptions['perPage']).ceil();

    if (totalPages > 0 && paginationOptions['page'] > totalPages) {
      _state.paginationOptionsNotifier.value = Map<String, dynamic>.from(
        paginationOptions,
      );
      _state.paginationOptionsNotifier.value['page'] = totalPages;
    }

    return ResponsiveBuilder(
      breakpoints: const ScreenBreakpoints(
        desktop: 800,
        tablet: 600,
        watch: 200,
      ),
      builder: (context, sizingInformation) {
        return Scaffold(
          bottomSheet: LibraryGalleryBottomSheet(
            uploadProgress: _state.uploadProgressNotifier.value,
          ),
          body: Container(
            // 添加一个容器来确保 Docking 布局有适当的边距和样式
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: _builders.buildResponsiveLayout(
              context,
              sizingInformation,
              isRecycleBin,
            ),
          ),
        );
      },
    );
  }
}
