import 'package:flutter/material.dart';

/// 路线点数据模型
class RoutePoint {
  /// 城市/地点名称
  final String city;

  /// 日期标签
  final String date;

  /// 是否已完成
  final bool isCompleted;

  const RoutePoint({
    required this.city,
    required this.date,
    required this.isCompleted,
  });

  /// 从 JSON 创建
  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      city: json['city'] as String? ?? '',
      date: json['date'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'date': date,
      'isCompleted': isCompleted,
    };
  }
}

/// 路线状态追踪卡片小组件
///
/// 用于显示运输路线、行程追踪等场景，包含起点、终点和当前状态的卡片。
/// 支持入场动画和深色模式。
class RouteTrackingCardWidget extends StatefulWidget {
  /// 日期标签（如 "Wed, 8 Aug"）
  final String date;

  /// 起点信息
  final RoutePoint origin;

  /// 终点信息
  final RoutePoint destination;

  /// 当前状态文本（如 "Shipped"、"In Transit"）
  final String status;

  /// 卡片宽度，默认 176
  final double width;

  /// 卡片高度，默认 176
  final double height;

  /// 圆角半径，默认 28
  final double borderRadius;

  /// 是否启用入场动画，默认 true
  final bool enableAnimation;

  const RouteTrackingCardWidget({
    super.key,
    required this.date,
    required this.origin,
    required this.destination,
    required this.status,
    this.width = 176,
    this.height = 176,
    this.borderRadius = 28,
    this.enableAnimation = true,
  });

  @override
  State<RouteTrackingCardWidget> createState() =>
      _RouteTrackingCardWidgetState();
}

class _RouteTrackingCardWidgetState extends State<RouteTrackingCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    if (widget.enableAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(RouteTrackingCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当关键数据变化时重新播放动画
    if (oldWidget.origin != widget.origin ||
        oldWidget.destination != widget.destination ||
        oldWidget.status != widget.status) {
      _animationController.reset();
      if (widget.enableAnimation) {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF18181B) : Colors.white;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.date,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  _buildTimeline(isDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPoint(
                          widget.origin.city,
                          widget.origin.date,
                          isDark,
                          widget.origin.isCompleted,
                        ),
                        _buildStatus(isDark),
                        _buildPoint(
                          widget.destination.city,
                          widget.destination.date,
                          isDark,
                          widget.destination.isCompleted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建时间轴线
  Widget _buildTimeline(bool isDark) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              width: 2,
            ),
            color: Colors.transparent,
          ),
        ),
        Expanded(
          child: Container(
            width: 1,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: CustomPaint(
              painter: _DashedLinePainter(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.white : Colors.grey.shade800,
            border: Border.all(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade300,
              width: 2,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建路线点信息
  Widget _buildPoint(String city, String date, bool isDark, bool isCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          city,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.grey.shade900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  /// 构建状态显示
  Widget _buildStatus(bool isDark) {
    return Row(
      children: [
        Text(
          widget.status,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
          ),
        ),
        const SizedBox(width: 6),
        Transform.rotate(
          angle: 45 * 3.14159 / 180,
          child: Icon(
            Icons.flight,
            size: 14,
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

/// 虚线绘制器
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
