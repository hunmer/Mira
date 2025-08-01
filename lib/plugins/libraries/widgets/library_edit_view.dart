import 'package:flutter/foundation.dart';
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
  late final TextEditingController _httpServerController;
  late final TextEditingController _socketServerController;
  late final TextEditingController _nasRelativePathController;
  late final TextEditingController _nasSmbPathController;
  late String _localPath;
  late bool _enableHash = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _httpServerController = TextEditingController();
    _socketServerController = TextEditingController();
    _nasRelativePathController = TextEditingController();
    _nasSmbPathController = TextEditingController();
    _localPath = '';

    if (widget.library != null) {
      final library = widget.library!;
      _nameController.text = library.name;

      if (library.type == 'local') {
        _selectedType = LibraryType.local;
      } else {
        _selectedType = LibraryType.network;
      }

      if (_selectedType == LibraryType.local) {
        _localPath = library.customFields['path'] ?? '';
      } else {
        _httpServerController.text = library.httpServer;
        _socketServerController.text = library.socketServer;
        _nasRelativePathController.text =
            library.customFields['relativePath'] ?? '';
        _nasSmbPathController.text = library.customFields['smbPath'] ?? '';
      }
      _enableHash =
          library.customFields.containsKey('enableHash')
              ? library.customFields['enableHash']
              : false;
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
      String libraryType;
      if (_selectedType == LibraryType.local) {
        libraryType = 'local';
      } else {
        libraryType = 'network';
      }

      Map<String, dynamic> customFieldsMap = {};

      if (_selectedType == LibraryType.local) {
        customFieldsMap['path'] = _localPath;
        customFieldsMap['enableHash'] = _enableHash;
      } else {
        customFieldsMap['relativePath'] = _nasRelativePathController.text;
        customFieldsMap['smbPath'] = _nasSmbPathController.text;
      }

      final library = Library(
        id:
            widget.library?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        icon: 'default',
        type: libraryType,
        httpServer:
            _selectedType == LibraryType.network
                ? _httpServerController.text
                : '',
        socketServer:
            _selectedType == LibraryType.network
                ? _socketServerController.text
                : '',
        customFields: customFieldsMap,
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
              // Only allow network type on web
              kIsWeb // Fuchsia is used as a placeholder for web in Flutter's platform detection
                  ? DropdownButtonFormField<LibraryType>(
                    value: LibraryType.network,
                    items: [
                      DropdownMenuItem<LibraryType>(
                        value: LibraryType.network,
                        child: Text(localizations.networkDatabase),
                      ),
                    ],
                    onChanged: null,
                    decoration: InputDecoration(
                      labelText: localizations.databaseType,
                    ),
                  )
                  : DropdownButtonFormField<LibraryType>(
                    value: _selectedType,
                    items:
                        LibraryType.values.map((type) {
                          String text;
                          switch (type) {
                            case LibraryType.local:
                              text = localizations.localDatabase;
                              break;
                            case LibraryType.network:
                              text = localizations.networkDatabase;
                              break;
                          }
                          return DropdownMenuItem<LibraryType>(
                            value: type,
                            child: Text(text),
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
                // 是否启用hash
                CheckboxListTile(
                  title: Text('开启文件唯一hash效验'),
                  value: _enableHash,
                  onChanged: (bool? value) {
                    setState(() {
                      _enableHash = value!;
                    });
                  },
                ),
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
                  controller: _httpServerController,
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
                  controller: _socketServerController,
                  decoration: InputDecoration(labelText: 'socket server'),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _nasRelativePathController,
                  decoration: InputDecoration(
                    labelText: localizations.relativePath,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.relativePathRequired;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _nasSmbPathController,
                  decoration: InputDecoration(labelText: localizations.smbPath),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.smbPathRequired;
                    }
                    return null;
                  },
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
