import 'package:flutter/material.dart';

/// 运输追踪路线卡片示例
class RouteTrackingCardExample extends StatelessWidget {
  const RouteTrackingCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('运输追踪路线卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: RouteTrackingCardWidget(
            date: 'Wed, 8 Aug',
            origin: RoutePoint(
              city: 'Stuttgart',
              date: 'Mon, 8 Aug',
              isCompleted: true,
            ),
            destination: RoutePoint(
              city: 'Dubai',
              date: 'Tue, 9 Aug',
              isCompleted: true,
            ),
            status: 'Shipped',
          ),
        ),
      ),
    );
  }
}

/// 路线点数据模型
class RoutePoint {
  final String city;
  final String date;
  final bool isCompleted;

  const RoutePoint({
    required this.city,
    required this.date,
    required this.isCompleted,
  });
}

/// 运输追踪路线小组件
class RouteTrackingCardWidget extends StatefulWidget {
  final String date;
  final RoutePoint origin;
  final RoutePoint destination;
  final String status;

  const RouteTrackingCardWidget({
    super.key,
    required this.date,
    required this.origin,
    required this.destination,
    required this.status,
  });

  @override
  State<RouteTrackingCardWidget> createState() => _RouteTrackingCardWidgetState();
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
    _animationController.forward();
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
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
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
                                true,
                              ),
                              _buildStatus(isDark),
                              _buildPoint(
                                widget.destination.city,
                                widget.destination.date,
                                isDark,
                                true,
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
          ),
        );
      },
    );
  }

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
