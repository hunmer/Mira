import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:mira/core/widgets/app_draw.dart';
import 'package:mira/plugins/libraries/widgets/library_list_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool isExpanded = false;
  final List<Widget> _pages = [const LibraryListView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDraw(),
      body: Column(
        children: [
          // 独立的侧边栏切换按钮区域
          Container(
            height: 56,
            alignment: Alignment.centerLeft,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: const Icon(CupertinoIcons.sidebar_left),
            ),
          ),
          // 侧边栏和内容区域
          Expanded(
            child: Row(
              children: [
                CupertinoSidebarCollapsible(
                  isExpanded: isExpanded,
                  child: CupertinoSidebar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    children: [
                      SidebarDestination(
                        icon: const Icon(CupertinoIcons.doc_text),
                        label: const Text('Libraries List'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
