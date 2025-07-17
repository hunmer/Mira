import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/widgets/library_item.dart';
import '../l10n/libraries_localizations.dart';

class LibraryGalleryView extends StatefulWidget {
  final LibrariesPlugin plugin;
  final Library library;

  const LibraryGalleryView({
    required this.plugin,
    required this.library,
    super.key,
  });

  @override
  _LibraryGalleryViewState createState() => _LibraryGalleryViewState();
}

class _LibraryGalleryViewState extends State<LibraryGalleryView> {
  final _uploadingFiles = <String, double>{};

  Future<void> _uploadFiles() async {
    final localizations = LibrariesLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: true, // 尝试读取文件内容
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          _uploadingFiles[file.name] = 0.0;
        }
      });

      try {
        await _batchUploadFiles(result.files);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.uploadComplete)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.uploadFailed}: $e')),
        );
      } finally {
        setState(() {
          _uploadingFiles.clear();
        });
      }
    }
  }

  Future<void> _batchUploadFiles(List<PlatformFile> files) async {
    final completer = Completer<void>();
    final futures = <Future>[];

    for (final file in files) {
      futures.add(_uploadSingleFile(file));
    }

    await Future.wait(futures);
    completer.complete();
    return completer.future;
  }

  Future<void> _uploadSingleFile(PlatformFile file) async {
    await widget.plugin.libraryController.addFileFromPath(file.path!);
  }

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
          IconButton(icon: Icon(Icons.file_upload), onPressed: _uploadFiles),
        ],
      ),
      bottomSheet:
          _uploadingFiles.isNotEmpty
              ? LinearProgressIndicator(
                value:
                    _uploadingFiles.values.reduce((a, b) => a + b) /
                    _uploadingFiles.length,
              )
              : null,
      body: FutureBuilder<List<LibraryFile>>(
        future: widget.plugin.libraryController.getFiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载文件失败: ${snapshot.error}'));
          }
          final files = snapshot.data ?? [];

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return LibraryItem(file: file, onTap: () => {});
            },
          );
        },
      ),
    );
  }
}
