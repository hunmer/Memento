import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:async';
import 'dart:math' as math;
import '../adapters/floating_ball_platform_adapter.dart';
import '../models/floating_ball_gesture.dart';
import '../constants/overlay_window_constants.dart';
import '../floating_ball_manager.dart';

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

  /// 重置全局悬浮球位置（静态方法）
  static void resetGlobalPosition() {
    _SharedFloatingBallWidgetState._shouldResetPosition = true;
    debugPrint('🎯 标记需要重置全局悬浮球位置');
  }

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
  bool _pointerDown = false;
  final GlobalKey _ballKey = GlobalKey();
  Size _currentWindowSize = const Size(
    OverlayWindowDimensions.collapsedWidthDouble,
    OverlayWindowDimensions.collapsedHeightDouble,
  );
  Offset? _preExpandPosition;

  // 圆球选项展开相关
  List<Map<String, dynamic>> _optionBalls = [];
  AnimationController? _expandController;
  Animation<double>? _expandAnimation;

  // 双击保护
  bool _isAnimating = false;

  // 全局悬浮球位置持久化
  static Offset? _persistentPosition;
  static bool _shouldResetPosition = false;

  // 大小相关
  double _sizeScale = 1.0;
  bool _sizeLoaded = false;

  @override
  void initState() {
    super.initState();
    _initialize();

    // 注册大小变化回调
    final manager = FloatingBallManager();
    if (widget.isInOverlay) {
      manager.addOverlaySizeChangeCallback(_onSizeChanged);
    } else {
      manager.addSizeChangeCallback(_onSizeChanged);
    }
  }

  Future<void> _initialize() async {
    // 初始化平台适配器
    _adapter = widget.platformAdapter ??
        FloatingBallAdapterFactory.create(isInOverlay: widget.isInOverlay);

    await _adapter.initialize();

    await _loadSizeScale();
    _initializePosition();
    _initializeAnimations();
    _initializeOptionBalls();

    // 通知初始化完成
    widget.onConfigChanged?.call();
  }

  void _initializePosition() {
    if (widget.isInOverlay) {
      // 检查是否需要重置位置
      if (_shouldResetPosition) {
        _persistentPosition = null;
        _shouldResetPosition = false;
        debugPrint('🎯 清除持久化位置，重置到默认位置');
      }

      // 获取真实的窗口尺寸
      final screenSize = _adapter.getScreenSize(context);
      _currentWindowSize = screenSize;

      // 优先使用持久化位置，如果没有则使用默认位置
      final savedPosition = _persistentPosition;
      final defaultPosition = savedPosition ?? _centerPositionForSize(screenSize);

      // 确保位置在有效范围内
      final validPosition = _clampPosition(savedPosition ?? defaultPosition);

      setState(() {
        _position = validPosition;
        _isLoading = false;
      });
      debugPrint('🎯 全局悬浮球初始化位置: $_position');
      debugPrint('🎯 屏幕尺寸: ${screenSize.width}x${screenSize.height}');
      debugPrint('🎯 默认位置: $defaultPosition, 保存位置: $savedPosition');
    } else {
      // Overlay环境下从配置加载位置
      _loadPositionFromConfig();
    }
  }

  /// 重置位置到默认位置（实例方法）
  void resetPosition() {
    if (widget.isInOverlay) {
      _persistentPosition = null; // 清除持久化位置
      final defaultPosition = const Offset(20, 20); // 默认左上角位置
      final validPosition = _clampPosition(defaultPosition);

      setState(() {
        _position = validPosition;
      });

      widget.onPositionChanged?.call(validPosition);
      debugPrint('🎯 全局悬浮球重置到默认位置: $validPosition');
    }
  }

  /// 确保位置在有效范围内
  Offset _clampPosition(Offset position) {
    final screenSize = _effectiveScreenSize();
    // 确保屏幕尺寸有效，避免出现0.0的情况
    final safeWidth = screenSize.width > 0 ? screenSize.width : 400.0;
    final safeHeight = screenSize.height > 0 ? screenSize.height : 400.0;
    return Offset(
      position.dx.clamp(0, safeWidth - _currentSize),
      position.dy.clamp(0, safeHeight - _currentSize),
    );
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
      curve: Curves.easeOutCubic, // 使用更安全的动画曲线
    );

    // 监听动画状态
    _expandController?.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      }
    });
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
    _expandController?.dispose();
    _adapter.dispose();

    // 移除大小变化回调
    final manager = FloatingBallManager();
    if (widget.isInOverlay) {
      manager.removeOverlaySizeChangeCallback(_onSizeChanged);
    } else {
      manager.removeSizeChangeCallback(_onSizeChanged);
    }

    super.dispose();
  }

  // 大小变化回调
  void _onSizeChanged(double newScale) {
    if (!mounted || newScale == _sizeScale) return;

    debugPrint('🎯 悬浮球大小变化回调: $_sizeScale -> $newScale');

    setState(() {
      _sizeScale = newScale;
    });

    // 通知父组件
    widget.onSizeChanged?.call(newScale);
  }

  // 长按开始 - 仅应用内模式需要
  void _handleLongPressDown(LongPressDownDetails details) {
    if (widget.isInOverlay) {
      // 全局模式下不需要长按逻辑
      return;
    }

    if (!_adapter.supportsDragging || _position == null) return;

    // Overlay环境下，长按开始拖动
    setState(() {
      _pointerDown = true;
      _canDrag = true;
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
      _lastLongPressDragUpdate = details.globalPosition;
    });
  }

  // 展开/收起选项
  Future<void> _toggleExpandOptions() async {
    // 双击保护：如果正在动画中，忽略点击
    if (_isAnimating) {
      debugPrint('🎯 动画进行中，忽略点击');
      return;
    }

    debugPrint('🎯 _toggleExpandOptions() - 当前状态: $_isExpanded');
    final willExpand = !_isExpanded;
    setState(() {
      _isExpanded = willExpand;
      _isAnimating = true;
    });

    debugPrint('🎯 新的展开状态: $_isExpanded');
    if (_isExpanded) {
      debugPrint('🎯 开始展开动画');
      _expandController?.forward();
    } else {
      debugPrint('🎯 开始收起动画');
      _expandController?.reverse();
    }

    if (widget.isInOverlay) {
      unawaited(_applyOverlayWindowResize(expand: willExpand));
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
    debugPrint('🔥 _handleTap() called - isInOverlay: ${widget.isInOverlay}, _isExpanded: $_isExpanded');

    if (widget.isInOverlay && _isExpanded) {
      // 如果已展开，点击收起
      debugPrint('收起展开的选项');
      _toggleExpandOptions();
    } else if (widget.isInOverlay) {
      // OverlayWindow环境下点击展开
      debugPrint('展开选项菜单');
      _toggleExpandOptions();
    } else {
      // Overlay环境下执行绑定的动作
      debugPrint('执行tap手势动作');
      widget.onGesture?.call(FloatingBallGesture.tap);
    }
  }

  // 处理选项球点击
  void _handleOptionBallTap(Map<String, dynamic> option) {
    debugPrint('🎯 选项球被点击: ${option['label']}');
    final action = option['action'] as FloatingBallGesture;
    debugPrint('🎯 触发手势: $action');
    widget.onGesture?.call(action);
    _toggleExpandOptions();
  }

  @override
  Widget build(BuildContext context) {
    // 在每次构建时检查大小配置是否有更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_sizeLoaded) {
        _loadSizeScale();
      }
    });

    debugPrint('🎯 SharedFloatingBallWidget.build() - isLoading: $_isLoading, position: $_position, isInOverlay: ${widget.isInOverlay}, sizeScale: $_sizeScale');

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

    debugPrint('🎯 构建悬浮球，当前位置: $_position, 当前尺寸: $_currentSize, 大小比例: $_sizeScale');

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
    if (widget.isInOverlay) {
      // 全局悬浮球：简化手势处理
      return GestureDetector(
        onTap: () {
          debugPrint('🔥 全局悬浮球被点击');
          _handleTap();
        },
        onPanStart: (details) {
          if (_position == null) return;
          _dragStartPosition = details.globalPosition;
        },
        onPanUpdate: (details) {
          if (_position == null) return;

          final screenSize = _effectiveScreenSize();
          final newPosition = Offset(
            (_position!.dx + details.delta.dx).clamp(0, screenSize.width - _currentSize),
            (_position!.dy + details.delta.dy).clamp(0, screenSize.height - _currentSize),
          );

          if (newPosition == _position) return;

          setState(() {
            _position = newPosition;
          });

          // 保存位置到持久化变量
          _persistentPosition = newPosition;

          widget.onPositionChanged?.call(newPosition);
        },
        onPanEnd: (details) {
          if (_dragStartPosition == null) return;
          final velocity = details.globalPosition - _dragStartPosition!;
          _dragStartPosition = null;
          if (velocity.distance > 10) {
            _handleSwipe(velocity);
          }
        },
        child: Container(
          key: _ballKey,
          width: _currentSize,
          height: _currentSize,
          decoration: BoxDecoration(
            color: widget.color, // 使用配置的颜色
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: widget.iconPath.startsWith('assets')
              ? Image.asset(
                  widget.iconPath,
                  width: _currentSize,
                  height: _currentSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 如果图片加载失败，显示默认图标
                    return Icon(
                      Icons.home,
                      size: _currentSize * 0.6,
                      color: Colors.white,
                    );
                  },
                )
              : Icon(
                  _getIconFromPath(widget.iconPath),
                  size: _currentSize * 0.6,
                  color: Colors.white,
                ),
          ),
        ),
      );
    } else {
      // 应用内悬浮球：保持原有复杂手势处理
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
  }

  List<Widget> _buildExpandedOptions() {
    if (_expandAnimation == null) return [];

    debugPrint('🎯 _buildExpandedOptions() - 选项球数量: ${_optionBalls.length}');
    final centerX = _position!.dx + _currentSize / 2;
    final centerY = _position!.dy + _currentSize / 2;

    final screenSize = _effectiveScreenSize();

    // 动态调整选项球大小：根据窗口大小计算合适的尺寸
    final optionBallSize = _resolveOptionBallSize(screenSize);
    final maxRadius = math.min(screenSize.width, screenSize.height) / 2 -
        _currentSize / 2 -
        optionBallSize -
        OverlayWindowDimensions.outerPadding;
    final radius = math.max(optionBallSize, maxRadius);

    debugPrint('🎯 主球中心位置: ($centerX, $centerY), 主球尺寸: $_currentSize');
    debugPrint('🎯 屏幕尺寸: ${screenSize.width}x${screenSize.height}, 选项球尺寸: $optionBallSize, 半径: $radius');
    debugPrint('🎯 最大半径: $maxRadius');

    return List.generate(_optionBalls.length, (index) {
      final option = _optionBalls[index];
      final angle = (index * 2 * math.pi) / _optionBalls.length - math.pi / 2;

      return AnimatedBuilder(
        animation: _expandAnimation!,
        builder: (context, child) {
          final animationValue = _expandAnimation!.value.clamp(0.0, 1.0);
          final animatedRadius = radius * animationValue;

          // 计算选项球位置
          var animatedX = centerX + animatedRadius * math.cos(angle) - (optionBallSize / 2);
          var animatedY = centerY + animatedRadius * math.sin(angle) - (optionBallSize / 2);

          // 边界检查和调整
          animatedX = animatedX.clamp(0.0, screenSize.width - optionBallSize);
          animatedY = animatedY.clamp(0.0, screenSize.height - optionBallSize);

          debugPrint('🎯 选项球$index 位置: ($animatedX, $animatedY), opacity: $animationValue');

          return Positioned(
            left: animatedX,
            top: animatedY,
            child: Opacity(
              opacity: animationValue,
              child: Transform.scale(
                scale: animationValue,
                child: _buildOptionBall(option, optionBallSize),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildOptionBall(Map<String, dynamic> option, [double? size]) {
    final optionBallSize = size ?? 40.0;
    final iconSize = optionBallSize * 0.6; // 图标尺寸为球尺寸的60%

    return GestureDetector(
      onTap: () => _handleOptionBallTap(option),
      child: Container(
        width: optionBallSize,
        height: optionBallSize,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Icon(
          option['icon'] as IconData,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }

  Size _effectiveScreenSize() {
    if (widget.isInOverlay) {
      return _currentWindowSize;
    }
    return _adapter.getScreenSize(context);
  }

  Offset _centerPositionForSize(Size windowSize) {
    final dx = (windowSize.width - _currentSize) / 2;
    final dy = (windowSize.height - _currentSize) / 2;
    return Offset(
      dx.clamp(0, math.max(0.0, windowSize.width - _currentSize)),
      dy.clamp(0, math.max(0.0, windowSize.height - _currentSize)),
    );
  }

  // 加载大小比例配置
  Future<void> _loadSizeScale() async {
    if (_sizeLoaded) return;

    try {
      final manager = FloatingBallManager();
      final scale = widget.isInOverlay
          ? await manager.getOverlaySizeScale()
          : await manager.getSizeScale();
      if (mounted) {
        setState(() {
          _sizeScale = scale;
          _sizeLoaded = true;
        });
      }
      debugPrint('🎯 加载${widget.isInOverlay ? 'Overlay' : '应用内'}悬浮球大小比例: $_sizeScale');
    } catch (e) {
      debugPrint('🎯 加载悬浮球大小比例失败: $e');
      // 使用默认大小
      if (mounted) {
        setState(() {
          _sizeScale = 1.0;
          _sizeLoaded = true;
        });
      }
    }
  }

  // 更新大小比例
  void _updateSizeScale(double newScale) {
    if (!mounted || newScale == _sizeScale) return;

    setState(() {
      _sizeScale = newScale;
    });

    debugPrint('🎯 更新悬浮球大小比例: $_sizeScale');

    // 通知外部大小变化
    widget.onSizeChanged?.call(newScale);
  }

  double _resolveOptionBallSize(Size screenSize) {
    final baseSize = _currentSize * 0.55;
    final adaptive = screenSize.shortestSide * 0.2;
    return math.max(
      32.0,
      math.min(48.0, math.min(baseSize, adaptive)),
    );
  }

  Size _calculateExpandedWindowSize() {
    final targetSide = math.max(
      OverlayWindowDimensions.minExpandedSize,
      math.max(_currentWindowSize.width, _currentWindowSize.height),
    );
    final virtualSize = Size(targetSide, targetSide);
    final optionBallSize = _resolveOptionBallSize(virtualSize);
    const spacingRatio = 1.3;
    final circumference = _optionBalls.length * (optionBallSize * spacingRatio);
    final radius = math.max(optionBallSize, circumference / (2 * math.pi));
    final diameter = _currentSize +
        (radius * 2) +
        (optionBallSize * 2) +
        OverlayWindowDimensions.outerPadding * 2;
    final finalSide = math.max(
      diameter,
      OverlayWindowDimensions.minExpandedSize,
    );
    return Size(finalSide, finalSide);
  }

  Future<void> _applyOverlayWindowResize({required bool expand}) async {
    if (!widget.isInOverlay) return;

    if (expand) {
      _preExpandPosition ??= _position;
      final targetSize = _calculateExpandedWindowSize();
      setState(() {
        _currentWindowSize = targetSize;
        _position = _centerPositionForSize(targetSize);
      });
      await FlutterOverlayWindow.resizeOverlay(
        targetSize.width.round(),
        targetSize.height.round(),
        false,
      );
    } else {
      const collapsedSize = Size(
        OverlayWindowDimensions.collapsedWidthDouble,
        OverlayWindowDimensions.collapsedHeightDouble,
      );
      await FlutterOverlayWindow.resizeOverlay(
        OverlayWindowDimensions.collapsedWidth,
        OverlayWindowDimensions.collapsedHeight,
        true,
      );
      setState(() {
        _currentWindowSize = collapsedSize;
        final fallback = _preExpandPosition ?? _centerPositionForSize(collapsedSize);
        _position = _clampPosition(fallback);
        _preExpandPosition = null;
      });
    }
  }
}
