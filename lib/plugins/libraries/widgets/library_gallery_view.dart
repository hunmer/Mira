import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/services/upload_queue_service.dart';
import 'package:mira/plugins/libraries/widgets/file_upload_list_dialog.dart';
import 'package:mira/plugins/libraries/widgets/library_file_preview_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery/library_gallery_bottom_sheet.dart';

// 导入分离后的组件
import 'library_gallery_view/index.dart';

/// 图库视图主组件
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
  late LibraryGalleryState _state;
  late LibraryGalleryEvents _events;
  late LibraryGalleryBuilders _builders;
  late LibraryGalleryMobile _mobile;

  @override
  void initState() {
    super.initState();

    // 初始化状态管理
    _state = LibraryGalleryState();
    _state.initializeState(widget.tabId, widget.plugin.tabManager);

    // 初始化上传队列
    _state.uploadQueue = UploadQueueService(widget.plugin, widget.library);
    _state.progressSubscription = _state.uploadQueue.progressStream.listen((
      completed,
    ) {
      _state.uploadProgressNotifier.value = _state.uploadQueue.progress;
    });

    // 初始化事件处理
    _events = LibraryGalleryEvents(
      state: _state,
      plugin: widget.plugin,
      library: widget.library,
      tabId: widget.tabId,
    );
    _events.initEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 在这里初始化需要context的组件
    _builders = LibraryGalleryBuilders(
      state: _state,
      events: _events,
      plugin: widget.plugin,
      library: widget.library,
      tabId: widget.tabId,
      context: context,
      onShowDropDialog: _showDropDialog,
      onFileOpen: _onFileOpen,
      onFileSelected: _onFileSelected,
      onToggleSelected: _onToggleSelected,
    );

    _mobile = LibraryGalleryMobile(
      state: _state,
      events: _events,
      plugin: widget.plugin,
      library: widget.library,
      tabId: widget.tabId,
      context: context,
      onShowDropDialog: _showDropDialog,
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
            plugin: widget.plugin,
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
              plugin: widget.plugin,
              library: widget.library,
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
    // 如果不是选择模式，默认选中当前文件
    if (!_state.isSelectionModeNotifier.value) {
      _state.selectedFileIds.value = {file.id};
    }
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return FutureBuilder<dynamic>(
      future: widget.plugin.libraryController.loadLibraryInst(widget.library),
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
    final isRecycleBin = _state.tabData!.isRecycleBin;
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
      builder: (context, sizingInformation) {
        return Scaffold(
          bottomSheet: LibraryGalleryBottomSheet(
            uploadProgress: _state.uploadProgressNotifier.value,
          ),
          body: _buildResponsiveBody(sizingInformation, isRecycleBin),
        );
      },
    );
  }

  /// 构建响应式主体内容
  Widget _buildResponsiveBody(
    SizingInformation sizingInformation,
    bool isRecycleBin,
  ) {
    // 针对移动设备的特殊处理
    if (sizingInformation.deviceScreenType == DeviceScreenType.mobile) {
      return _buildMobileLayout(
        isRecycleBin,
        sizingInformation.screenSize.width,
      );
    }

    // 其他设备使用通用布局构建器
    return _builders.buildResponsiveLayout(sizingInformation, isRecycleBin);
  }

  /// 构建移动端布局
  Widget _buildMobileLayout(bool isRecycleBin, double screenWidth) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        return Scaffold(
          floatingActionButton: _mobile.buildMobileFloatingActions(),
          body: Column(
            children: [
              _mobile.buildMobileTopBar(),
              Expanded(child: _buildMobileMainContent(isRecycleBin)),
              _builders.buildPagination(),
            ],
          ),
        );
      },
    );
  }

  /// 构建移动端主内容
  Widget _buildMobileMainContent(bool isRecycleBin) {
    return Stack(
      children: [
        _builders.buildGalleryBodyWithDragSelect(),
        ValueListenableBuilder(
          valueListenable: _state.isItemsLoadingNotifier,
          builder: (context, isLoading, _) {
            return isLoading
                ? Center(child: CircularProgressIndicator())
                : SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
