import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/core/widgets/app_draw.dart';
import 'package:mira/plugins/libraries/widgets/library_list_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const LibraryListView(),
    // Container(), // Placeholder for recording button
    // const RecordsMainView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDraw(),
      body: Row(
        children: [
          CupertinoSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            children: [
              SidebarDestination(
                icon: const Icon(CupertinoIcons.doc_text),
                label: const Text('Memos'),
              ),
              // SidebarDestination(
              //   icon: const Icon(CupertinoIcons.mic),
              //   label: const Text('Record'),
              // ),
              // SidebarDestination(
              //   icon: const Icon(CupertinoIcons.music_note),
              //   label: const Text('Records'),
              // ),
            ],
          ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
