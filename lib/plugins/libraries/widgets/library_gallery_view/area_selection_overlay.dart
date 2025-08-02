import 'dart:async';
import 'package:flutter/material.dart';

/// 矩形选择区域的回调函数类型定义
typedef AreaSelectionCallback = void Function(Rect selectionArea);
typedef ScrollControllerCallback = void Function(ScrollController controller);
typedef SelectionStateCallback = void Function(bool isActive);
typedef SelectionStartCallback = void Function(Offset startPosition);

/// 控制器类，用于child组件与overlay交互
class AreaSelectionOverlayController {
  AreaSelectionOverlayState? _state;
  AreaSelectionOverlayController? _linkedController;

  void _attach(AreaSelectionOverlayState state) {
    _state = state;
  }

  /// 同步两个控制器，让按钮控制器能控制覆盖层控制器
  void syncWith(AreaSelectionOverlayController other) {
    _linkedController = other;
  }

  /// 开始区域选择模式
  void startSelectionMode() {
    _state?.startSelectionMode();
    _linkedController?._state?.startSelectionMode();
  }

  /// 结束区域选择模式
  void endSelectionMode() {
    _state?.endSelectionMode();
    _linkedController?._state?.endSelectionMode();
  }

  /// 提供ScrollController给父组件
  void provideScrollController(ScrollController controller) {
    _state?.setScrollController(controller);
  }
}

/// 独立的矩形选择overlay组件
/// 这是一个可复用的组件，可以作为覆盖层提供矩形选择功能
class AreaSelectionOverlay extends StatefulWidget {
  final Widget Function(AreaSelectionOverlayController controller)?
  childBuilder;
  final AreaSelectionCallback? onAreaSelectionUpdate;
  final SelectionStateCallback? onSelectionStateChanged;
  final ScrollControllerCallback? onScrollControllerProvided;
  final VoidCallback? onClearSelection;
  final SelectionStartCallback? onSelectionStart;
  final ScrollController? scrollController;
  final bool enabled;

  const AreaSelectionOverlay({
    Key? key,
    this.childBuilder,
    this.onAreaSelectionUpdate,
    this.onSelectionStateChanged,
    this.onScrollControllerProvided,
    this.onClearSelection,
    this.onSelectionStart,
    this.scrollController,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<AreaSelectionOverlay> createState() => AreaSelectionOverlayState();
}

class AreaSelectionOverlayState extends State<AreaSelectionOverlay> {
  Rect? _selectionArea;
  Offset? _startPoint;
  bool _isSelectionActive = false;
  Timer? _scrollTimer;
  ScrollController? _scrollController;
  late final AreaSelectionOverlayController _controller;
  Widget? _childWidget; // 可选的子组件缓存

  // 使用ValueNotifier来优化矩形的重绘，避免重建整个组件
  final ValueNotifier<Rect?> _selectionRectNotifier = ValueNotifier<Rect?>(
    null,
  );
  final ValueNotifier<bool> _showSelectionNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _selectionModeEnabledNotifier = ValueNotifier<bool>(
    false,
  );

  @override
  void initState() {
    super.initState();
    _controller = AreaSelectionOverlayController();
    _controller._attach(this);

    // 设置ScrollController
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController;
      widget.onScrollControllerProvided?.call(_scrollController!);
    }

    // 只在有childBuilder时创建子组件
    if (widget.childBuilder != null) {
      _childWidget = RepaintBoundary(
        child: _ChildWidget(
          childBuilder: widget.childBuilder!,
          controller: _controller,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _selectionRectNotifier.dispose();
    _showSelectionNotifier.dispose();
    _selectionModeEnabledNotifier.dispose();
    super.dispose();
  }

  /// 由子组件调用，开始显示选择区域
  void showSelection() {
    _showSelectionNotifier.value = true;
  }

  /// 隐藏选择区域
  void hideSelection() {
    _showSelectionNotifier.value = false;
    _selectionRectNotifier.value = null;
    _selectionArea = null;
    _startPoint = null;
    _isSelectionActive = false;
  }

  /// 开始选择模式（由控制器调用）
  void startSelectionMode() {
    if (!widget.enabled) return;
    _selectionModeEnabledNotifier.value = true;
    showSelection();
    widget.onSelectionStateChanged?.call(true);
  }

  /// 结束选择模式（由控制器调用）
  void endSelectionMode() {
    _selectionModeEnabledNotifier.value = false;
    hideSelection();
    widget.onSelectionStateChanged?.call(false);
  }

  /// 设置ScrollController（由控制器调用）
  void setScrollController(ScrollController controller) {
    _scrollController = controller;
    widget.onScrollControllerProvided?.call(controller);
  }

  void _startSelection(Offset position) {
    if (!widget.enabled || !_selectionModeEnabledNotifier.value) return;

    _startPoint = position;
    _selectionArea = Rect.fromLTWH(position.dx, position.dy, 0, 0);
    _isSelectionActive = true;

    // 通知子组件开始选择
    widget.onSelectionStart?.call(position);
  }

  void _updateSelection(Offset position) {
    if (!_isSelectionActive || _startPoint == null) return;

    // 获取child组件的边界限制
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    // 限制position在child范围内
    final clampedPosition = Offset(
      position.dx.clamp(0.0, size.width),
      position.dy.clamp(0.0, size.height),
    );

    // 不使用setState，避免重建UI
    _selectionArea = Rect.fromPoints(_startPoint!, clampedPosition);

    // 只更新矩形显示，不重建整个组件
    _selectionRectNotifier.value = _selectionArea;

    // 通知外部组件选择区域更新
    if (_selectionArea != null) {
      widget.onAreaSelectionUpdate?.call(_selectionArea!);
    }

    // 检查是否需要滚动
    _handleAutoScroll(position);
  }

  void _endSelection() {
    _scrollTimer?.cancel();
    _isSelectionActive = false;

    // 保持选择矩形显示，不自动隐藏
    // 由外部控制器决定何时隐藏
  }

  void _handleAutoScroll(Offset position) {
    if (!mounted || _scrollController == null) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    const double scrollThreshold = 100.0;
    const double scrollSpeed = 200.0;

    _scrollTimer?.cancel();

    double? deltaY;

    if (position.dy < scrollThreshold) {
      // 需要向上滚动
      deltaY = -scrollSpeed * 0.016;
    } else if (position.dy > size.height - scrollThreshold) {
      // 需要向下滚动
      deltaY = scrollSpeed * 0.016;
    }

    if (deltaY != null) {
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!mounted || !_isSelectionActive || _scrollController == null) {
          timer.cancel();
          return;
        }

        // 使用ScrollController进行滚动
        final currentOffset = _scrollController!.offset;
        final newOffset = (currentOffset + deltaY!).clamp(
          _scrollController!.position.minScrollExtent,
          _scrollController!.position.maxScrollExtent,
        );

        if (newOffset != currentOffset) {
          _scrollController!.jumpTo(newOffset);
        }
      });
    }
  }

  void _clearSelection() {
    _endSelection();
    widget.onClearSelection?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 子组件层 - 只在有childBuilder时显示
        if (_childWidget != null) _childWidget!,

        // 透明的交互层 - 使用ValueListenableBuilder监听选择模式状态
        if (widget.enabled)
          ValueListenableBuilder<bool>(
            valueListenable: _selectionModeEnabledNotifier,
            builder: (context, selectionModeEnabled, _) {
              return _InteractionLayer(
                enabled: selectionModeEnabled,
                onDoubleTap: _clearSelection,
                onPanStart: (details) => _startSelection(details.localPosition),
                onPanUpdate:
                    (details) => _updateSelection(details.localPosition),
                onPanEnd: (details) => _endSelection(),
              );
            },
          ),

        // 选择区域视觉反馈层 - 直接使用，RepaintBoundary在内部
        _SelectionOverlay(
          showSelectionNotifier: _showSelectionNotifier,
          selectionRectNotifier: _selectionRectNotifier,
        ),
      ],
    );
  }
}

