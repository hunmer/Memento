import 'package:flutter/material.dart';
import '../../plugin_base.dart';

/// 最小化状态的插件图标
/// 复用FloatingBallWidget的拖拽逻辑，用于显示最小化的插件
class MinimizedPluginIcon extends StatefulWidget {
  final PluginBase plugin;
  final VoidCallback? onRestore;
  final Function(Offset)? onPositionChanged; // 位置变化回调，传递新位置
  final double? initialX;
  final double? initialY;

  const MinimizedPluginIcon({
    super.key,
    required this.plugin,
    this.onRestore,
    this.onPositionChanged,
    this.initialX,
    this.initialY,
  });

  @override
  State<MinimizedPluginIcon> createState() => _MinimizedPluginIconState();
}

class _MinimizedPluginIconState extends State<MinimizedPluginIcon>
    with SingleTickerProviderStateMixin {
  static const double _iconSize = 40;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // 位置相关
  late Offset _position;
  bool _isInitialized = false;
  bool _isDragging = false;
  Offset _dragStartOffset = Offset.zero;
  Offset _initialIconPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // 延迟到下一帧调用，确保context已经准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializePosition();
        _animationController.forward();
      }
    });
  }

  /// 获取默认位置
  Offset _getDefaultPosition(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 如果有初始位置，使用初始位置
    if (widget.initialX != null && widget.initialY != null) {
      return Offset(widget.initialX!, widget.initialY!);
    } else {
      // 否则默认放在右下角
      return Offset(
        screenSize.width - _iconSize - 20,
        screenSize.height - _iconSize - 20,
      );
    }
  }

  void _initializePosition() {
    if (_isInitialized) return; // 避免重复初始化

    final screenSize = MediaQuery.of(context).size;

    _position = _getDefaultPosition(context);

    // 确保位置在屏幕范围内
    _position = Offset(
      _position.dx.clamp(0, screenSize.width - _iconSize),
      _position.dy.clamp(0, screenSize.height - _iconSize),
    );

    _isInitialized = true;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleRestore() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onRestore?.call();
      }
    });
  }

  void _handlePanStart(DragStartDetails details) {
    _isDragging = true;
    _dragStartOffset = details.globalPosition;

    // 确保_position已初始化
    if (!_isInitialized) {
      _initializePosition();
    }
    _initialIconPosition = _position;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final delta = details.globalPosition - _dragStartOffset;
    _position = _initialIconPosition + delta;

    // 限制图标在屏幕内
    final screenSize = MediaQuery.of(context).size;
    _position = Offset(
      _position.dx.clamp(0, screenSize.width - _iconSize),
      _position.dy.clamp(0, screenSize.height - _iconSize),
    );

    setState(() {});
  }

  void _handlePanEnd(DragEndDetails details) {
    _isDragging = false;

    // 通知位置变化，传递当前位置
    if (widget.onPositionChanged != null && _isInitialized) {
      widget.onPositionChanged!(_position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              // 确保_position已初始化，如果未初始化则使用默认位置
              final currentPosition =
                  _isInitialized ? _position : _getDefaultPosition(context);
              return Positioned(
                left: currentPosition.dx,
                top: currentPosition.dy,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: GestureDetector(
                    onPanStart: _handlePanStart,
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: _handlePanEnd,
                    onTap: _handleRestore,
                    child: Container(
                      width: _iconSize,
                      height: _iconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            widget.plugin.color ??
                            Theme.of(context).primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // 插件图标
                          Center(
                            child: Icon(
                              widget.plugin.icon ?? Icons.extension,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
