import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口控制按钮组件
/// 在桌面端显示最小化、最大化、关闭按钮
/// macOS在左侧，Windows/Linux在右侧
class WindowControls extends StatefulWidget {
  final Color? backgroundColor;
  final Color? hoverColor;
  final Color? iconColor;
  final double? buttonSize;

  const WindowControls({
    Key? key,
    this.backgroundColor,
    this.hoverColor,
    this.iconColor,
    this.buttonSize = 32.0,
  }) : super(key: key);

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _updateWindowState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  Future<void> _updateWindowState() async {
    final isMaximized = await windowManager.isMaximized();
    setState(() {
      _isMaximized = isMaximized;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return const SizedBox.shrink();
    }

    // macOS样式的红绿灯按钮
    if (Platform.isMacOS) {
      return _buildMacOSControls();
    }

    // Windows/Linux样式的控制按钮
    return _buildWindowsLinuxControls();
  }

  Widget _buildMacOSControls() {
    return Container(
      padding: const EdgeInsets.only(left: 12, top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MacOSButton(
            color: const Color(0xFFFF5F57),
            hoverColor: const Color(0xFFFF5F57).withOpacity(0.8),
            icon: Icons.close,
            size: widget.buttonSize ?? 12.0,
            onTap: () => windowManager.close(),
          ),
          const SizedBox(width: 8),
          _MacOSButton(
            color: const Color(0xFFFFBD2E),
            hoverColor: const Color(0xFFFFBD2E).withOpacity(0.8),
            icon: Icons.minimize,
            size: widget.buttonSize ?? 12.0,
            onTap: () => windowManager.minimize(),
          ),
          const SizedBox(width: 8),
          _MacOSButton(
            color: const Color(0xFF28CA42),
            hoverColor: const Color(0xFF28CA42).withOpacity(0.8),
            icon: _isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
            size: widget.buttonSize ?? 12.0,
            onTap: () async {
              if (_isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsLinuxControls() {
    final theme = Theme.of(context);
    final iconColor = widget.iconColor ?? theme.iconTheme.color ?? Colors.black;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WindowButton(
            icon: Icons.minimize,
            iconColor: iconColor,
            backgroundColor: widget.backgroundColor,
            hoverColor: widget.hoverColor ?? theme.hoverColor,
            size: widget.buttonSize ?? 32.0,
            onTap: () => windowManager.minimize(),
          ),
          _WindowButton(
            icon: _isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
            iconColor: iconColor,
            backgroundColor: widget.backgroundColor,
            hoverColor: widget.hoverColor ?? theme.hoverColor,
            size: widget.buttonSize ?? 32.0,
            onTap: () async {
              if (_isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          _WindowButton(
            icon: Icons.close,
            iconColor: iconColor,
            backgroundColor: widget.backgroundColor,
            hoverColor: Colors.red.withOpacity(0.8),
            size: widget.buttonSize ?? 32.0,
            onTap: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

/// macOS样式的圆形按钮
class _MacOSButton extends StatefulWidget {
  final Color color;
  final Color hoverColor;
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _MacOSButton({
    required this.color,
    required this.hoverColor,
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  State<_MacOSButton> createState() => _MacOSButtonState();
}

class _MacOSButtonState extends State<_MacOSButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _isHovering ? widget.hoverColor : widget.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child:
              _isHovering
                  ? Icon(
                    widget.icon,
                    size: widget.size * 0.5,
                    color: Colors.black.withOpacity(0.6),
                  )
                  : null,
        ),
      ),
    );
  }
}

/// Windows/Linux样式的方形按钮
class _WindowButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color? backgroundColor;
  final Color hoverColor;
  final double size;
  final VoidCallback onTap;

  const _WindowButton({
    required this.icon,
    required this.iconColor,
    this.backgroundColor,
    required this.hoverColor,
    required this.size,
    required this.onTap,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color:
                _isHovering
                    ? widget.hoverColor
                    : widget.backgroundColor ?? Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.5,
            color: widget.iconColor,
          ),
        ),
      ),
    );
  }
}

/// 窗口拖拽区域组件
/// 包装其他组件使其可以拖拽窗口
class DragToMoveArea extends StatelessWidget {
  final Widget child;

  const DragToMoveArea({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        windowManager.startDragging();
      },
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          windowManager.unmaximize();
        } else {
          windowManager.maximize();
        }
      },
      child: child,
    );
  }
}
