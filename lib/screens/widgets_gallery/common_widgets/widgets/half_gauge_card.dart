import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 半圆仪表盘小组件
class HalfGaugeCardWidget extends StatefulWidget {
  final String title;
  final double totalBudget;
  final double remaining;
  final String currency;

  /// 组件尺寸
  final HomeWidgetSize size;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const HalfGaugeCardWidget({
    super.key,
    this.title = 'Shopping',
    required this.totalBudget,
    required this.remaining,
    this.currency = 'AED',
    this.size = HomeWidgetSize.medium,
    this.inline = false,
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
      size: size,
      inline: props['inline'] as bool? ?? false,
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

    // 获取字体大小（使用已有的 size 方法）
    final gaugeTitleFontSize = widget.size.getTitleFontSize();
    final gaugeAmountFontSize = widget.size.getSubtitleFontSize() + 2;
    final gaugeIconSize = widget.size.getIconSize();
    final gaugeLabelFontSize = widget.size.getLegendFontSize();
    final gaugeRemainLabelFontSize = widget.size.getLegendFontSize() - 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用宽度计算仪表盘尺寸（自适应）
        final availableWidth = constraints.maxWidth;
        final gaugeWidth = availableWidth * 0.8; // 仪表盘占可用宽度的 80%
        final gaugeHeight = gaugeWidth * 0.5; // 半圆高度是宽度的一半
        final strokeWidth = gaugeWidth * 0.12; // 描边宽度是宽度的 12%
        final pointerSize = strokeWidth * 0.3; // 指针大小是描边的 30%
        final gaugeSectionHeight = gaugeWidth * 0.7; // 仪表盘区域高度

        return Container(
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
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: gaugeTitleFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),

              // 中间仪表盘区域
              SizedBox(
                height: gaugeSectionHeight,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 半圆形仪表盘
                      SizedBox(
                        width: gaugeWidth,
                        height: gaugeHeight,
                        child: Stack(
                          children: [
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: Size(gaugeWidth, gaugeHeight),
                                  painter: _GaugePainter(
                                    progress:
                                        progress * _progressAnimation.value,
                                    backgroundColor: gaugeBackgroundColor,
                                    progressColor: primaryColor,
                                    isDark: isDark,
                                    strokeWidth: strokeWidth,
                                    pointerSize: pointerSize,
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: gaugeHeight * 0.05,
                              child: Column(
                                children: [
                                  Text(
                                    'REMAIN',
                                    style: TextStyle(
                                      fontSize: gaugeRemainLabelFontSize,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.5,
                                      color:
                                          isDark
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade400,
                                    ),
                                  ),
                                  SizedBox(
                                    height: widget.size.getSmallSpacing() * 2,
                                  ),
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: gaugeIconSize,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 刻度标记
                      SizedBox(
                        width: gaugeWidth,
                        height: gaugeLabelFontSize * 2,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              bottom: 0,
                              child: Text(
                                '0%',
                                style: TextStyle(
                                  fontSize: gaugeLabelFontSize,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
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
                                    fontSize: gaugeLabelFontSize,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark
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
                                  fontSize: gaugeLabelFontSize,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
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
              Center(
                child: Text(
                  '${_formatAmount(widget.remaining)}.${_getDecimalPart(widget.remaining)} / ${_formatAmount(widget.totalBudget)}.${_getDecimalPart(widget.totalBudget)} (${widget.currency})',
                  style: TextStyle(
                    fontSize: gaugeAmountFontSize,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
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
  final double strokeWidth;
  final double pointerSize;

  _GaugePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.isDark,
    this.strokeWidth = 16.0,
    this.pointerSize = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth / 2 - 2;

    final angleAdjustment = math.asin(strokeWidth / (2 * radius));

    final backgroundPaint =
        Paint()
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
      final progressPaint =
          Paint()
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
    final pointerAngle =
        math.pi +
        angleAdjustment +
        ((math.pi - 2 * angleAdjustment) * adjustedProgress);

    final pointerPaint =
        Paint()
          ..color = isDark ? Colors.white : Colors.grey.shade800
          ..style = PaintingStyle.fill;

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
        oldDelegate.isDark != isDark ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.pointerSize != pointerSize;
  }
}
