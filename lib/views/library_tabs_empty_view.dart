import 'package:flutter/material.dart';

class LibraryTabsEmptyView extends StatelessWidget {
  final VoidCallback onAddTab;

  const LibraryTabsEmptyView({super.key, required this.onAddTab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('选择一个数据库打开', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onAddTab, child: const Text('打开数据库')),
        ],
      ),
    );
  }
}
