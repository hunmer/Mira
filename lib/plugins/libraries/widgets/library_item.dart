import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class LibraryItem extends StatelessWidget {
  final LibraryFile file;
  final bool isSelected;
  final bool useThumbnail;
  final VoidCallback? onTap;
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
    this.onLongPress,
    this.displayFields = const {
      'title',
      'cover',
      'rating',
      'notes',
      'createdAt',
      'tags',
      'folder',
      'size',
    },
    super.key,
  });

  final VoidCallback? onLongPress;

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

            // 添加文件路径或URL到payload
            if (file.path != null) {
              final path = filePathToUri(file.path!);
              item.add(Formats.fileUri(Uri.tryParse(path)!));
            }
            return item;
          },
          allowedOperations: () => [DropOperation.copy],
          child: DraggableWidget(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Card(
                child: Stack(
                  children: [
                    InkWell(
                      onTap: onTap,
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            Expanded(
                              child:
                                  useThumbnail && file.thumb != null
                                      ? file.thumb!.startsWith('http')
                                          ? Image.network(
                                            file.thumb!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      Icons.insert_drive_file,
                                                      size: 48,
                                                    ),
                                          )
                                          : Image.file(
                                            File(file.thumb!),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      Icons.insert_drive_file,
                                                      size: 48,
                                                    ),
                                          )
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
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (displayFields.contains('title'))
                                    Text(
                                      file.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (displayFields.contains('rating') &&
                                      file.rating != null)
                                    Row(
                                      children: List.generate(
                                        5,
                                        (index) => Icon(
                                          index < file.rating!
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  if (displayFields.contains('notes') &&
                                      file.notes != null)
                                    Text(
                                      file.notes!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  if (displayFields.contains('createdAt'))
                                    Text(
                                      '创建: ${file.createdAt.toString().split(' ')[0]}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  if (displayFields.contains('size'))
                                    Text(
                                      '大小: ${(file.size / 1024).toStringAsFixed(1)}KB',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  if (displayFields.contains('tags') &&
                                      file.tags.isNotEmpty)
                                    Text(
                                      '标签: ${tagTitles.join(', ')}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  if (displayFields.contains('folder'))
                                    Text(
                                      '文件夹: ${folderTitle}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
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
