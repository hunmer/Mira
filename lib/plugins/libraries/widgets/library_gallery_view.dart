import 'package:flutter/material.dart';
import '../models/file.dart';
import '../l10n/libraries_localizations.dart';

class LibraryGalleryView extends StatelessWidget {
  final List<LibraryFile> files;
  final Function(LibraryFile) onFileSelected;

  const LibraryGalleryView({
    required this.files,
    required this.onFileSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = LibrariesLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.filesTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // TODO: 实现过滤功能
            },
          ),
        ],
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return Card(
            child: InkWell(
              onTap: () => onFileSelected(file),
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
          );
        },
      ),
    );
  }
}
