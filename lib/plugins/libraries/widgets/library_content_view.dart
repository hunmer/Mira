import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_manager.dart';

class LibraryContentView extends StatefulWidget {
  final LibrariesPlugin plugin;
  final LibraryTabData tabData;
  final String tabId;

  const LibraryContentView({
    super.key,
    required this.plugin,
    required this.tabData,
    required this.tabId,
  });

  @override
  State<LibraryContentView> createState() => _LibraryContentViewState();
}

class _LibraryContentViewState extends State<LibraryContentView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LibraryGalleryView(
      plugin: widget.plugin,
      tabId: widget.tabId,
      library: widget.tabData.library,
    );
  }
}
