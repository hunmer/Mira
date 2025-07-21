import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/l10n/libraries_localizations.dart';

class LibraryGalleryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onExitSelection;
  final VoidCallback onFilter;
  final VoidCallback onEnterSelection;
  final VoidCallback onUpload;
  final double uploadProgress;
  final Set<String> displayFields;
  final ValueChanged<Set<String>> onDisplayFieldsChanged;
  final int imagesPerRow;
  final ValueChanged<int> onImagesPerRowChanged;
  final VoidCallback onRefresh;

  const LibraryGalleryAppBar({
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onExitSelection,
    required this.onFilter,
    required this.onEnterSelection,
    required this.onUpload,
    required this.uploadProgress,
    required this.displayFields,
    required this.onDisplayFieldsChanged,
    required this.imagesPerRow,
    required this.onImagesPerRowChanged,
    required this.onRefresh,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final localizations = LibrariesLocalizations.of(context);
    if (localizations == null) return Container();

    return AppBar(
      title: Text(isSelectionMode ? '已选择 $selectedCount 项' : ''),
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
                      icon: Icon(Icons.file_upload),
                      onPressed: onUpload,
                    ),
                    if (uploadProgress > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child:
                              uploadProgress == 1
                                  ? const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.green,
                                  )
                                  : Text(
                                    '${uploadProgress * 100}%',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                        ),
                      ),
                  ],
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.grid_view),
                  itemBuilder:
                      (context) =>
                          [1, 2, 3, 4, 5].map((count) {
                            return CheckedPopupMenuItem<int>(
                              value: count,
                              checked: imagesPerRow == count,
                              child: Text('每行 $count 张'),
                            );
                          }).toList(),
                  onSelected: (count) {
                    onImagesPerRowChanged(count);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                ),
              ],
    );
  }
}
