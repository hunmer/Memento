import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'dart:math';
import '../adapters/floating_ball_platform_adapter.dart';
import '../models/floating_ball_gesture.dart';

/// 可复用的悬浮球组件
///
/// 支持两种运行环境：
/// - isInOverlay=false: 在应用内使用Overlay显示
/// - isInOverlay=true: 在OverlayWindow中显示
class SharedFloatingBallWidget extends StatefulWidget {
  /// 是否在OverlayWindow环境中运行
  final bool isInOverlay;

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
    this.isInOverlay = false,
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
  State<SharedFloatingBallWidget> createState() => _SharedFloatingBallWidgetState();
}

class _SharedFloatingBallWidgetState extends State<SharedFloatingBallWidget>
    with TickerProviderStateMixin {

  late FloatingBallPlatformAdapter _adapter;
  Offset? _position;
  bool _isDragging = false;
  bool _isExpanded = false;
  Timer? _longPressTimer;
  Offset? _dragStartPosition;
  bool _isLoading = true;
  bool _canDrag = false;
  Offset? _lastLongPressDragUpdate;
  Offset? _panStartPosition;
  DateTime? _panStartTime;
  final double _sizeScale = 1.0;
  bool _pointerDown = false;
  final GlobalKey _ballKey = GlobalKey();

  // 圆球选项展开相关
  List<Map<String, dynamic>> _optionBalls = [];
  AnimationController? _expandController;
  Animation<double>? _expandAnimation;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 初始化平台适配器
    _adapter = widget.platformAdapter ??
        FloatingBallAdapterFactory.create(isInOverlay: widget.isInOverlay);

    await _adapter.initialize();

    _initializePosition();
    _initializeAnimations();
    _initializeOptionBalls();

    // 通知初始化完成
    widget.onConfigChanged?.call();
  }

  void _initializePosition() {
    if (widget.isInOverlay) {
      // OverlayWindow环境下使用默认位置
      setState(() {
        _position = const Offset(10, 10);
        _isLoading = false;
      });
    } else {
      // Overlay环境下从配置加载位置
      _loadPositionFromConfig();
    }
  }

  Future<void> _loadPositionFromConfig() async {
    try {
      // TODO: 从配置管理器加载位置
      final position = const Offset(21, 99); // 默认位置

      if (!mounted) return;

      final screenSize = _adapter.getScreenSize(context);
      final safePosition = Offset(
        position.dx.clamp(0, screenSize.width - _currentSize),
        position.dy.clamp(0, screenSize.height - _currentSize),
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

  void _initializeAnimations() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController!,
      curve: Curves.easeOutBack,
    );
  }

  void _initializeOptionBalls() {
    _optionBalls = [
      {'icon': Icons.chat, 'label': '聊天', 'action': FloatingBallGesture.tap},
      {'icon': Icons.note, 'label': '日记', 'action': FloatingBallGesture.swipeUp},
      {'icon': Icons.list, 'label': '待办', 'action': FloatingBallGesture.swipeDown},
      {'icon': Icons.event, 'label': '日历', 'action': FloatingBallGesture.swipeLeft},
      {'icon': Icons.settings, 'label': '设置', 'action': FloatingBallGesture.swipeRight},
    ];
  }

  double get _currentSize => widget.baseSize * _sizeScale;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _expandController?.dispose();
    _adapter.dispose();
    super.dispose();
  }

  // 长按开始
  void _handleLongPressDown(LongPressDownDetails details) {
    if (!_adapter.supportsDragging || _position == null) return;

    if (widget.isInOverlay) {
      // OverlayWindow环境下，长按展开选项
      _toggleExpandOptions();
    } else {
      // Overlay环境下，长按开始拖动
      setState(() {
        _pointerDown = true;
        _canDrag = true;
        _isDragging = true;
        _dragStartPosition = details.globalPosition;
        _lastLongPressDragUpdate = details.globalPosition;
      });
    }
  }

  // 展开/收起选项
  void _toggleExpandOptions() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController?.forward();
    } else {
      _expandController?.reverse();
    }
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

    final delta = details.globalPosition -
        (_lastLongPressDragUpdate ?? details.globalPosition);
    _lastLongPressDragUpdate = details.globalPosition;

    final screenSize = _adapter.getScreenSize(context);
    final newPosition = Offset(
      (_position!.dx + delta.dx).clamp(0, screenSize.width - _currentSize),
      (_position!.dy + delta.dy).clamp(0, screenSize.height - _currentSize),
    );

    setState(() {
      _position = newPosition;
    });

    widget.onPositionChanged?.call(newPosition);

    // 检查指针是否移出悬浮球
    if (_pointerDown && !_isPointerInsideBall(details.globalPosition, _currentSize)) {
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
      gesture = velocity.dx > 0
          ? FloatingBallGesture.swipeRight
          : FloatingBallGesture.swipeLeft;
    } else if (absY > absX * directionThreshold) {
      gesture = velocity.dy > 0
          ? FloatingBallGesture.swipeDown
          : FloatingBallGesture.swipeUp;
    } else if (absX > absY) {
      gesture = velocity.dx > 0
          ? FloatingBallGesture.swipeRight
          : FloatingBallGesture.swipeLeft;
    } else {
      gesture = velocity.dy > 0
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
    if (widget.isInOverlay && _isExpanded) {
      // 如果已展开，点击收起
      _toggleExpandOptions();
    } else if (widget.isInOverlay) {
      // OverlayWindow环境下点击展开
      _toggleExpandOptions();
    } else {
      // Overlay环境下执行绑定的动作
      widget.onGesture?.call(FloatingBallGesture.tap);
    }
  }

  // 处理选项球点击
  void _handleOptionBallTap(Map<String, dynamic> option) {
    final action = option['action'] as FloatingBallGesture;
    widget.onGesture?.call(action);
    _toggleExpandOptions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _position == null) {
      return const Positioned(
        right: 20,
        bottom: 20,
        child: SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(),
        ),
      );
    }

    final screenSize = _adapter.getScreenSize(context);
    final safePosition = Offset(
      _position!.dx.clamp(0, screenSize.width - _currentSize),
      _position!.dy.clamp(0, screenSize.height - _currentSize),
    );

    if (safePosition != _position) {
      _position = safePosition;
      widget.onPositionChanged?.call(_position!);
    }

    return Stack(
      children: [
        // 主悬浮球
        Positioned(
          left: _position!.dx,
          top: _position!.dy,
          child: _buildMainBall(),
        ),

        // 展开的选项球（仅在OverlayWindow环境下显示）
        if (widget.isInOverlay && _isExpanded) ..._buildExpandedOptions(),
      ],
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
        if (_pointerDown && _canDrag &&
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
          if (_isDragging || widget.isInOverlay) return;
          setState(() {
            _panStartPosition = details.globalPosition;
            _panStartTime = DateTime.now();
          });
        },
        onPanUpdate: (details) {
          if (_isDragging || _panStartPosition == null || widget.isInOverlay) {
            return;
          }
        },
        onPanEnd: (details) {
          if (_isDragging || _panStartPosition == null || widget.isInOverlay) {
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

  List<Widget> _buildExpandedOptions() {
    if (_expandAnimation == null) return [];

    final centerX = _position!.dx + _currentSize / 2;
    final centerY = _position!.dy + _currentSize / 2;
    final radius = 80.0;

    return List.generate(_optionBalls.length, (index) {
      final option = _optionBalls[index];
      final angle = (index * 2 * pi) / _optionBalls.length - pi / 2;

      return AnimatedBuilder(
        animation: _expandAnimation!,
        builder: (context, child) {
          final animatedRadius = radius * _expandAnimation!.value;
          final animatedX = centerX + animatedRadius * cos(angle) - 25;
          final animatedY = centerY + animatedRadius * sin(angle) - 25;
          final opacity = _expandAnimation!.value;

          return Positioned(
            left: animatedX,
            top: animatedY,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: _expandAnimation!.value,
                child: _buildOptionBall(option),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildOptionBall(Map<String, dynamic> option) {
    return GestureDetector(
      onTap: () => _handleOptionBallTap(option),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Icon(
          option['icon'] as IconData,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
