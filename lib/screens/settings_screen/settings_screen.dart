import 'package:provider/provider.dart';
import 'package:mira/core/services/backup_service.dart';
import 'package:mira/core/theme_controller.dart';
import 'package:mira/l10n/app_localizations.dart';
import 'package:mira/screens/settings_screen/log_settings_screen.dart';
import 'package:flutter/material.dart';
import './controllers/settings_screen_controller.dart';
import './widgets/webdav_settings_dialog.dart';
import './controllers/webdav_controller.dart';
import 'package:mira/screens/settings_screen/screens/data_management_screen.dart';
import 'package:mira/screens/about_screen/about_screen.dart';
import './l10n/settings_screen_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsScreenController _controller;
  late WebDAVController _webdavController;
  bool _isWebDAVConnected = false;

  @override
  void initState() {
    super.initState();
    _controller = SettingsScreenController();
    _webdavController = WebDAVController();

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // 检查WebDAV配置
    _checkWebDAVConfig();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.initializeControllers(context);
    _backupService = BackupService(_controller, context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 检查WebDAV配置
  Future<void> _checkWebDAVConfig() async {
    final config = await _webdavController.getWebDAVConfig();
    if (mounted) {
      setState(() {
        _isWebDAVConnected = config?['isConnected'] == true;
      });
    }
  }

  late BackupService _backupService;

  // 显示WebDAV设置对话框
  Future<void> _showWebDAVSettings() async {
    final config = await _webdavController.getWebDAVConfig();
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => WebDAVSettingsDialog(
            controller: _webdavController,
            initialConfig: config,
          ),
    );

    if (result == true) {
      // 重新检查WebDAV状态
      await _checkWebDAVConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isInitialized() || _backupService == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(SettingsScreenLocalizations.of(context).settingsTitle),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(SettingsScreenLocalizations.of(context).languageTitle),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).languageSubtitle,
            ),
            onTap: () => _controller.toggleLanguage(context),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text('主题设置'),
            subtitle: Text('选择应用主题颜色'),
            onTap: () {
              final themeController = Provider.of<ThemeController>(
                context,
                listen: false,
              );
              themeController.showThemeDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text('暗色模式'),
            subtitle: Text('切换暗色模式'),
            onTap: () {
              final themeController = Provider.of<ThemeController>(
                context,
                listen: false,
              );
              themeController.toggleTheme();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload),
            title: Text(
              SettingsScreenLocalizations.of(context).exportDataTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).exportDataSubtitle,
            ),
            onTap: () {
              if (mounted) {
                _controller.exportData(context);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text(
              SettingsScreenLocalizations.of(context).dataManagementTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).dataManagementSubtitle,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DataManagementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(
              SettingsScreenLocalizations.of(context).importDataTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).importDataSubtitle,
            ),
            onTap: _controller.importData,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(
              SettingsScreenLocalizations.of(context).fullBackupTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).fullBackupSubtitle,
            ),
            onTap: _controller.exportAllData,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(
              SettingsScreenLocalizations.of(context).fullRestoreTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).fullRestoreSubtitle,
            ),
            onTap: _controller.importAllData,
            trailing: const Icon(Icons.warning, color: Colors.orange),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: Text(SettingsScreenLocalizations.of(context).webDAVTitle),
            subtitle: Text(
              _isWebDAVConnected
                  ? SettingsScreenLocalizations.of(context).webDAVConnected
                  : SettingsScreenLocalizations.of(context).webDAVDisconnected,
            ),
            trailing:
                _isWebDAVConnected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
            onTap: () {
              if (mounted) {
                _showWebDAVSettings();
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(
              SettingsScreenLocalizations.of(context).autoBackupTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).autoBackupSubtitle,
            ),
            onTap: _backupService.showBackupScheduleDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: Text(
              SettingsScreenLocalizations.of(context).autoCheckUpdateTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).autoCheckUpdateSubtitle,
            ),
            trailing: Switch(
              value: _controller.autoCheckUpdate,
              onChanged:
                  (value) => setState(() {
                    _controller.autoCheckUpdate = value;
                  }),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.update),
            title: Text(
              SettingsScreenLocalizations.of(context).checkUpdateTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).checkUpdateSubtitle,
            ),
            onTap: _controller.checkForUpdates,
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(
              SettingsScreenLocalizations.of(context).logSettingsTitle,
            ),
            subtitle: Text(
              SettingsScreenLocalizations.of(context).logSettingsSubtitle,
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(AppLocalizations.of(context)!.aboutTitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
