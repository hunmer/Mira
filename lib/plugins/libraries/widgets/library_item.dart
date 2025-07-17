import 'package:flutter/material.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class LibraryItem extends StatelessWidget {
  final LibraryFile file;
  final bool isSelected;
  final bool useThumbnail;
  final VoidCallback? onTap;

  const LibraryItem({
    required this.file,
    this.isSelected = false,
    this.useThumbnail = false,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
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
                                  ? Image.network(
                                    file.thumb!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.insert_drive_file,
                                          size: 48,
                                        ),
                                  )
                                  : Icon(
                                    Icons.insert_drive_file,
                                    size: 48,
                                    color:
                                        [
                                              'audio',
                                              'video',
                                            ].contains(file.type?.toLowerCase())
                                            ? Colors.blue
                                            : null,
                                  ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      child: Icon(Icons.check, color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
