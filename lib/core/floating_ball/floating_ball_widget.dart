import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'floating_ball_manager.dart';
import 'settings_screen.dart';

class FloatingBallWidget extends StatefulWidget {
  final double size;
  final Color color;
  
  const FloatingBallWidget({
    super.key, 
    this.size = 60, 
    this.color = Colors.blue,
  });

  @override
  State<FloatingBallWidget> createState() => _FloatingBallWidgetState();
}

class _FloatingBallWidgetState extends State<FloatingBallWidget> {
  final FloatingBallManager _manager = FloatingBallManager();
  Offset? _position; // 改为可空类型
  bool _isDragging = false;
  Timer? _longPressTimer;
  Offset? _dragStartPosition;
  bool _isLoading = true; // 添加加载状态标志
  bool _canDrag = false; // 是否可以拖动
  Offset? _lastLongPressDragUpdate; // 最后一次长按拖动更新的位置
  
  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    final position = await _manager.getPosition();
    if (mounted) { // 检查widget是否还在树中
      setState(() {
        _position = position;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  // 长按开始时
  void _handleLongPressDown(LongPressDownDetails details) {
    if (_position == null) return;
    
    setState(() {
      _canDrag = true;
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
      _lastLongPressDragUpdate = details.globalPosition;
    });
  }

  // 长按拖动更新
  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_position == null || !_canDrag) return;
    
    // 计算拖动的偏移量
    final delta = details.globalPosition - (_lastLongPressDragUpdate ?? details.globalPosition);
    _lastLongPressDragUpdate = details.globalPosition;
    
    setState(() {
      _position = Offset(
        _position!.dx + delta.dx,
        _position!.dy + delta.dy,
      );
    });
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
        final dragDistance = (_dragStartPosition! - details.globalPosition).distance;
        // 如果拖动距离很短(小于阈值)，可能是用户想要滑动而不是拖动
        if (dragDistance < 10) {
          final dragVector = details.globalPosition - _dragStartPosition!;
          _handleSwipe(dragVector);
        }
      }
    }
    
    setState(() {
      _isDragging = false;
      _canDrag = false;
      _lastLongPressDragUpdate = null;
      _dragStartPosition = null;
    });
  }

  void _handleSwipe(Offset velocity) {
    // 如果滑动距离太小，不触发任何动作
    if (velocity.distance < 5) return;
    
    // 判断滑动方向
    final absX = velocity.dx.abs();
    final absY = velocity.dy.abs();
    
    if (absX > absY) {
      // 水平方向滑动
      if (velocity.dx > 0) {
        // 右滑
        final action = _manager.getAction(FloatingBallGesture.swipeRight);
        if (action != null) {
          action();
        }
      } else {
        // 左滑
        final action = _manager.getAction(FloatingBallGesture.swipeLeft);
        if (action != null) {
          action();
        }
      }
    } else {
      // 垂直方向滑动
      if (velocity.dy > 0) {
        // 下滑
        final action = _manager.getAction(FloatingBallGesture.swipeDown);
        if (action != null) {
          action();
        }
      } else {
        // 上滑
        final action = _manager.getAction(FloatingBallGesture.swipeUp);
        if (action != null) {
          action();
        }
      }
    }
  }

  void _handleTap() {
    final action = _manager.getAction(FloatingBallGesture.tap);
    if (action != null) action();
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
      _position!.dx.clamp(0, screenSize.width - widget.size),
      _position!.dy.clamp(0, screenSize.height - widget.size),
    );
    
    if (safePosition != _position) {
      _position = safePosition;
      _manager.savePosition(_position!);
    }

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        onLongPressDown: _handleLongPressDown,
        onLongPressMoveUpdate: _handleLongPressMoveUpdate,
        onLongPressEnd: _handleLongPressEnd,
        onLongPressCancel: () {
          _longPressTimer?.cancel();
          setState(() {
            _canDrag = false;
            _isDragging = false;
            _lastLongPressDragUpdate = null;
            _dragStartPosition = null;
          });
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _canDrag ? widget.color.withAlpha(179) : widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(77),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
            border: _canDrag ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: const Center(
            child: Icon(
              Icons.touch_app,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}