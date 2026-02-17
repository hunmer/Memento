import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 收益趋势卡片小组件
///
/// 用于显示收益趋势的卡片组件，支持：
/// - 货币数值显示（带动画计数）
/// - 百分比变化徽章
/// - 平滑折线图（带渐变填充）
/// - 深色/浅色主题适配
class EarningsTrendCardWidget extends StatefulWidget {
  /// 标题文本
  final String title;

  /// 主要数值
  final double value;

  /// 货币符号
  final String currency;

  /// 百分比变化
  final double percentage;

  /// 图表数据点（Y坐标值，0-120范围）
  final List<double> chartData;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const EarningsTrendCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.currency,
    required this.percentage,
    required this.chartData,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于小组件系统）
  factory EarningsTrendCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return EarningsTrendCardWidget(
      title: props['title'] as String? ?? 'Earnings',
      value: (props['value'] as num?)?.toDouble() ?? 0.0,
      currency: props['currency'] as String? ?? '\$',
      percentage: (props['percentage'] as num?)?.toDouble() ?? 0.0,
      chartData: (props['chartData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0, 0, 0, 0, 0],
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<EarningsTrendCardWidget> createState() =>
      _EarningsTrendCardWidgetState();
}

class _EarningsTrendCardWidgetState extends State<EarningsTrendCardWidget>
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

    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final valueColor = isDark ? Colors.white : const Color(0xFF1F2937);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 340,
              height: widget.inline ? double.maxFinite : 280,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  // Chart section - 固定在底部作为背景
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: 0.4,
                      child: SizedBox(
                        height: widget.size.getStrokeWidth() * 25,
                        width: double.infinity,
                        child: _LineChart(
                          data: widget.chartData,
                          animation: _animation,
                          isDark: isDark,
                          size: widget.size,
                        ),
                      ),
                    ),
                  ),

                  // Title and value section - 显示在图表上方
                  Padding(
                    padding: EdgeInsets.only(
                      top: widget.size.getTitleSpacing() * 0.6,
                    ),
                    child: Padding(
                      padding: widget.size.getPadding(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: widget.size.getSubtitleFontSize() * 0.9,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: widget.size.getItemSpacing() * 0.75),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedFlipCounter(
                                value: widget.value * _animation.value,
                                fractionDigits: 1,
                                textStyle: TextStyle(
                                  color: valueColor,
                                  fontSize: widget.size.getLargeFontSize() * 0.7,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                widget.currency,
                                style: TextStyle(
                                  color: valueColor,
                                  fontSize: widget.size.getLargeFontSize() * 0.6,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: widget.size.getItemSpacing() * 1.5),
                          _PercentageBadge(
                            percentage: widget.percentage,
                            animation: _animation,
                            size: widget.size,
                          ),
                        ],
                      ),
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

/// 百分比徽章
class _PercentageBadge extends StatelessWidget {
  final double percentage;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _PercentageBadge({
    required this.percentage,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = isDark ? const Color(0xFF0D9488) : const Color(0xFF085F6D);

    final badgeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: badgeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: badgeAnimation.value,
          child: Opacity(
            opacity: badgeAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: size.getItemSpacing() * 1.5,
                vertical: size.getItemSpacing() * 0.75,
              ),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: size.getIconSize() * 0.8,
                  ),
                  SizedBox(width: size.getItemSpacing() * 0.5),
                  Text(
                    '+${percentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.getLegendFontSize() * 0.8,
                      fontWeight: FontWeight.w700,
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

/// 平滑折线图
class _LineChart extends StatelessWidget {
  final List<double> data;
  final Animation<double> animation;
  final bool isDark;
  final HomeWidgetSize size;

  const _LineChart({
    required this.data,
    required this.animation,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final chartAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: chartAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 120),
          painter: _LineChartPainter(
            data: data,
            progress: chartAnimation.value,
            lineColor: const Color(0xFF0284C7),
            gradientStart: const Color(0xFF0284C7).withOpacity(0.1),
            gradientEnd: const Color(0xFF0284C7).withOpacity(0.0),
            strokeWidth: size.getStrokeWidth() * 0.4,
          ),
        );
      },
    );
  }
}

/// 折线图画笔
class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final Color lineColor;
  final Color gradientStart;
  final Color gradientEnd;
  final double strokeWidth;

  _LineChartPainter({
    required this.data,
    required this.progress,
    required this.lineColor,
    required this.gradientStart,
    required this.gradientEnd,
    this.strokeWidth = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 10.0;
    final chartWidth = size.width;
    final chartHeight = size.height - padding * 2;
    final stepX = chartWidth / (data.length - 1);

    // 计算数据点位置
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedY = 1 - (data[i] / 120); // 归一化到 0-1
      final y = normalizedY * chartHeight + padding;
      points.add(Offset(x, y));
    }

    // 创建平滑曲线路径
    final linePath = _createSmoothPath(points, size);

    // 绘制渐变填充
    final fillPath = Path.from(linePath);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [gradientStart, gradientEnd],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(fillPath.getBounds())
      ..style = PaintingStyle.fill;

    // 裁剪渐变填充区域以实现动画
    canvas.clipRect(Rect.fromLTWH(
      0,
      0,
      size.width * progress,
      size.height,
    ));
    canvas.drawPath(fillPath, fillPaint);

    // 绘制线条
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  Path _createSmoothPath(List<Offset> points, Size size) {
    if (points.isEmpty) return Path();

    final path = Path();

    // 添加起始点（从左侧外部开始）
    path.moveTo(-10, points[0].dy);

    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.lineTo(points[i].dx, points[i].dy);
      } else {
        final previousPoint = points[i - 1];
        final currentPoint = points[i];

        // 使用三次贝塞尔曲线创建平滑连接
        final controlPoint1 = Offset(
          previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.5,
          previousPoint.dy,
        );
        final controlPoint2 = Offset(
          previousPoint.dx + (currentPoint.dx - previousPoint.dx) * 0.5,
          currentPoint.dy,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
    }

    // 延伸到右侧外部
    path.lineTo(size.width + 10, points.last.dy);

    return path;
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
