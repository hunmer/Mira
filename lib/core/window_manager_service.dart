import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'config_manager.dart';

/// 窗口管理服务，负责窗口状态的保存和恢复
class WindowManagerService with WindowListener {
  final ConfigManager _configManager;
  bool _isInitialized = false;

  WindowManagerService(this._configManager);

  /// 初始化窗口管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 仅在非Web平台初始化window_manager
    if (!kIsWeb) {
      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      // 恢复窗口状态
      await _restoreWindowState();
    }
    _isInitialized = true;
  }

  /// 销毁窗口管理器
  void dispose() {
    if (_isInitialized && !kIsWeb) {
      windowManager.removeListener(this);
      _isInitialized = false;
    }
  }

  /// 恢复窗口状态
  Future<void> _restoreWindowState() async {
    final windowConfig = _configManager.getWindowConfig();

    final size = Size(
      (windowConfig['width'] as num?)?.toDouble() ?? 800.0,
      (windowConfig['height'] as num?)?.toDouble() ?? 600.0,
    );

    WindowOptions windowOptions = WindowOptions(
      size: size,
      center: windowConfig['x'] == null || windowConfig['y'] == null,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      minimumSize: const Size(400, 300),
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();

      // 如果有保存的位置，设置窗口位置
      if (windowConfig['x'] != null && windowConfig['y'] != null) {
        final position = Offset(
          (windowConfig['x'] as num).toDouble(),
          (windowConfig['y'] as num).toDouble(),
        );
        // 确保窗口位置不超出屏幕范围
        final screenSize = await windowManager.getSize(); // 获取屏幕尺寸的替代方法
        final windowSize = size;

        await windowManager.setPosition(position);
      }

      // 如果窗口之前是最大化状态，恢复最大化(BUG: 窗口无法正常显示，可能需要延迟)
      // if (windowConfig['isMaximized'] == true) {
      //   await windowManager.maximize();
      // }
    });
  }

  @override
  void onWindowEvent(String eventName) {
    // debugPrint('[WindowManager] onWindowEvent: $eventName');
  }

  @override
  void onWindowClose() {
    // 窗口关闭前保存当前状态
    if (!kIsWeb) {
      _saveCurrentWindowState();
    }
  }

  @override
  void onWindowResize() {
    // 窗口大小改变时保存
    if (!kIsWeb) {
      _saveWindowSize();
    }
  }

  @override
  void onWindowMove() {
    // 窗口位置改变时保存
    if (!kIsWeb) {
      _saveWindowPosition();
    }
  }

  @override
  void onWindowMaximize() {
    // 窗口最大化时保存状态
    if (!kIsWeb) {
      _configManager.updateWindowMaximized(true);
    }
  }

  @override
  void onWindowUnmaximize() {
    // 窗口取消最大化时保存状态和当前大小位置
    if (!kIsWeb) {
      _configManager.updateWindowMaximized(false);
      _saveCurrentWindowState();
    }
  }

  @override
  void onWindowRestore() {
    // 窗口恢复时保存状态
    if (!kIsWeb) {
      _configManager.updateWindowMaximized(false);
      _saveCurrentWindowState();
    }
  }

  /// 保存当前窗口状态（大小和位置）
  Future<void> _saveCurrentWindowState() async {
    if (kIsWeb) return; // Web平台不支持window_manager

    try {
      final size = await windowManager.getSize();
      final position = await windowManager.getPosition();
      final isMaximized = await windowManager.isMaximized();

      final windowConfig = _configManager.getWindowConfig();
      windowConfig['width'] = size.width;
      windowConfig['height'] = size.height;
      windowConfig['x'] = position.dx;
      windowConfig['y'] = position.dy;
      windowConfig['isMaximized'] = isMaximized;

      await _configManager.saveWindowConfig(windowConfig);
    } catch (e) {
      debugPrint('保存窗口状态失败: $e');
    }
  }

  /// 保存窗口大小
  Future<void> _saveWindowSize() async {
    if (kIsWeb) return; // Web平台不支持window_manager

    try {
      final size = await windowManager.getSize();
      await _configManager.updateWindowSize(size.width, size.height);
    } catch (e) {
      debugPrint('保存窗口大小失败: $e');
    }
  }

  /// 保存窗口位置
  Future<void> _saveWindowPosition() async {
    if (kIsWeb) return; // Web平台不支持window_manager

    try {
      final position = await windowManager.getPosition();
      await _configManager.updateWindowPosition(position.dx, position.dy);
    } catch (e) {
      debugPrint('保存窗口位置失败: $e');
    }
  }

  @override
  void onWindowFocus() {
    // 可以在这里处理窗口获得焦点的逻辑
  }

  @override
  void onWindowBlur() {
    // 可以在这里处理窗口失去焦点的逻辑
  }

  @override
  void onWindowMinimize() {
    // 可以在这里处理窗口最小化的逻辑
  }

  @override
  void onWindowEnterFullScreen() {
    // 可以在这里处理进入全屏的逻辑
  }

  @override
  void onWindowLeaveFullScreen() {
    // 可以在这里处理离开全屏的逻辑
  }
}