/// 完全隔离的子组件widget，避免重绘
class _ChildWidget extends StatelessWidget {
  final Widget Function(AreaSelectionOverlayController controller) childBuilder;
  final AreaSelectionOverlayController controller;

  const _ChildWidget({required this.childBuilder, required this.controller});

  @override
  Widget build(BuildContext context) {
    return childBuilder(controller);
  }
}

/// 完全隔离的交互层widget
class _InteractionLayer extends StatelessWidget {
  final bool enabled;
  final VoidCallback onDoubleTap;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  const _InteractionLayer({
    required this.enabled,
    required this.onDoubleTap,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onDoubleTap: onDoubleTap,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

/// 完全独立的选择矩形渲染widget，使用CustomPainter优化性能
class _SelectionOverlay extends StatelessWidget {
  final ValueNotifier<bool> showSelectionNotifier;
  final ValueNotifier<Rect?> selectionRectNotifier;

  const _SelectionOverlay({
    required this.showSelectionNotifier,
    required this.selectionRectNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: showSelectionNotifier,
      builder: (context, showSelection, _) {
        if (!showSelection) return const SizedBox.shrink();

        return ValueListenableBuilder<Rect?>(
          valueListenable: selectionRectNotifier,
          builder: (context, selectionRect, _) {
            if (selectionRect == null) return const SizedBox.shrink();

            return Positioned.fill(
              child: RepaintBoundary(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SelectionRectPainter(
                      selectionRect: selectionRect,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 自定义画笔，用于高效绘制选择矩形
class _SelectionRectPainter extends CustomPainter {
  final Rect selectionRect;
  final Color color;

  _SelectionRectPainter({required this.selectionRect, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint =
        Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    final Paint strokePaint =
        Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    // 绘制填充
    canvas.drawRect(selectionRect, fillPaint);

    // 绘制边框
    canvas.drawRect(selectionRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionRectPainter oldDelegate) {
    return oldDelegate.selectionRect != selectionRect ||
        oldDelegate.color != color;
  }
}
