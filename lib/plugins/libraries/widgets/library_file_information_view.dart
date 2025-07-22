import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:path/path.dart' as path;

class LibraryFileInformationView extends StatefulWidget {
  final LibraryFile file;

  const LibraryFileInformationView({required this.file, super.key});

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
    _nameController = TextEditingController(
      text: path.basename(widget.file.path!),
    );
    _notesController = TextEditingController(text: widget.file.notes);
    _ratingController = TextEditingController(
      text: widget.file.rating?.toString() ?? '0',
    );
    _tagsController = TextEditingController(text: widget.file.tags.join(', '));
    _folderIdController = TextEditingController(text: widget.file.folderId);
    _referenceController = TextEditingController(text: widget.file.reference);
    _urlController = TextEditingController(text: widget.file.url);
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
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(path.basename(widget.file.name)),
      //   automaticallyImplyLeading: false,
      //   actions: [
      //     // IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
      //     IconButton(icon: const Icon(Icons.share), onPressed: () => {}),
      //   ],
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child:
                  widget.file.thumb != null
                      ? buildImageFromUrl(widget.file.thumb!)
                      : Icon(
                        Icons.insert_drive_file,
                        size: 48,
                        color:
                            [
                                  'audio',
                                  'video',
                                ].contains(widget.file.type?.toLowerCase())
                                ? Colors.blue
                                : null,
                      ),
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
              controller: _tagsController,
              decoration: const InputDecoration(labelText: '标签 (用逗号分隔)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _folderIdController,
              decoration: const InputDecoration(labelText: '文件夹ID'),
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
      type: widget.file.type,
    );

    Navigator.of(context).pop(updatedFile);
  }
}
