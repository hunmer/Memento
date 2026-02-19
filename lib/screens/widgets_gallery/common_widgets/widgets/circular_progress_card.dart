import 'dart:math' as math;
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const CircularProgressCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.percentage,
    required this.progress,
    this.progressColor,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory CircularProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CircularProgressCardWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      percentage: (props['percentage'] as num?)?.toDouble() ?? 0.0,
      progress: (props['progress'] as num?)?.toDouble() ?? 0.0,
      progressColor:
          props['progressColor'] != null
              ? Color(props['progressColor'] as int)
              : null,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<CircularProgressCardWidget> createState() =>
      _CircularProgressCardWidgetState();
}

class _CircularProgressCardWidgetState extends State<CircularProgressCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    final backgroundColor =
        isDark
            ? const Color(0xFF151516)
            : Theme.of(context).colorScheme.surface;
    final effectiveProgressColor =
        widget.progressColor ??
        (isDark
            ? const Color(0xFFFDE047)
            : Theme.of(context).colorScheme.primary);
    final textColor =
        isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final subtitleColor =
        isDark
            ? Colors.grey.shade400
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final trackColor =
        isDark
            ? const Color(0xFF374151)
            : Theme.of(context).colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.inline ? double.maxFinite : 150,
            height: widget.inline ? double.maxFinite : 150,
            padding: widget.size.getPadding(),
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
                // 圆形进度环
                _buildCircularProgress(effectiveProgressColor, trackColor),

                SizedBox(height: widget.size.getTitleSpacing()),

                // 标题和副标题
                _buildTitleAndSubtitle(textColor, subtitleColor),

                // 百分比数值
                _buildPercentage(textColor),
              ],
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

    final iconSize = widget.size.getIconSize() * 2.5;
    final strokeWidth = widget.size.getStrokeWidth();

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: iconSize,
        height: iconSize,
        child: AnimatedBuilder(
          animation: progressAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _CircularProgressPainter(
                progress: widget.progress * progressAnimation.value,
                progressColor: progressColor,
                trackColor: trackColor,
                strokeWidth: strokeWidth,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: widget.size.getTitleFontSize(),
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subtitle.isNotEmpty) ...[
                SizedBox(height: widget.size.getItemSpacing()),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: widget.size.getLegendFontSize(),
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
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
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedFlipCounter(
              value: widget.percentage * percentAnimation.value,
              fractionDigits: 1,
              suffix: '%',
              textStyle: TextStyle(
                fontSize: widget.size.getLargeFontSize() * 0.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
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
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 背景轨道
    final trackPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 进度条
    final progressPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
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
