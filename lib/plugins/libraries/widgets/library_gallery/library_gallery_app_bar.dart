import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/l10n/libraries_localizations.dart';

class LibraryGalleryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onExitSelection;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback onEnterSelection;
  final VoidCallback onUpload;
  final VoidCallback onShowUploadQueue;
  final VoidCallback onFolder;
  final VoidCallback onTag;
  final int pendingUploadCount;

  const LibraryGalleryAppBar({
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onExitSelection,
    required this.onSearch,
    required this.onFilter,
    required this.onEnterSelection,
    required this.onUpload,
    required this.onShowUploadQueue,
    required this.onFolder,
    required this.onTag,
    required this.pendingUploadCount,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final localizations = LibrariesLocalizations.of(context);
    if (localizations == null) return Container();

    return AppBar(
      title: Text(
        isSelectionMode ? '已选择 $selectedCount 项' : localizations.filesTitle,
      ),
      automaticallyImplyLeading: false,
      actions:
          isSelectionMode
              ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: onSelectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onExitSelection,
                ),
              ]
              : [
                IconButton(icon: const Icon(Icons.search), onPressed: onSearch),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: onFilter,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.check_box),
                  onPressed: onEnterSelection,
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.file_upload),
                      onPressed: onUpload,
                    ),
                    if (pendingUploadCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$pendingUploadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  onPressed: onShowUploadQueue,
                ),
                IconButton(icon: const Icon(Icons.folder), onPressed: onFolder),
                IconButton(icon: const Icon(Icons.tag), onPressed: onTag),
              ],
    );
  }
}
