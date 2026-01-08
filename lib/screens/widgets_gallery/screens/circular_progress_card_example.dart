import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 圆形进度卡片示例
class CircularProgressCardExample extends StatelessWidget {
  const CircularProgressCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('圆形进度卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: CircularProgressCardWidget(
            title: '2020 Progress',
            subtitle: '157d/366d • Passed',
            percentage: 71.23,
            progress: 0.71,
          ),
        ),
      ),
    );
  }
}

/// 圆形进度小组件
class CircularProgressCardWidget extends StatelessWidget {
  /// 标题
  final String title;

  /// 副标题（显示天数等信息）
  final String subtitle;

  /// 百分比数值（0-100）
  final double percentage;

  /// 进度值（0.0-1.0）
  final double progress;

  /// 进度颜色
  final Color? progressColor;

  const CircularProgressCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.percentage,
    required this.progress,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 颜色定义
    const backgroundColorLight = Color(0xFFFFFFFF);
    const backgroundColorDark = Color(0xFF151516);
    const primaryColor = Color(0xFFFDE047);
    final textColor = isDark ? Colors.white : Colors.grey.shade900;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final percentColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
    final trackColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    final backgroundColor = isDark ? backgroundColorDark : backgroundColorLight;
    final effectiveProgressColor = progressColor ?? primaryColor;

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(40),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 圆形进度环
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(
                painter: _CircularProgressPainter(
                  progress: progress,
                  progressColor: effectiveProgressColor,
                  trackColor: trackColor,
                ),
              ),
            ),
          ),

          // 标题和副标题
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
            ],
          ),

          // 百分比数值
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                percentage.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: percentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 圆形进度条绘制器
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2; // 减去描边宽度

    // 背景轨道
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 进度条
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // 从顶部开始
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
