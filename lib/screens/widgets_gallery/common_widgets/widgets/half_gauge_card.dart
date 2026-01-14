import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 半圆仪表盘小组件
class HalfGaugeCardWidget extends StatefulWidget {
  final String title;
  final double totalBudget;
  final double remaining;
  final String currency;

  const HalfGaugeCardWidget({
    super.key,
    this.title = 'Shopping',
    required this.totalBudget,
    required this.remaining,
    this.currency = 'AED',
  });

  /// 从 props 创建实例
  factory HalfGaugeCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return HalfGaugeCardWidget(
      title: props['title'] as String? ?? 'Shopping',
      totalBudget: (props['totalBudget'] as num?)?.toDouble() ?? 0.0,
      remaining: (props['remaining'] as num?)?.toDouble() ?? 0.0,
      currency: props['currency'] as String? ?? 'AED',
    );
  }

  @override
  State<HalfGaugeCardWidget> createState() => _HalfGaugeCardWidgetState();
}

class _HalfGaugeCardWidgetState extends State<HalfGaugeCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  double get progress =>
      (widget.totalBudget - widget.remaining) / widget.totalBudget;
  double get percentage => progress * 100;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
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
  void didUpdateWidget(HalfGaugeCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalBudget != widget.totalBudget ||
        oldWidget.remaining != widget.remaining) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final gaugeBackgroundColor =
        isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final primaryColor = const Color(0xFF7C5CFF);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),

          // 中间仪表盘区域
          SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 半圆形仪表盘
                  SizedBox(
                    width: 160,
                    height: 80,
                    child: Stack(
                      children: [
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(160, 80),
                              painter: _GaugePainter(
                                progress: progress * _progressAnimation.value,
                                backgroundColor: gaugeBackgroundColor,
                                progressColor: primaryColor,
                                isDark: isDark,
                              ),
                            );
                          },
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 4,
                          child: Column(
                            children: [
                              Text(
                                'REMAIN',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.5,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text('🛍️', style: TextStyle(fontSize: 20)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 刻度标记
                  SizedBox(
                    width: 160,
                    height: 16,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Text(
                            '0%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              '50%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Text(
                            '100%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部金额显示
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${widget.currency} ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
                Text(
                  _formatAmount(widget.remaining),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
                Text(
                  '.${_getDecimalPart(widget.remaining)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    return parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _getDecimalPart(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    return parts[1];
  }
}

/// 仪表盘绘制器
class _GaugePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final bool isDark;

  _GaugePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;
    const strokeWidth = 20.0;

    final angleAdjustment = math.asin(strokeWidth / (2 * radius));

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi + angleAdjustment,
      math.pi - 2 * angleAdjustment,
      false,
      backgroundPaint,
    );

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final maxSweepAngle = math.pi - 2 * angleAdjustment;
      final sweepAngle = maxSweepAngle * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi + angleAdjustment,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    final adjustedProgress = progress.clamp(0.0, 1.0);
    final pointerAngle = math.pi +
        angleAdjustment +
        ((math.pi - 2 * angleAdjustment) * adjustedProgress);

    final pointerPaint = Paint()
      ..color = isDark ? Colors.white : Colors.grey.shade800
      ..style = PaintingStyle.fill;

    final pointerSize = 5.0;

    canvas.save();

    final pointerRadius = radius - pointerSize - strokeWidth / 2;
    final pointerX = center.dx + math.cos(pointerAngle) * pointerRadius;
    final pointerY = center.dy + math.sin(pointerAngle) * pointerRadius;
    canvas.translate(pointerX, pointerY);

    final angleInDegrees = (pointerAngle * 180 / math.pi) + 90;
    canvas.rotate(angleInDegrees * math.pi / 180);

    final pointerPath = Path();
    pointerPath.moveTo(0, -pointerSize);
    pointerPath.lineTo(-pointerSize, pointerSize);
    pointerPath.lineTo(pointerSize, pointerSize);
    pointerPath.close();

    canvas.drawPath(pointerPath, pointerPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.isDark != isDark;
  }
}
