import 'package:flutter/material.dart';

class AppSidebarView extends StatefulWidget {
  const AppSidebarView({super.key});

  @override
  State<AppSidebarView> createState() => _AppSidebarViewState();
}

class _AppSidebarViewState extends State<AppSidebarView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.all_inbox),
            title: const Text('所有素材库'),
            onTap: () => Navigator.pushNamed(context, '/libraries'),
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('我的收藏'),
            onTap: () => {},
          ),
        ],
      ),
    );
  }
}
