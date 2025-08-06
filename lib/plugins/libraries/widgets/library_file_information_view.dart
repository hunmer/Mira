import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mira/core/utils/utils.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/models/file.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/widgets/checkable_treeview/treeview.dart';
import 'package:path/path.dart' as path;
import 'package:rxdart/rxdart.dart';
import 'dart:async';

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

  // 添加防抖和定时器功能
  final BehaviorSubject<Map<String, dynamic>> _changeSubject =
      BehaviorSubject();
  Timer? _refreshTimer;
  bool _isDataChanged = false;

  @override
  void initState() {
    super.initState();

    // 初始化控制器
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

    // 设置防抖监听器，延迟500ms上传更新
    _changeSubject
        .debounceTime(const Duration(milliseconds: 500))
        .listen(_uploadChanges);

    // 添加文本控制器监听器
    _nameController.addListener(_onDataChanged);
    _notesController.addListener(_onDataChanged);
    _ratingController.addListener(_onDataChanged);
    _tagsController.addListener(_onDataChanged);
    _folderIdController.addListener(_onDataChanged);
    _referenceController.addListener(_onDataChanged);

    // 启动定时获取最新文件数据（每30秒）
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshFileData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _ratingController.dispose();
    _tagsController.dispose();
    _folderIdController.dispose();
    _referenceController.dispose();
    _changeSubject.close();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filePath = widget.file.path!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false, // 移除返回按钮
        title: Text(path.basename(widget.file.name)),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _showAddFolderDialog,
            tooltip: '添加文件夹',
          ),
          IconButton(
            icon: const Icon(Icons.tag),
            onPressed: _showAddTagDialog,
            tooltip: '添加标签',
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
            tooltip: '分享',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    widget.file.thumb != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: buildImageFromUrl(widget.file.thumb!),
                        )
                        : Container(
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            Icons.insert_drive_file,
                            size: 48,
                            color:
                                [
                                      'audio',
                                      'video',
                                    ].contains(widget.file.fileType)
                                    ? Colors.blue
                                    : null,
                          ),
                        ),
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
            // 评分栏
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingBar.builder(
                  initialRating: (widget.file.rating?.toDouble() ?? 0.0).clamp(
                    0.0,
                    5.0,
                  ),
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder:
                      (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    _ratingController.text = rating.toString();
                    _onDataChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(labelText: '来源'),
            ),
          ],
        ),
      ),
    );
  }

  // 数据变更监听器
  void _onDataChanged() {
    if (!_isDataChanged) {
      _isDataChanged = true;
    }

    final changes = <String, dynamic>{
      'name': _nameController.text,
      'notes': _notesController.text.isEmpty ? null : _notesController.text,
      'rating': int.tryParse(_ratingController.text),
      'tags': _tagsController.text.split(',').map((e) => e.trim()).toList(),
      'folderId': _folderIdController.text,
      'reference':
          _referenceController.text.isEmpty ? null : _referenceController.text,
    };

    _changeSubject.add(changes);
  }

  // 上传变更数据
  void _uploadChanges(Map<String, dynamic> changes) async {
    if (!_isDataChanged) return;

    try {
      final libraryInst = widget.plugin.libraryController.getLibraryInst(
        widget.library.id,
      );
      if (libraryInst != null) {
        await libraryInst.updateFile(widget.file.id, changes);
        _isDataChanged = false;
      }
    } catch (e) {
      // 处理错误
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  // 定时刷新文件数据
  void _refreshFileData() async {
    try {
      final libraryInst = widget.plugin.libraryController.getLibraryInst(
        widget.library.id,
      );
      if (libraryInst != null) {
        final updatedFile = await libraryInst.getFile(widget.file.id);
        if (mounted && !_isDataChanged) {
          // 只有在没有本地更改时才更新界面
          setState(() {
            _nameController.text = path.basename(updatedFile.name);
            _notesController.text = updatedFile.notes ?? '';
            _ratingController.text = updatedFile.rating?.toString() ?? '0';
            _tagsController.text = updatedFile.tags.join(', ');
            _folderIdController.text = updatedFile.folderId;
            _referenceController.text = updatedFile.reference ?? '';
          });
        }
      }
    } catch (e) {
      // 忽略刷新错误
    }
  }

  // 显示添加文件夹对话框
  void _showAddFolderDialog() async {
    final result = await widget.plugin.libraryUIController.showFolderSelector(
      widget.library,
      context,
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _folderIdController.text = result.first.id;
        _onDataChanged();
      });
    }
  }

  // 显示添加标签对话框
  void _showAddTagDialog() async {
    final result = await widget.plugin.libraryUIController.showTagSelector(
      widget.library,
      context,
      selectionMode: TreeSelectionMode.multiple,
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        // 添加新选中的标签到现有标签列表
        for (final tag in result) {
          if (!widget.file.tags.contains(tag.id)) {
            widget.file.tags.add(tag.id);
          }
        }
        _tagsController.text = widget.file.tags.join(', ');
        _onDataChanged();
      });
    }
  }
}
