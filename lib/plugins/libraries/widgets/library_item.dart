import 'package:flutter/material.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/models/file.dart';
// ignore: depend_on_referenced_packages
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class LibraryItem extends StatelessWidget {
  final LibraryFile file;
  final VoidCallback? onTap;

  const LibraryItem({required this.file, this.onTap, super.key});

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
        child: Card(
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                Expanded(child: Icon(Icons.insert_drive_file, size: 48)),
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
      ),
    );
  }
}
