import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager.dart';

class LibraryContentView extends StatefulWidget {
  final LibrariesPlugin plugin;
  final LibraryTabData tabData;

  const LibraryContentView({
    super.key,
    required this.plugin,
    required this.tabData,
  });

  @override
  State<LibraryContentView> createState() => _LibraryContentViewState();
}

class _LibraryContentViewState extends State<LibraryContentView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // 缓存LibraryGalleryView实例，避免重复创建
  late final Widget _cachedGalleryView;

  @override
  void initState() {
    super.initState();
    // 初始化时创建一次LibraryGalleryView
    _cachedGalleryView = LibraryGalleryView(
      plugin: widget.plugin,
      tabId: widget.tabData.id,
      library: widget.tabData.library,
      tabData: widget.tabData,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _cachedGalleryView;
  }
}
