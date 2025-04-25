import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'floating_ball_service.dart';
import 'floating_ball_manager.dart';
import 'floating_ball_service.dart';
import 'settings_screen.dart';

class FloatingBallWidget extends StatefulWidget {
  final double baseSize;
  final Color color;
  final String iconPath;

  const FloatingBallWidget({
    super.key,
    this.baseSize = 60,
    this.color = Colors.blue,
    this.iconPath = 'assets/icon/icon.png',
  });

  @override
  State<FloatingBallWidget> createState() => _FloatingBallWidgetState();
}

class _FloatingBallWidgetState extends State<FloatingBallWidget>
    with TickerProviderStateMixin {
  final FloatingBallManager _manager = FloatingBallManager();
  Offset? _position; // 改为可空类型
  bool _isDragging = false;
  Timer? _longPressTimer;
  Offset? _dragStartPosition;
  bool _isLoading = true; // 添加加载状态标志
  bool _canDrag = false; // 是否可以拖动
  Offset? _lastLongPressDragUpdate; // 最后一次长按拖动更新的位置
  Offset? _panStartPosition; // 滑动开始位置
  DateTime? _panStartTime; // 滑动开始时间
  double _sizeScale = 1.0; // 大小比例

  // 添加指针移出检测相关变量
  bool _pointerDown = false;
  final GlobalKey _ballKey = GlobalKey();
  StreamSubscription<double>? _sizeSubscription;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _initializePosition();
    _loadSizeScale();

    // 监听大小变化
    _sizeSubscription = FloatingBallService().sizeChangeStream.listen((scale) {
      if (mounted) {
        setState(() {
          _sizeScale = scale;
        });
      }
    });

    // 在下一帧更新上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FloatingBallService().updateContext(context);
        // 设置动作上下文
        _manager.setActionContext(context);
      }
    });
  }

  Future<void> _initializePosition() async {
    try {
      final position = await _manager.getPosition();
      if (!mounted) return;

      // 获取屏幕大小
      final screenSize = MediaQuery.of(context).size;

      // 确保位置在屏幕范围内
      final safePosition = Offset(
        position.dx.clamp(0, screenSize.width - widget.baseSize),
        position.dy.clamp(0, screenSize.height - widget.baseSize),
      );

      setState(() {
        _position = safePosition;
        _isLoading = false;
      });

      // 如果位置被调整了，保存新的安全位置
      if (safePosition != position) {
        _manager.savePosition(safePosition);
      }
    } catch (e) {
      debugPrint('Error loading position: $e');
      if (mounted) {
        // 如果加载失败，使用默认位置
        setState(() {
          _position = const Offset(20, 100);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSizeScale() async {
    final scale = await _manager.getSizeScale();
    if (mounted) {
      setState(() {
        _sizeScale = scale;
      });
    }
  }

  double get _currentSize => widget.baseSize * _sizeScale;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _sizeSubscription?.cancel();
    super.dispose();
  }

  // 长按开始时
  void _handleLongPressDown(LongPressDownDetails details) {
    if (_position == null) return;

    setState(() {
      _pointerDown = true;
      _canDrag = true;
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
      _lastLongPressDragUpdate = details.globalPosition;
    });
  }

  // 检查指针是否在悬浮球内
  bool _isPointerInsideBall(Offset globalPosition) {
    if (_ballKey.currentContext == null) return false;

    final RenderBox renderBox =
        _ballKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset localPosition = renderBox.globalToLocal(globalPosition);

    // 检查点是否在圆形内
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final distance = (localPosition - center).distance;

    return distance <= radius;
  }

  // 长按拖动更新
  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_position == null || !_canDrag) return;

    // 计算拖动的偏移量
    final delta =
        details.globalPosition -
        (_lastLongPressDragUpdate ?? details.globalPosition);
    _lastLongPressDragUpdate = details.globalPosition;

    // 获取屏幕大小
    final screenSize = MediaQuery.of(context).size;

    // 计算新位置，并确保在屏幕范围内
    final newPosition = Offset(
      (_position!.dx + delta.dx).clamp(0, screenSize.width - _currentSize),
      (_position!.dy + delta.dy).clamp(0, screenSize.height - _currentSize),
    );

    setState(() {
      _position = newPosition;
    });

    // 实时保存位置
    _manager.savePosition(newPosition);

    // 检查指针是否移出悬浮球
    if (_pointerDown && !_isPointerInsideBall(details.globalPosition)) {
      _handlePointerExit(details.globalPosition);
    }
  }

  // 处理指针移出悬浮球
  void _handlePointerExit(Offset exitPosition) {
    if (!_pointerDown || !_canDrag) return;

    // 计算滑动方向
    if (_dragStartPosition != null) {
      final dragVector = exitPosition - _dragStartPosition!;
      final dragDistance = dragVector.distance;

      // 如果移动距离足够大，触发滑动动作
      if (dragDistance > 10) {
        _handleSwipe(dragVector);
      }
    }

    // 重置状态
    setState(() {
      _pointerDown = false;
      _canDrag = false;
      _isDragging = false;
      _lastLongPressDragUpdate = null;
    });

    // 保存当前位置
    if (_position != null) {
      _manager.savePosition(_position!);
    }
  }

  // 长按拖动结束
  void _handleLongPressEnd(LongPressEndDetails details) {
    _longPressTimer?.cancel();

    if (_position == null) return;

    // 保存位置
    if (_isDragging && _canDrag) {
      _manager.savePosition(_position!);

      // 只有在拖动距离很短时才考虑触发滑动手势
      // 这样可以区分真正的拖动和滑动意图
      if (_dragStartPosition != null) {
        final dragDistance =
            (_dragStartPosition! - details.globalPosition).distance;
        // 如果拖动距离很短(小于阈值)，可能是用户想要滑动而不是拖动
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

  void _handleSwipe(Offset velocity) {
    // 如果滑动距离太小，不触发任何动作
    if (velocity.distance < 5) return;

    // 打印滑动信息，便于调试
    debugPrint('Swipe detected: $velocity, distance: ${velocity.distance}');

    // 判断滑动方向
    final absX = velocity.dx.abs();
    final absY = velocity.dy.abs();

    // 设置方向判定的阈值，使判断更准确
    const directionThreshold = 2.0; // 如果一个方向的分量是另一个方向的2倍以上，才判定为该方向

    FloatingBallGesture? gesture;

    if (absX > absY * directionThreshold) {
      // 明显的水平方向滑动
      gesture =
          velocity.dx > 0
              ? FloatingBallGesture.swipeRight
              : FloatingBallGesture.swipeLeft;
    } else if (absY > absX * directionThreshold) {
      // 明显的垂直方向滑动
      gesture =
          velocity.dy > 0
              ? FloatingBallGesture.swipeDown
              : FloatingBallGesture.swipeUp;
    } else if (absX > absY) {
      // 偏水平方向滑动
      gesture =
          velocity.dx > 0
              ? FloatingBallGesture.swipeRight
              : FloatingBallGesture.swipeLeft;
    } else {
      // 偏垂直方向滑动
      gesture =
          velocity.dy > 0
              ? FloatingBallGesture.swipeDown
              : FloatingBallGesture.swipeUp;
    }

    if (gesture != null) {
      final action = _manager.getAction(gesture);
      if (action != null) {
        debugPrint('Executing action for gesture: $gesture');
        action();
      } else {
        debugPrint('No action registered for gesture: $gesture');
      }
    }
  }

  void _handleTap() {
    debugPrint('Tap detected');
    final action = _manager.getAction(FloatingBallGesture.tap);
    if (action != null) {
      debugPrint('Executing tap action');
      action();
    } else {
      debugPrint('No tap action registered');
    }
  }

  // 双击打开设置页面
  void _handleDoubleTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FloatingBallSettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 确保动作上下文是最新的
    _manager.setActionContext(context);

    // 如果位置还没加载完成，显示一个加载指示器或返回空容器
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

    // 确保悬浮球在屏幕范围内
    final screenSize = MediaQuery.of(context).size;
    final safePosition = Offset(
      _position!.dx.clamp(0, screenSize.width - _currentSize),
      _position!.dy.clamp(0, screenSize.height - _currentSize),
    );

    if (safePosition != _position) {
      _position = safePosition;
      _manager.savePosition(_position!);
    }

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: Listener(
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
              !_isPointerInsideBall(event.position)) {
            _handlePointerExit(event.position);
          }
        },
        child: GestureDetector(
          onTap: _handleTap,
          onDoubleTap: _handleDoubleTap,
          onLongPressDown: _handleLongPressDown,
          onLongPressMoveUpdate: _handleLongPressMoveUpdate,
          onLongPressEnd: _handleLongPressEnd,
          onPanStart: (details) {
            if (_isDragging) return; // 如果正在长按拖动，不处理滑动
            setState(() {
              _panStartPosition = details.globalPosition;
              _panStartTime = DateTime.now();
            });
          },
          onPanUpdate: (details) {
            if (_isDragging || _panStartPosition == null)
              return; // 如果正在长按拖动，不处理滑动

            // 在桌面端，我们不立即处理滑动，而是在onPanEnd中处理
          },
          onPanEnd: (details) {
            if (_isDragging || _panStartPosition == null)
              return; // 如果正在长按拖动，不处理滑动

            // 计算滑动时间和距离
            final now = DateTime.now();
            final duration = now.difference(_panStartTime!).inMilliseconds;
            final endPosition = details.globalPosition;
            final distance = (endPosition - _panStartPosition!).distance;
            final velocity = endPosition - _panStartPosition!;

            // 如果滑动时间小于500毫秒且距离大于10，触发滑动手势
            if (duration < 500 && distance > 10) {
              _handleSwipe(velocity);
            }

            setState(() {
              _panStartPosition = null;
              _panStartTime = null;
            });
          },
          onLongPressCancel: () {
            _longPressTimer?.cancel();
            setState(() {
              _pointerDown = false;
              _canDrag = false;
              _isDragging = false;
              _lastLongPressDragUpdate = null;
              _dragStartPosition = null;
            });
          },
          child: SizedBox(
            key: _ballKey,
            width: _currentSize,
            height: _currentSize,
            child: ClipOval(
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
    );
  }
}
