import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/library_edit_view.dart';
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
    _plugin.libraryController.openLibrary(library, context);
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              // 根据屏幕宽度动态计算列数
              final width = constraints.maxWidth;
              final crossAxisCount =
                  width > 1200
                      ? 6
                      : width > 800
                      ? 4
                      : width > 500
                      ? 3
                      : 2;

              return GridView.builder(
                padding: EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: libraries.length,
                itemBuilder: (context, index) {
                  final library = libraries[index];
                  return Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () => _onLibrarySelected(library),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.library_books, size: 40),
                            SizedBox(height: 8),
                            Text(
                              library.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              library.type,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
