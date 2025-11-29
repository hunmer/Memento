import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'dart:math' as math;
import '../adapters/floating_ball_platform_adapter.dart';
import '../models/floating_ball_gesture.dart';

/// 可复用的悬浮球组件
class SharedFloatingBallWidget extends StatefulWidget {
  /// 基础尺寸
  final double baseSize;

  /// 主题色
  final Color color;

  /// 图标路径
  final String iconPath;

  /// 平台适配器
  final FloatingBallPlatformAdapter? platformAdapter;

  /// 手势回调
  final Function(FloatingBallGesture gesture)? onGesture;

  /// 位置变化回调
  final Function(Offset position)? onPositionChanged;

  /// 大小变化回调
  final Function(double scale)? onSizeChanged;

  /// 配置变更回调
  final VoidCallback? onConfigChanged;

  const SharedFloatingBallWidget({
    super.key,
    this.baseSize = 60,
    this.color = Colors.blue,
    this.iconPath = 'assets/icon/icon.png',
    this.platformAdapter,
    this.onGesture,
    this.onPositionChanged,
    this.onSizeChanged,
    this.onConfigChanged,
  });

  @override
  State<SharedFloatingBallWidget> createState() =>
      _SharedFloatingBallWidgetState();
}

class _SharedFloatingBallWidgetState extends State<SharedFloatingBallWidget>
    with TickerProviderStateMixin {
  late FloatingBallPlatformAdapter _adapter;
  Offset? _position;
  bool _isDragging = false;
  Timer? _longPressTimer;
  Offset? _dragStartPosition;
  bool _isLoading = true;
  bool _canDrag = false;
  Offset? _lastLongPressDragUpdate;
  Offset? _panStartPosition;
  DateTime? _panStartTime;
  bool _pointerDown = false;
  final GlobalKey _ballKey = GlobalKey();

  // 大小相关（固定为1.0，不再动态调整）
  static const double _fixedSizeScale = 1.0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 初始化平台适配器
    _adapter =
        widget.platformAdapter ??
        FloatingBallAdapterFactory.create(isInOverlay: false);

    await _adapter.initialize();

    _initializePosition();

    // 通知初始化完成
    widget.onConfigChanged?.call();
  }

  void _initializePosition() {
    // 从配置加载位置
    _loadPositionFromConfig();
  }

  /// 确保位置在有效范围内
  Offset _clampPosition(Offset position) {
    final screenSize = _effectiveScreenSize();
    // 确保屏幕尺寸有效，避免出现0.0的情况
    final safeWidth = screenSize.width > 0 ? screenSize.width : 400.0;
    final safeHeight = screenSize.height > 0 ? screenSize.height : 400.0;

    // 确保当前尺寸有效
    final currentSize = _currentSize > 0 ? _currentSize : 60.0;

    // 计算最大位置，确保结果大于0
    final maxX = math.max(0.0, safeWidth - currentSize);
    final maxY = math.max(0.0, safeHeight - currentSize);

    return Offset(position.dx.clamp(0, maxX), position.dy.clamp(0, maxY));
  }

  Future<void> _loadPositionFromConfig() async {
    try {
      // TODO: 从配置管理器加载位置
      final position = const Offset(21, 99); // 默认位置

      if (!mounted) return;

      final screenSize = _adapter.getScreenSize(context);
      // 确保屏幕尺寸减去悬浮球尺寸后仍为正值
      final maxX = math.max(0.0, screenSize.width - _currentSize);
      final maxY = math.max(0.0, screenSize.height - _currentSize);

      final safePosition = Offset(
        position.dx.clamp(0, maxX),
        position.dy.clamp(0, maxY),
      );

      setState(() {
        _position = safePosition;
        _isLoading = false;
      });

      if (safePosition != position) {
        widget.onPositionChanged?.call(safePosition);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _position = const Offset(20, 100);
          _isLoading = false;
        });
      }
    }
  }

  double get _currentSize => widget.baseSize * _fixedSizeScale;

  /// 根据路径获取图标
  IconData _getIconFromPath(String iconPath) {
    switch (iconPath.toLowerCase()) {
      case 'home':
      case 'icons.home':
        return Icons.home;
      case 'chat':
      case 'icons.chat':
        return Icons.chat;
      case 'settings':
      case 'icons.settings':
        return Icons.settings;
      case 'favorite':
      case 'icons.favorite':
        return Icons.favorite;
      case 'star':
      case 'icons.star':
        return Icons.star;
      default:
        return Icons.circle; // 默认图标
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _adapter.dispose();
    super.dispose();
  }

  // 长按开始
  void _handleLongPressDown(LongPressDownDetails details) {
    if (!_adapter.supportsDragging || _position == null) return;

    // 长按开始拖动
    setState(() {
      _pointerDown = true;
      _canDrag = true;
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
      _lastLongPressDragUpdate = details.globalPosition;
    });
  }

  // 显示子菜单（简化版）
  Future<void> _showSubmenu() async {
    if (_position == null) {
      debugPrint('🎯 位置未初始化，无法显示子菜单');
      return;
    }

    debugPrint('🎯 简化版显示子菜单');
    // 简化版：直接发送 tap 手势，主应用会处理子菜单显示
    widget.onGesture?.call(FloatingBallGesture.tap);
  }

  // 检查指针是否在球内
  bool _isPointerInsideBall(Offset globalPosition, double ballSize) {
    if (_ballKey.currentContext == null) return false;

    final RenderBox renderBox =
        _ballKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset localPosition = renderBox.globalToLocal(globalPosition);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final distance = (localPosition - center).distance;

    return distance <= radius;
  }

  // 长按拖动更新
  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_adapter.supportsDragging || _position == null || !_canDrag) return;

    final delta =
        details.globalPosition -
        (_lastLongPressDragUpdate ?? details.globalPosition);
    _lastLongPressDragUpdate = details.globalPosition;

    final screenSize = _adapter.getScreenSize(context);
    // 确保屏幕尺寸减去悬浮球尺寸后仍为正值
    final maxX = math.max(0.0, screenSize.width - _currentSize);
    final maxY = math.max(0.0, screenSize.height - _currentSize);

    final newPosition = Offset(
      (_position!.dx + delta.dx).clamp(0, maxX),
      (_position!.dy + delta.dy).clamp(0, maxY),
    );

    setState(() {
      _position = newPosition;
    });

    widget.onPositionChanged?.call(newPosition);

    // 检查指针是否移出悬浮球
    if (_pointerDown &&
        !_isPointerInsideBall(details.globalPosition, _currentSize)) {
      _handlePointerExit(details.globalPosition);
    }
  }

  // 处理指针移出
  void _handlePointerExit(Offset exitPosition) {
    if (!_pointerDown || !_canDrag) return;

    if (_dragStartPosition != null) {
      final dragVector = exitPosition - _dragStartPosition!;
      final dragDistance = dragVector.distance;

      if (dragDistance > 10) {
        _handleSwipe(dragVector);
      }
    }

    setState(() {
      _pointerDown = false;
      _canDrag = false;
      _isDragging = false;
      _lastLongPressDragUpdate = null;
    });
  }

  // 长按结束
  void _handleLongPressEnd(LongPressEndDetails details) {
    _longPressTimer?.cancel();

    if (_position == null) return;

    if (_isDragging && _canDrag) {
      widget.onPositionChanged?.call(_position!);

      if (_dragStartPosition != null) {
        final dragDistance =
            (_dragStartPosition! - details.globalPosition).distance;
        if (dragDistance < 10) {
          final dragVector = details.globalPosition - _dragStartPosition!;
          _handleSwipe(dragVector);
        }
      }
    }

    setState(() {
      _pointerDown = false;
      _isDragging = false;
      _canDrag = false;
      _lastLongPressDragUpdate = null;
      _dragStartPosition = null;
    });
  }

  // 处理滑动
  void _handleSwipe(Offset velocity) {
    if (velocity.distance < 5) return;

    final absX = velocity.dx.abs();
    final absY = velocity.dy.abs();
    const directionThreshold = 2.0;

    FloatingBallGesture gesture;

    if (absX > absY * directionThreshold) {
      gesture =
          velocity.dx > 0
              ? FloatingBallGesture.swipeRight
              : FloatingBallGesture.swipeLeft;
    } else if (absY > absX * directionThreshold) {
      gesture =
          velocity.dy > 0
              ? FloatingBallGesture.swipeDown
              : FloatingBallGesture.swipeUp;
    } else if (absX > absY) {
      gesture =
          velocity.dx > 0
              ? FloatingBallGesture.swipeRight
              : FloatingBallGesture.swipeLeft;
    } else {
      gesture =
          velocity.dy > 0
              ? FloatingBallGesture.swipeDown
              : FloatingBallGesture.swipeUp;
    }

    // 检查适配器是否支持该手势
    if (_adapter.shouldHandleGesture(gesture)) {
      widget.onGesture?.call(gesture);
    }
  }

  // 处理点击
  void _handleTap() {
    debugPrint('🔥 _handleTap() called');

    // 执行tap手势动作
    debugPrint('执行tap手势动作');
    widget.onGesture?.call(FloatingBallGesture.tap);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🎯 SharedFloatingBallWidget.build() - isLoading: $_isLoading, position: $_position',
    );

    if (_isLoading) {
      debugPrint('🎯 显示加载中状态');
      return const Positioned(
        left: 170, // (400-60)/2 = 170，在400x400窗口内居中
        top: 170,
        child: SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    if (_position == null) {
      debugPrint('🎯 位置为空，使用默认位置');
      return const Positioned(
        left: 170,
        top: 170,
        child: SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    debugPrint('🎯 构建悬浮球，当前位置: $_position, 当前尺寸: $_currentSize');

    // 简化的构建：只显示主悬浮球，不再包含展开的选项球
    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: _buildMainBall(),
    );
  }

  Widget _buildMainBall() {
    return Listener(
      onPointerUp: (event) {
        if (_pointerDown) {
          setState(() {
            _pointerDown = false;
            if (_canDrag) {
              _canDrag = false;
              _isDragging = false;
            }
          });
        }
      },
      onPointerMove: (event) {
        if (_pointerDown &&
            _canDrag &&
            !_isPointerInsideBall(event.position, _currentSize)) {
          _handlePointerExit(event.position);
        }
      },
      child: GestureDetector(
        onTap: _handleTap,
        onLongPressDown: _handleLongPressDown,
        onLongPressMoveUpdate: _handleLongPressMoveUpdate,
        onLongPressEnd: _handleLongPressEnd,
        onPanStart: (details) {
          if (_isDragging) return;
          setState(() {
            _panStartPosition = details.globalPosition;
            _panStartTime = DateTime.now();
          });
        },
        onPanUpdate: (details) {
          if (_isDragging || _panStartPosition == null) {
            return;
          }
        },
        onPanEnd: (details) {
          if (_isDragging || _panStartPosition == null) {
            return;
          }

          final now = DateTime.now();
          final duration = now.difference(_panStartTime!).inMilliseconds;
          final endPosition = details.globalPosition;
          final distance = (endPosition - _panStartPosition!).distance;
          final velocity = endPosition - _panStartPosition!;

          if (duration < 500 && distance > 10) {
            _handleSwipe(velocity);
          }

          setState(() {
            _panStartPosition = null;
            _panStartTime = null;
          });
        },
        child: _adapter.adaptChildWidget(
          SizedBox(
            key: _ballKey,
            width: _currentSize,
            height: _currentSize,
            child: ClipOval(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  widget.iconPath,
                  width: _currentSize,
                  height: _currentSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Size _effectiveScreenSize() {
    final screenSize = _adapter.getScreenSize(context);

    // 确保屏幕尺寸有合理的最小值，避免因窗口太小导致计算错误
    final minWidth = math.max(screenSize.width, _currentSize + 50.0);
    final minHeight = math.max(screenSize.height, _currentSize + 50.0);

    return Size(minWidth, minHeight);
  }
}
