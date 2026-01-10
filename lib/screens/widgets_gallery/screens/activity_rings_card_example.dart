import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 活动圆环卡片示例
class ActivityRingsCardExample extends StatelessWidget {
  const ActivityRingsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('活动圆环卡片')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
          ),
        ),
        child: Center(
          child: ActivityRingsCardWidget(
            date: 'Jan 23, 2025',
            steps: 858,
            status: 'Normal',
            rings: [
              RingData(
                value: 70,
                color: const Color(0xFFF97316),
                icon: Icons.print,
              ),
              const RingData(
                value: 20,
                color: Color(0xFF2563EB),
                icon: null,
                isDiamond: true,
              ),
              const RingData(
                value: 40,
                color: Color(0xFF6B7280),
                icon: Icons.directions_run,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 圆环数据模型
class RingData {
  final double value; // 0-100
  final Color color;
  final IconData? icon;
  final bool isDiamond;

  const RingData({
    required this.value,
    required this.color,
    this.icon,
    this.isDiamond = false,
  });
}

/// 活动圆环小组件
class ActivityRingsCardWidget extends StatefulWidget {
  final String date;
  final int steps;
  final String status;
  final List<RingData> rings;

  const ActivityRingsCardWidget({
    super.key,
    required this.date,
    required this.steps,
    required this.status,
    required this.rings,
  });

  @override
  State<ActivityRingsCardWidget> createState() =>
      _ActivityRingsCardWidgetState();
}

class _ActivityRingsCardWidgetState extends State<ActivityRingsCardWidget>
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 日期和导航
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.date,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? const Color(0xFFF3F4F6)
                                  : const Color(0xFF1F2937),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '16 Feb',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color:
                                isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 步数和圆环
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 步数显示
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 54,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AnimatedFlipCounter(
                                  value:
                                      widget.steps.toDouble() *
                                      _animation.value,
                                  textStyle: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    'steps',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isDark
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color:
                                    isDark
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFFF97316),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.status,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
                                          ? const Color(0xFFD1D5DB)
                                          : const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // 圆环
                      Row(
                        children: List.generate(widget.rings.length, (index) {
                          final ringAnimation = CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(
                              index * 0.08,
                              0.5 + index * 0.08,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: _RingWidget(
                              data: widget.rings[index],
                              animation: ringAnimation,
                              isDark: isDark,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 单个圆环组件
class _RingWidget extends StatelessWidget {
  final RingData data;
  final Animation<double> animation;
  final bool isDark;

  const _RingWidget({
    required this.data,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: data.value / 100 * animation.value,
              color: data.color,
              backgroundColor:
                  isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
            ),
            child: Center(child: _buildCenterWidget()),
          );
        },
      ),
    );
  }

  Widget _buildCenterWidget() {
    if (data.isDiamond) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: data.color,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    if (data.icon != null) {
      return Icon(data.icon, size: 18, color: data.color);
    }

    return const SizedBox.shrink();
  }
}

/// 圆环绘制器
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;
    final strokeWidth = 4.0;

    // 背景圆环
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆环
    if (progress > 0) {
      final progressPaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;

      const startAngle = -90.0 * (3.14159 / 180.0); // 从顶部开始
      final sweepAngle = 2 * 3.14159 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
