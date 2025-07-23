import 'package:flutter/material.dart';
import 'package:mira/screens/settings_screen/controllers/settings_screen_controller.dart';

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
          // 插件
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text('插件管理'),
            onTap: () => {},
          ),
          // 暗色模式
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text('夜间模式'),
            onTap: () {
              SettingsScreenController().toggleTheme(context);
            },
          ),
          // 系统设置
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('系统设置'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }
}
