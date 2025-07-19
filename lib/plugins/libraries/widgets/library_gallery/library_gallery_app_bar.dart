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
  final VoidCallback onShowUploadQueue;
  final VoidCallback onFolder;
  final VoidCallback onTag;
  final int pendingUploadCount;
  final Set<String> displayFields;
  final ValueChanged<Set<String>> onDisplayFieldsChanged;
  final int imagesPerRow;
  final ValueChanged<int> onImagesPerRowChanged;

  const LibraryGalleryAppBar({
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onExitSelection,
    required this.onFilter,
    required this.onEnterSelection,
    required this.onUpload,
    required this.onShowUploadQueue,
    required this.onFolder,
    required this.onTag,
    required this.pendingUploadCount,
    required this.displayFields,
    required this.onDisplayFieldsChanged,
    required this.imagesPerRow,
    required this.onImagesPerRowChanged,
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
                if (pendingUploadCount > 0)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.file_upload),
                        onPressed: onUpload,
                      ),

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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.view_column),
                  itemBuilder:
                      (context) =>
                          [
                            'title',
                            'cover',
                            'rating',
                            'notes',
                            'createdAt',
                            'tags',
                            'folder',
                            'size',
                          ].map((field) {
                            return CheckedPopupMenuItem<String>(
                              value: field,
                              checked: displayFields.contains(field),
                              child: Text(field),
                            );
                          }).toList(),
                  onSelected: (field) {
                    final newFields = Set<String>.from(displayFields);
                    if (newFields.contains(field)) {
                      newFields.remove(field);
                    } else {
                      newFields.add(field);
                    }
                    onDisplayFieldsChanged(newFields);
                  },
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
              ],
    );
  }
}
