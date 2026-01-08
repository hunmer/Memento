import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 堆叠环形图统计卡片示例
class StackedRingChartExample extends StatelessWidget {
  const StackedRingChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('堆叠环形图统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFE0E5EC),
        child: const Center(
          child: StackedRingChartWidget(
            segments: [
              RingSegmentData(label: 'Documents', value: 30, color: Color(0xFF0B1556)),
              RingSegmentData(label: 'Videos', value: 155, color: Color(0xFF00A9CE)),
              RingSegmentData(label: 'Photos', value: 80, color: Color(0xFF00649F)),
              RingSegmentData(label: 'Music', value: 193.5, color: Color(0xFF8AD6E9)),
            ],
            total: 251.2,
            title: 'Storage of your device',
            usedValue: 137,
            unit: 'GB',
          ),
        ),
      ),
    );
  }
}

/// 环形数据模型
class RingSegmentData {
  final String label;
  final double value;
  final Color color;

  const RingSegmentData({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// 堆叠环形图统计小组件
class StackedRingChartWidget extends StatefulWidget {
  final List<RingSegmentData> segments;
  final double total;
  final String title;
  final double usedValue;
  final String unit;

  const StackedRingChartWidget({
    super.key,
    required this.segments,
    required this.total,
    required this.title,
    required this.usedValue,
    this.unit = '',
  });

  @override
  State<StackedRingChartWidget> createState() => _StackedRingChartWidgetState();
}

class _StackedRingChartWidgetState extends State<StackedRingChartWidget>
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
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconColor = isDark ? Colors.white : Colors.black;
    final buttonBgColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    // 计算使用率百分比
    final percentage = (widget.segments.fold<double>(0, (sum, s) => sum + s.value) / widget.total * 100).round();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 环形图和图例
                  Row(
                    children: [
                      // 环形图
                      SizedBox(
                        width: 144,
                        height: 144,
                        child: CustomPaint(
                          painter: _RingChartPainter(
                            segments: widget.segments,
                            total: widget.total,
                            progress: _animation.value,
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          ),
                          child: Center(
                            child: Text(
                              '${percentage * _animation.value.toInt()}%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 图例
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.segments.asMap().entries.map((entry) {
                            final index = entry.key;
                            final segment = entry.value;
                            final itemAnimation = CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                index * 0.12,
                                0.5 + index * 0.12,
                                curve: Curves.easeOutCubic,
                              ),
                            );
                            return _LegendItem(
                              label: segment.label,
                              color: segment.color,
                              animation: itemAnimation,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 标题
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 底部信息
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Used storage',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // 堆叠圆点
                                Stack(
                                  children: widget.segments.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final segment = entry.value;
                                    return Transform.translate(
                                      offset: Offset(-index * 8.0, 0),
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: segment.color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: backgroundColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(width: 12),
                                // 使用量数字
                                AnimatedFlipCounter(
                                  value: widget.usedValue * _animation.value,
                                  fractionDigits: 0,
                                  textStyle: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  widget.unit,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 设置按钮
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: buttonBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings,
                          color: iconColor,
                          size: 24,
                        ),
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

/// 图例项
class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final Animation<double> animation;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - animation.value)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade200
                          : Colors.grey.shade800,
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
}

/// 环形图绘制器
class _RingChartPainter extends CustomPainter {
  final List<RingSegmentData> segments;
  final double total;
  final double progress;
  final Color backgroundColor;

  _RingChartPainter({
    required this.segments,
    required this.total,
    required this.progress,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12; // 减去边框宽度
    const strokeWidth = 12.0;

    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, backgroundPaint);

    // 计算起始角度（135度转换为弧度）
    const startAngle = 135 * 3.14159 / 180;
    double currentAngle = startAngle;

    // 绘制每个扇段
    for (final segment in segments) {
      final sweepAngle = (segment.value / total * 360) * 3.14159 / 180 * progress;
      final adjustedSweepAngle = sweepAngle > 6.28 ? 6.28 : sweepAngle; // 限制最大为2π

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        adjustedSweepAngle,
        false,
        paint,
      );

      currentAngle += adjustedSweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _RingChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
