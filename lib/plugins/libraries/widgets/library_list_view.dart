import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/library_edit_view.dart';
import 'package:mira/plugins/libraries/widgets/library_gallery_view.dart';
import '../controllers/library_data_interface.dart';
import '../models/library.dart';
import '../l10n/libraries_localizations.dart';

class LibraryListView extends StatefulWidget {
  const LibraryListView({Key? key}) : super(key: key);

  @override
  _LibraryListViewState createState() => _LibraryListViewState();
}

class _LibraryListViewState extends State<LibraryListView> {
  late Future<List<Library>> _librariesFuture;
  late LibrariesPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
    _librariesFuture = _plugin.dataController.findLibraries().then(
      (list) => list.cast<Library>(),
    );
  }

  void _onLibrarySelected(Library library) {
    _plugin.setlibraryController(library.customFields['path'] ?? 'local');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LibraryGalleryView(
              files: [], // TODO: 获取实际文件列表
              onFileSelected: (file) {
                // TODO: 处理文件选择
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LibrariesLocalizations.of(context)!;

    return FutureBuilder<List<Library>>(
      future: _librariesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator());
        }

        final libraries = snapshot.data ?? [];
        return Scaffold(
          appBar: AppBar(title: Text(localizations.librariesTitle)),
          body: ListView.builder(
            itemCount: libraries.length,
            itemBuilder: (context, index) {
              final library = libraries[index];
              return ListTile(
                leading: Icon(Icons.library_books),
                title: Text(library.name),
                subtitle: Text(library.type),
                onTap: () => _onLibrarySelected(library),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () async {
              final newLibrary = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LibraryEditView()),
              );

              if (newLibrary != null) {
                setState(() {
                  _plugin.dataController.addLibrary(newLibrary);
                });
              }
            },
          ),
        );
      },
    );
  }
}
