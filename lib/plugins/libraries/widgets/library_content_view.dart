import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view.dart';
import 'package:mira/plugins/libraries/widgets/library_tab_data.dart';

class LibraryContentView extends StatefulWidget {
  final LibraryTabData tabData;

  const LibraryContentView({super.key, required this.tabData});

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
      tabData: widget.tabData, // 传递tabData
    );
  }
}
