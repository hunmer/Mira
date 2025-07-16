import 'package:flutter/material.dart';
import '../models/library.dart';
import '../l10n/libraries_localizations.dart';

class LibraryEditView extends StatefulWidget {
  final Library? library;
  final Function(Library) onSave;

  const LibraryEditView({this.library, required this.onSave, Key? key})
    : super(key: key);

  @override
  _LibraryEditViewState createState() => _LibraryEditViewState();
}

class _LibraryEditViewState extends State<LibraryEditView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.library?.name ?? '');
    _typeController = TextEditingController(text: widget.library?.type ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LibrariesLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.library == null
              ? localizations.createLibrary
              : localizations.editLibrary,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(labelText: 'Type'),
              ),
              // TODO: 添加自定义字段编辑器
              Spacer(),
              ElevatedButton(onPressed: _saveLibrary, child: Text('Save')),
            ],
          ),
        ),
      ),
    );
  }

  void _saveLibrary() {
    if (_formKey.currentState!.validate()) {
      final library = Library(
        id: widget.library?.id ?? DateTime.now().toIso8601String(),
        name: _nameController.text,
        type: _typeController.text,
        icon: '', // TODO: 添加图标选择
        customFields: {},
        createdAt: widget.library?.createdAt ?? DateTime.now(),
      );
      widget.onSave(library);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }
}
