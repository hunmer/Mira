import 'dart:io' show Platform;
import 'dart:ui';

/// 跨平台任务栏操作工具类
class Taskbar {
  /// 设置缩略图工具栏按钮
  static void setThumbnailToolbar(List<ThumbnailToolbarButton> buttons) {
    if (Platform.isWindows) {
      // Windows平台实现
      WindowsTaskbar.setThumbnailToolbar(buttons);
    } else if (Platform.isMacOS) {
      // macOS平台实现
      // TODO: 添加macOS特定实现
    } else if (Platform.isLinux) {
      // Linux平台实现
      // TODO: 添加Linux特定实现
    }
  }

  /// 重置缩略图工具栏
  static void resetThumbnailToolbar() {
    if (Platform.isWindows) {
      WindowsTaskbar.resetThumbnailToolbar();
    }
    // 其他平台暂无对应功能
  }

  /// 设置进度条模式
  static void setProgressMode(TaskbarProgressMode mode) {
    if (Platform.isWindows) {
      WindowsTaskbar.setProgressMode(mode);
    } else if (Platform.isMacOS) {
      // macOS Dock进度条实现
    }
  }

  /// 设置进度条值
  static void setProgress(int current, int total) {
    if (Platform.isWindows) {
      WindowsTaskbar.setProgress(current, total);
    } else if (Platform.isMacOS) {
      // macOS Dock进度条实现
    }
  }

  /// 设置缩略图工具提示
  static void setThumbnailTooltip(String tooltip) {
    if (Platform.isWindows) {
      WindowsTaskbar.setThumbnailTooltip(tooltip);
    }
  }

  /// 闪烁任务栏图标
  static void setFlashTaskbarAppIcon({
    required TaskbarFlashMode mode,
    Duration timeout = const Duration(milliseconds: 500),
  }) {
    if (Platform.isWindows) {
      WindowsTaskbar.setFlashTaskbarAppIcon(mode: mode, timeout: timeout);
    } else if (Platform.isMacOS) {
      // macOS Dock图标弹跳效果
    }
  }

  /// 停止闪烁任务栏图标
  static void resetFlashTaskbarAppIcon() {
    if (Platform.isWindows) {
      WindowsTaskbar.resetFlashTaskbarAppIcon();
    }
  }

  /// 设置覆盖图标
  static void setOverlayIcon(
    ThumbnailToolbarAssetIcon icon, {
    String? tooltip,
  }) {
    if (Platform.isWindows) {
      WindowsTaskbar.setOverlayIcon(icon, tooltip: tooltip);
    }
  }

  /// 重置覆盖图标
  static void resetOverlayIcon() {
    if (Platform.isWindows) {
      WindowsTaskbar.resetOverlayIcon();
    }
  }

  /// 设置窗口标题
  static void setWindowTitle(String title) {
    if (Platform.isWindows) {
      WindowsTaskbar.setWindowTitle(title);
    } else {
      // 通用平台实现
      // TODO: 添加跨平台窗口标题设置
    }
  }

  /// 重置窗口标题
  static void resetWindowTitle() {
    if (Platform.isWindows) {
      WindowsTaskbar.resetWindowTitle();
    }
  }
}

/// Windows平台特定实现
class WindowsTaskbar {
  static void setThumbnailToolbar(List<ThumbnailToolbarButton> buttons) {
    // Windows平台实现
  }

  static void resetThumbnailToolbar() {
    // Windows平台实现
  }

  static void setProgressMode(TaskbarProgressMode mode) {
    // Windows平台实现
  }

  static void setProgress(int current, int total) {
    // Windows平台实现
  }

  static void setThumbnailTooltip(String tooltip) {
    // Windows平台实现
  }

  static void setFlashTaskbarAppIcon({
    required TaskbarFlashMode mode,
    required Duration timeout,
  }) {
    // Windows平台实现
  }

  static void resetFlashTaskbarAppIcon() {
    // Windows平台实现
  }

  static void setOverlayIcon(
    ThumbnailToolbarAssetIcon icon, {
    String? tooltip,
  }) {
    // Windows平台实现
  }

  static void resetOverlayIcon() {
    // Windows平台实现
  }

  static void setWindowTitle(String title) {
    // Windows平台实现
  }

  static void resetWindowTitle() {
    // Windows平台实现
  }
}

enum TaskbarProgressMode { none, normal, indeterminate, error, paused }

enum TaskbarFlashMode { none, stop, all, timernofg }

class ThumbnailToolbarButton {
  final ThumbnailToolbarAssetIcon icon;
  final String tooltip;
  final VoidCallback onPressed;
  final int mode;

  ThumbnailToolbarButton(
    this.icon,
    this.tooltip,
    this.onPressed, {
    this.mode = 0,
  });
}

class ThumbnailToolbarAssetIcon {
  final String assetPath;

  ThumbnailToolbarAssetIcon(this.assetPath);
}
