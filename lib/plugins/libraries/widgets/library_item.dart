import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/widgets/icon_chip.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class LibraryItem extends StatelessWidget {
  final LibraryFile file;
  final bool isSelected;
  final bool useThumbnail;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  final Future<String> Function(String) getFolderTitle;
  final Future<String> Function(String) getTagTilte;
  final Set<String> displayFields;

  const LibraryItem({
    required this.file,
    this.isSelected = false,
    this.useThumbnail = false,
    required this.getFolderTitle,
    required this.getTagTilte,
    this.onTap,
    this.onDoubleTap,
    required this.onLongPress,
    required this.displayFields,
    super.key,
  });

  final Function(dynamic) onLongPress;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        getFolderTitle(file.folderId),
        Future.wait(file.tags.map((tag) => getTagTilte(tag)).toList()),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        final folderTitle = snapshot.data![0] as String;
        final tagTitles = snapshot.data![1] as List<String>;
        return DragItemWidget(
          dragItemProvider: (request) async {
            final item = DragItem(
              localData: {'fileId': file.id},
              suggestedName: file.name,
            );
            if (file.path != null) {
              final path = filePathToUri(file.path!);
              item.add(Formats.fileUri(Uri.tryParse(path)!));
            }
            return item;
          },
          allowedOperations: () => [DropOperation.copy],
          child: DraggableWidget(
            child: GestureDetector(
              onSecondaryTapDown: (details) => onLongPress(details),
              onLongPressDown:
                  kIsWeb ? onLongPress(LongPressDownDetails) : null,
              child: Card(
                child: Stack(
                  children: [
                    InkWell(
                      onTap: onTap,
                      onDoubleTap: onDoubleTap,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 100;
                          return SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [
                                Expanded(
                                  child:
                                      useThumbnail && file.thumb != null
                                          ? buildImageFromUrl(file.thumb!)
                                          : Icon(
                                            Icons.insert_drive_file,
                                            size: 48,
                                            color:
                                                ['audio', 'video'].contains(
                                                      file.type?.toLowerCase(),
                                                    )
                                                    ? Colors.blue
                                                    : null,
                                          ),
                                ),
                                if (!isCompact)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (displayFields.contains('title'))
                                          Text(
                                            file.path!
                                                .replaceAll('\\', '/')
                                                .split('/')
                                                .last
                                                .split('.')
                                                .first,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                        if (displayFields.contains('notes') &&
                                            file.notes != null)
                                          Text(
                                            file.notes!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                        if (displayFields.contains('createdAt'))
                                          Text(
                                            '创建: ${file.createdAt.toString().split(' ')[0]}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                        if (displayFields.contains('size'))
                                          Text(
                                            '大小: ${(file.size / 1024).toStringAsFixed(1)}KB',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                        if (displayFields.any(
                                          (field) => [
                                            'rating',
                                            'folder',
                                            'tags',
                                          ].contains(field),
                                        ))
                                          Wrap(
                                            spacing: 4,
                                            children: [
                                              if (displayFields.contains(
                                                    'rating',
                                                  ) &&
                                                  file.rating != null &&
                                                  file.rating! > 0)
                                                IconChip(
                                                  icon: Icons.star,
                                                  label: '${file.rating}/5',
                                                  iconColor: Colors.amber,
                                                ),
                                              if (displayFields.contains(
                                                    'folder',
                                                  ) &&
                                                  folderTitle.isNotEmpty)
                                                IconChip(
                                                  icon: Icons.folder,
                                                  label: folderTitle,
                                                ),
                                              if (displayFields.contains(
                                                    'tags',
                                                  ) &&
                                                  file.tags.isNotEmpty)
                                                ...tagTitles
                                                    .where((t) => t.isNotEmpty)
                                                    .map(
                                                      (tag) => IconChip(
                                                        icon: Icons.label,
                                                        label: tag,
                                                      ),
                                                    ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insert_drive_file,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            SizedBox(width: 4),
                            Text(
                              file.path!.split('.').last.toUpperCase(),
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
