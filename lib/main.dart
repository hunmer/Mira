// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:mira/core/event/event.dart';
import 'package:mira/plugins/libraries/l10n/libraries_localizations.dart';
import 'package:mira/plugins/libraries/libraries_plugin.dart';
import 'package:mira/dock/dock_manager.dart';
import 'package:provider/provider.dart';
import 'package:mira/core/theme_controller.dart';
import 'package:mira/plugins/login/l10n/login_localizations.dart';
import 'package:mira/screens/settings_screen/controllers/permission_controller.dart';
import 'package:mira/screens/settings_screen/l10n/log_settings_localizations.dart';
import 'package:mira/screens/settings_screen/l10n/settings_screen_localizations.dart';
import 'package:mira/screens/settings_screen/screens/data_management_localizations.dart';
import 'package:mira/screens/settings_screen/widgets/l10n/webdav_localizations.dart';
import 'package:mira/widgets/l10n/group_selector_localizations.dart';
import 'package:mira/widgets/l10n/image_picker_localizations.dart';
import 'package:mira/widgets/l10n/location_picker_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mira/l10n/app_localizations.dart';
import 'core/plugin_manager.dart';
import 'core/storage/storage_manager.dart';
import 'core/config_manager.dart';
import 'screens/route.dart';
import 'screens/settings_screen/controllers/auto_update_controller.dart'; // 自动更新控制器

// 全局导航键
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// 全局单例实例
late final StorageManager globalStorage;
late final ConfigManager globalConfigManager;
late final PluginManager globalPluginManager;
late PermissionController _permissionController;

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 MediaKit
  // MediaKit.ensureInitialized();

  // 设置首选方向为竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final themeController = ThemeController();
  await themeController.initializeTheme();
  try {
    // 创建并初始化存储管理器（内部会处理Web平台的情况）
    globalStorage = StorageManager();
    await globalStorage.initialize();

    // 初始化配置管理器
    globalConfigManager = ConfigManager(globalStorage);
    await globalConfigManager.initialize();

    // 获取插件管理器单例实例并初始化
    globalPluginManager = PluginManager();
    await globalPluginManager.setStorageManager(globalStorage);

    // 初始化DockManager的持久化存储
    await DockManager.setStorageManager(globalStorage);

    // 注册内置插件
    final plugins = [LibrariesPlugin()];

    // 设置全局错误处理器
    FlutterError.onError = (details) {
      print(details.toString());
    };

    // 遍历并注册插件
    for (final plugin in plugins) {
      try {
        await globalPluginManager.registerPlugin(plugin);
      } catch (e) {
        print('插件注册失败: ${plugin.id} - $e');
      }
    }

    final updateController = AutoUpdateController.instance;
    updateController.initialize();

    // 延迟备份服务初始化到Widget构建完成后
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = navigatorKey.currentContext;
      if (context != null) {
        _permissionController = PermissionController(context);
        // 检查权限
        await _permissionController.checkAndRequestPermissions();
      }
      // 插件初始化完成，发布事件
      eventManager.broadcast(
        'plugins_initialized',
        EventArgs('plugins_initialized'),
      );
    });

    // 初始化DockManager的持久化存储
    DockManager.setStorageManager(globalStorage);
  } catch (e) {
    debugPrint('初始化失败: $e');
  }

  runApp(
    ChangeNotifierProvider.value(value: themeController, child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _setupAutoUpdate();
    });
  }

  void _setupAutoUpdate() {
    if (!mounted) return;
    final updateController = AutoUpdateController.instance;
    updateController.context = context;
  }

  Future<void> checkForUpdates() async {
    if (!mounted) return;

    final updateController = AutoUpdateController.instance;
    updateController.context = context;
    final hasUpdate = await updateController.checkForUpdates();
    if (hasUpdate) {
      updateController.showUpdateDialog(skipCheck: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        return MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          navigatorKey: navigatorKey,
          title: 'recordingNotes',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: [
            AppLocalizations.delegate,
            LoginLocalizations.delegate,
            ImagePickerLocalizations.delegate,
            SettingsScreenLocalizations.delegate,
            DataManagementLocalizations.delegate,
            LibrariesLocalizations.delegate,
            LogSettingsLocalizationsDelegate(),
            GroupSelectorLocalizations.delegate,
            LocationPickerLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            WebDAVLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', ''), // 中文
            Locale('en', ''), // 英文
          ],
          locale: globalConfigManager.getLocale(),
          theme: FlexThemeData.light(
            scheme: themeController.currentScheme ?? FlexScheme.mandyRed,
            usedColors: 4,
            surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
            blendLevel: 20,
            appBarStyle: FlexAppBarStyle.background,
            appBarOpacity: 0.95,
            tabBarStyle: FlexTabBarStyle.forBackground,
            swapColors: true,
            useMaterial3ErrorColors: true,
          ),
          darkTheme: FlexThemeData.dark(
            scheme: themeController.currentScheme ?? FlexScheme.mandyRed,
            usedColors: 4,
            surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
            blendLevel: 15,
            appBarStyle: FlexAppBarStyle.background,
            appBarOpacity: 0.90,
            tabBarStyle: FlexTabBarStyle.forBackground,
            useMaterial3ErrorColors: true,
          ),

          themeMode: themeController.themeMode,
          builder: (context, child) {
            // 确保字体大小不受系统设置影响
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
          initialRoute: AppRoutes.initialRoute,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.generateRoute,
          onGenerateTitle:
              (BuildContext context) => AppLocalizations.of(context)!.appTitle,
        );
      },
    );
  }
}
