import 'package:flutter/material.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:path/path.dart' as path;

class LibraryFileInformationView extends StatefulWidget {
  final LibraryFile file;
  final Library library;
  final LibrariesPlugin plugin;

  const LibraryFileInformationView({
    required this.plugin,
    required this.library,
    required this.file,
    super.key,
  });

  @override
  State<LibraryFileInformationView> createState() =>
      _LibraryFileInformationViewState();
}

class _LibraryFileInformationViewState
    extends State<LibraryFileInformationView> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _ratingController;
  late TextEditingController _tagsController;
  late TextEditingController _folderIdController;
  late TextEditingController _referenceController;
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _ratingController.dispose();
    _tagsController.dispose();
    _folderIdController.dispose();
    _referenceController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _nameController = TextEditingController(
      text: path.basename(widget.file.name),
    );
    _notesController = TextEditingController(text: widget.file.notes);
    _ratingController = TextEditingController(
      text: widget.file.rating?.toString() ?? '0',
    );
    _tagsController = TextEditingController(text: widget.file.tags.join(', '));
    _folderIdController = TextEditingController(text: widget.file.folderId);
    _referenceController = TextEditingController(text: widget.file.reference);
    _urlController = TextEditingController(text: widget.file.url);
    final filePath = widget.file.path!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveChanges,
                    ),
                    if (!filePath.startsWith('http'))
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () => openFileLocation(filePath),
                        tooltip: '打开文件所在位置',
                      ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child:
                  widget.file.thumb != null
                      ? buildImageFromUrl(widget.file.thumb!)
                      : Icon(
                        Icons.insert_drive_file,
                        size: 48,
                        color:
                            ['audio', 'video'].contains(widget.file.fileType)
                                ? Colors.blue
                                : null,
                      ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children:
                  widget.file.tags
                      .map(
                        (tag) => FutureBuilder<String>(
                          future: widget.plugin.foldersTagsController
                              .getTagTitleById(widget.library.id, tag),
                          builder: (context, snapshot) {
                            return InputChip(
                              label: Text(snapshot.data ?? tag),
                              onDeleted: () {
                                setState(() {
                                  widget.file.tags.remove(tag);
                                  _tagsController.text = widget.file.tags.join(
                                    ', ',
                                  );
                                });
                              },
                            );
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),
            if (widget.file.folderId.isNotEmpty)
              FutureBuilder<String>(
                future: widget.plugin.foldersTagsController.getFolderTitleById(
                  widget.library.id,
                  widget.file.folderId,
                ),
                builder: (context, snapshot) {
                  return InputChip(
                    label: Text(snapshot.data ?? widget.file.folderId),
                    avatar: const Icon(Icons.folder),
                    onDeleted: () {
                      setState(() {
                        _folderIdController.text = '';
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '文件名'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: '备注'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ratingController,
              decoration: const InputDecoration(labelText: '评分 (0-5)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(labelText: '引用'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _saveChanges() {
    final updatedFile = LibraryFile(
      id: widget.file.id,
      name: _nameController.text,
      createdAt: widget.file.createdAt,
      importedAt: widget.file.importedAt,
      size: widget.file.size,
      hash: widget.file.hash,
      customFields: widget.file.customFields,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      rating: int.tryParse(_ratingController.text),
      tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
      folderId: _folderIdController.text,
      reference:
          _referenceController.text.isEmpty ? null : _referenceController.text,
      url: _urlController.text.isEmpty ? null : _urlController.text,
      path: widget.file.path,
      thumb: widget.file.thumb,
    );

    Navigator.of(context).pop(updatedFile);
  }
}
