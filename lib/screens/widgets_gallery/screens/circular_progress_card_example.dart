import 'dart:math' as math;
import 'package:animated_flip_counter/animated_flip_counter.dart';
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
class CircularProgressCardWidget extends StatefulWidget {
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
  State<CircularProgressCardWidget> createState() => _CircularProgressCardWidgetState();
}

class _CircularProgressCardWidgetState extends State<CircularProgressCardWidget>
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

    // 使用主题颜色适配
    final backgroundColor = isDark
        ? const Color(0xFF151516)
        : Theme.of(context).colorScheme.surface;
    final effectiveProgressColor = widget.progressColor ??
        (isDark
            ? const Color(0xFFFDE047)
            : Theme.of(context).colorScheme.primary);
    final textColor = isDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    final subtitleColor = isDark
        ? Colors.grey.shade400
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final trackColor = isDark
        ? const Color(0xFF374151)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
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
                  _buildCircularProgress(effectiveProgressColor, trackColor),

                  // 标题和副标题
                  _buildTitleAndSubtitle(textColor, subtitleColor),

                  // 百分比数值
                  _buildPercentage(textColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularProgress(Color progressColor, Color trackColor) {
    final progressAnimation = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 64,
        height: 64,
        child: AnimatedBuilder(
          animation: progressAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _CircularProgressPainter(
                progress: widget.progress * progressAnimation.value,
                progressColor: progressColor,
                trackColor: trackColor,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTitleAndSubtitle(Color textColor, Color subtitleColor) {
    final textAnimation = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: textAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: textAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - textAnimation.value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
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
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPercentage(Color textColor) {
    final percentAnimation = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: percentAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: percentAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - percentAnimation.value)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedFlipCounter(
                  value: widget.percentage * percentAnimation.value,
                  fractionDigits: 2,
                  suffix: '%',
                  textStyle: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
