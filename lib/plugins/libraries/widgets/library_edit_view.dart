import 'package:flutter/material.dart';
import 'package:mira/plugins/libraries/models/library.dart';
import 'package:mira/plugins/libraries/l10n/libraries_localizations.dart';
import 'package:file_picker/file_picker.dart';

class LibraryEditView extends StatefulWidget {
  final Library? library;
  const LibraryEditView({super.key, this.library});

  @override
  // ignore: library_private_types_in_public_api
  _LibraryEditViewState createState() => _LibraryEditViewState();
}

class _LibraryEditViewState extends State<LibraryEditView> {
  final _formKey = GlobalKey<FormState>();
  late LibraryType _selectedType;
  late final TextEditingController _nameController;
  late final TextEditingController _serverController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late String _localPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _serverController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _localPath = '';

    if (widget.library != null) {
      final library = widget.library!;
      _nameController.text = library.name;
      _selectedType =
          library.type == 'local' ? LibraryType.local : LibraryType.network;

      if (_selectedType == LibraryType.local) {
        _localPath = library.customFields['path'] ?? '';
      } else {
        _serverController.text = library.customFields['server'] ?? '';
        _usernameController.text = library.customFields['username'] ?? '';
        _passwordController.text = library.customFields['password'] ?? '';
      }
    } else {
      _selectedType = LibraryType.local;
    }
  }

  Future<void> _pickFolder() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Warning'),
              content: Text('Location cannot be changed in android'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
      );
      return;
    }
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _localPath = result;
      });
    }
  }

  void _saveLibrary() {
    if (_formKey.currentState!.validate()) {
      final library = Library(
        id:
            widget.library?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        icon: 'default',
        type: _selectedType == LibraryType.local ? 'local' : 'network',
        customFields: {
          if (_selectedType == LibraryType.local) 'path': _localPath,
          if (_selectedType == LibraryType.network)
            'server': _serverController.text,
          if (_selectedType == LibraryType.network)
            'username': _usernameController.text,
          if (_selectedType == LibraryType.network)
            'password': _passwordController.text,
        },
        createdAt: DateTime.now(),
      );
      Navigator.pop(context, library);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LibrariesLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.library == null
              ? localizations.newLibrary
              : localizations.editLibrary,
        ),
        actions: [IconButton(icon: Icon(Icons.save), onPressed: _saveLibrary)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: localizations.libraryName,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.nameRequired;
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<LibraryType>(
                value: _selectedType,
                items:
                    LibraryType.values.map((type) {
                      return DropdownMenuItem<LibraryType>(
                        value: type,
                        child: Text(
                          type == LibraryType.local
                              ? localizations.localDatabase
                              : localizations.networkDatabase,
                        ),
                      );
                    }).toList(),
                onChanged: (type) {
                  setState(() {
                    _selectedType = type!;
                  });
                },
                decoration: InputDecoration(
                  labelText: localizations.databaseType,
                ),
              ),
              SizedBox(height: 16),
              if (_selectedType == LibraryType.local) ...[
                OutlinedButton(
                  onPressed: _pickFolder,
                  child: Text(
                    _localPath.isEmpty
                        ? localizations.selectFolder
                        : _localPath,
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _serverController,
                  decoration: InputDecoration(
                    labelText: localizations.serverAddress,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.serverRequired;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: localizations.username,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: localizations.password,
                  ),
                  obscureText: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum LibraryType { local, network }
