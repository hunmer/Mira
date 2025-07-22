import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/plugins/libraries/widgets/library_edit_view.dart';
import '../models/library.dart';
import '../l10n/libraries_localizations.dart';

class LibraryListView extends StatefulWidget {
  final Function(Library)? onSelected;
  const LibraryListView({super.key, this.onSelected});

  @override
  // ignore: library_private_types_in_public_api
  _LibraryListViewState createState() => _LibraryListViewState();
}

class _LibraryListViewState extends State<LibraryListView> {
  late List<Library> _libraries;
  late LibrariesPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = PluginManager.instance.getPlugin('libraries') as LibrariesPlugin;
    _libraries = _plugin.dataController.libraries;
  }

  Future<void> _onLibrarySelected(Library library) async {
    final newTabView = widget.onSelected == null;
    if (!newTabView) {
      widget.onSelected?.call(library);
    }
    await _plugin.libraryController.openLibrary(
      library,
      context,
      newTabView: newTabView,
    );
  }

  @override
  Widget build(BuildContext context) {
    LibrariesLocalizations.of(context);

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
            itemCount: _libraries.length,
            itemBuilder: (context, index) {
              final library = _libraries[index];
              return Card(
                elevation: 2,
                child: InkWell(
                  onTap: () => _onLibrarySelected(library),
                  onSecondaryTapDown: (details) {
                    _showContextMenu(context, details.globalPosition, library);
                  },
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
            await _plugin.dataController.addLibrary(newLibrary);
            setState(() {
              _libraries = _plugin.dataController.libraries;
            });
          }
        },
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    Library library,
  ) {
    final entries = <ContextMenuEntry>[
      MenuItem(
        label: '编辑',
        icon: Icons.edit,
        onSelected: () async {
          final updatedLibrary = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LibraryEditView(library: library),
            ),
          );

          if (updatedLibrary != null) {
            await _plugin.dataController.updateLibrary(updatedLibrary);
            setState(() {
              _libraries = _plugin.dataController.libraries;
            });
          }
        },
      ),
      MenuItem(
        label: '删除',
        icon: Icons.delete,
        onSelected: () async {
          await _plugin.dataController.deleteLibrary(library.id);
          setState(() {
            _libraries = _plugin.dataController.libraries;
          });
        },
      ),
    ];

    final menu = ContextMenu(
      entries: entries,
      position: position,
      padding: const EdgeInsets.all(8.0),
    );

    showContextMenu(context, contextMenu: menu);
  }
}
