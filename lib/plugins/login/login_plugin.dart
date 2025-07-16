// ignore_for_file: override_on_non_overriding_member

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mira/core/config_manager.dart';
import 'package:mira/core/plugin_base.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/login/controllers/auth_controller.dart';

class LoginPlugin extends PluginBase {
  static LoginPlugin? _instance;
  static LoginPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('login') as LoginPlugin?;
      if (_instance == null) {
        throw StateError('LoginPlugin has not been initialized');
      }
    }
    return _instance!;
  }

  @override
  String get id => 'login';

  late final AuthController authController;

  @override
  Widget buildSettingsPanel(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authController,
      child: Consumer<AuthController>(
        builder: (context, auth, child) {
          return ListTile(
            title: const Text('Logout'),
            trailing: const Icon(Icons.logout),
            onTap: () {
              auth.logout();
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildCard(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authController,
      child: Consumer<AuthController>(
        builder: (context, auth, child) {
          if (auth.state.isLoggedIn) {
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    auth.state.currentUser?.avatar != null
                        ? AssetImage(auth.state.currentUser!.avatar!)
                        : null,
                child:
                    auth.state.currentUser?.avatar == null
                        ? const Icon(Icons.person)
                        : null,
              ),
              title: Text(auth.state.currentUser?.nickname ?? 'User'),
              subtitle: Text(auth.state.currentUser?.phone ?? ''),
            );
          } else {
            return ListTile(
              title: const Text('Login Required'),
              trailing: const Icon(Icons.login),
              onTap: () => Navigator.pushNamed(context, '/login'),
            );
          }
        },
      ),
    );
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 初始化插件
    await initialize();
  }

  @override
  Future<void> initialize() async {
    authController = AuthController(storage: storage);
    await authController.init();

    if (!authController.state.isLoggedIn) {}
  }
}
