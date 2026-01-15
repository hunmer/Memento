import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 支出趋势折线图小组件
///
/// 用于显示支出趋势对比的卡片组件，支持：
/// - 当前月与上月对比
/// - 预算线显示
/// - 平滑曲线动画
/// - 渐变填充效果
/// - 深色/浅色主题适配
class SpendingTrendChartWidget extends StatefulWidget {
  /// 日期范围文本
  final String dateRange;

  /// 标题
  final String title;

  /// 当前月标签
  final String currentMonthLabel;

  /// 上月标签
  final String previousMonthLabel;

  /// 预算金额
  final double budgetAmount;

  /// 预算标签
  final String budgetLabel;

  /// X轴开始标签
  final String startLabel;

  /// X轴中间标签
  final String middleLabel;

  /// X轴结束标签
  final String endLabel;

  /// 当前月数据点
  final List<double> currentMonthData;

  /// 上月数据点
  final List<double> previousMonthData;

  /// 当前点值
  final double currentPoint;

  /// 最大金额（用于Y轴缩放）
  final double maxAmount;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const SpendingTrendChartWidget({
    super.key,
    required this.dateRange,
    required this.title,
    required this.currentMonthLabel,
    required this.previousMonthLabel,
    required this.budgetAmount,
    required this.budgetLabel,
    required this.startLabel,
    required this.middleLabel,
    required this.endLabel,
    required this.currentMonthData,
    required this.previousMonthData,
    required this.currentPoint,
    required this.maxAmount,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于小组件系统）
  factory SpendingTrendChartWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return SpendingTrendChartWidget(
      dateRange: props['dateRange'] as String? ?? '1-31 October 2025',
      title: props['title'] as String? ?? 'Spending trends',
      currentMonthLabel: props['currentMonthLabel'] as String? ?? 'Oct 2025',
      previousMonthLabel: props['previousMonthLabel'] as String? ?? 'Sep 2025',
      budgetAmount: (props['budgetAmount'] as num?)?.toDouble() ?? 3200,
      budgetLabel: props['budgetLabel'] as String? ?? 'Budget',
      startLabel: props['startLabel'] as String? ?? 'Oct 1',
      middleLabel: props['middleLabel'] as String? ?? 'Today',
      endLabel: props['endLabel'] as String? ?? 'Oct 31',
      currentMonthData: (props['currentMonthData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [3200, 2800, 2400, 2000, 1600],
      previousMonthData: (props['previousMonthData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [2800, 2400, 2000, 1600, 1200],
      currentPoint: (props['currentPoint'] as num?)?.toDouble() ?? 1600,
      maxAmount: (props['maxAmount'] as num?)?.toDouble() ?? 4000,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<SpendingTrendChartWidget> createState() =>
      _SpendingTrendChartWidgetState();
}

class _SpendingTrendChartWidgetState extends State<SpendingTrendChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _pointAnimationController;
  late Animation<double> _pointAnimation;

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

    // 当前点放大动画
    _pointAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pointAnimation = CurvedAnimation(
      parent: _pointAnimationController,
      curve: Curves.easeOutBack,
    );

    // 主动画完成后启动点动画
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pointAnimationController.forward();
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pointAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFf06431);
    final headerColor = isDark ? const Color(0xFF2d302e) : const Color(0xFFccd3ce);
    final cardColor = isDark ? const Color(0xFF242624) : Colors.white;
    final textColor = isDark ? const Color(0xFFe3e3e3) : const Color(0xFF1c1c1c);
    final mutedColor = isDark ? const Color(0xFFa0a0a0) : const Color(0xFF717171);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 320,
              height: widget.inline ? double.maxFinite : 320,
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 顶部标题栏
                  Padding(
                    padding: widget.size.getPadding().copyWith(
                      bottom: (widget.size.getPadding().bottom * 0.75).roundToDouble(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.dateRange,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: textColor,
                        ),
                      ],
                    ),
                  ),
                  // 内容区域
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(36),
                          topRight: Radius.circular(36),
                          bottomLeft: Radius.circular(36),
                          bottomRight: Radius.circular(36),
                        ),
                      ),
                      padding: widget.size.getPadding(),
                      child: Column(
                        children: [
                          // 标题和图例
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _LegendItem(
                                    color: primaryColor,
                                    label: widget.currentMonthLabel,
                                    isDashed: false,
                                    size: widget.size,
                                  ),
                                  SizedBox(height: widget.size.getItemSpacing()),
                                  _LegendItem(
                                    color: mutedColor,
                                    label: widget.previousMonthLabel,
                                    isDashed: true,
                                    size: widget.size,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: widget.size.getTitleSpacing()),
                          // 图表区域
                          Expanded(
                            child: _TrendLineChart(
                              currentMonthData: widget.currentMonthData,
                              previousMonthData: widget.previousMonthData,
                              currentPoint: widget.currentPoint,
                              budgetAmount: widget.budgetAmount,
                              maxAmount: widget.maxAmount,
                              primaryColor: primaryColor,
                              mutedColor: mutedColor,
                              animation: _animation,
                              pointAnimation: _pointAnimation,
                              budgetLabel: widget.budgetLabel,
                              textColor: textColor,
                              startLabel: widget.startLabel,
                              middleLabel: widget.middleLabel,
                              endLabel: widget.endLabel,
                              size: widget.size,
                            ),
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

/// 图例项
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;
  final HomeWidgetSize size;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDashed,
    this.size = HomeWidgetSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: isDashed ? Border.all(color: color, width: 1) : null,
          ),
          child: isDashed
              ? CustomPaint(
                  size: const Size(10, 10),
                  painter: _DashedCirclePainter(color: color),
                )
              : null,
        ),
        SizedBox(width: size.getItemSpacing()),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// 虚线圆圈绘制器
class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashCount = 8;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * 2 * math.pi / dashCount);
      final sweepAngle = (math.pi / dashCount) * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 趋势折线图组件
class _TrendLineChart extends StatelessWidget {
  final List<double> currentMonthData;
  final List<double> previousMonthData;
  final double currentPoint;
  final double budgetAmount;
  final double maxAmount;
  final Color primaryColor;
  final Color mutedColor;
  final Animation<double> animation;
  final Animation<double> pointAnimation;
  final String budgetLabel;
  final Color textColor;
  final String startLabel;
  final String middleLabel;
  final String endLabel;
  final HomeWidgetSize size;

  const _TrendLineChart({
    required this.currentMonthData,
    required this.previousMonthData,
    required this.currentPoint,
    required this.budgetAmount,
    required this.maxAmount,
    required this.primaryColor,
    required this.mutedColor,
    required this.animation,
    required this.pointAnimation,
    required this.budgetLabel,
    required this.textColor,
    required this.startLabel,
    required this.middleLabel,
    required this.endLabel,
    this.size = HomeWidgetSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Y轴标签
        Positioned(
          left: 0,
          top: 0,
          bottom: 30,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ['4k', '3k', '2k', '1k'].map((label) {
              return Padding(
                padding: EdgeInsets.only(bottom: size.getItemSpacing() / 2),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: mutedColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 预算线标签
        Positioned(
          left: size.getPadding().left,
          top: 30 * (1 - budgetAmount / maxAmount),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.getItemSpacing(),
                  vertical: size.getItemSpacing() / 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Text(
                  '\$${budgetAmount.toInt()} $budgetLabel',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              SizedBox(width: size.getItemSpacing()),
              Container(
                width: 200,
                height: 1,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ],
          ),
        ),
        // 图表
        Positioned.fill(
          left: size.getPadding().left,
          bottom: 30,
          child: _LineChartPainterWidget(
            currentMonthData: currentMonthData,
            previousMonthData: previousMonthData,
            currentPoint: currentPoint,
            budgetAmount: budgetAmount,
            maxAmount: maxAmount,
            primaryColor: primaryColor,
            mutedColor: mutedColor,
            animation: animation,
            pointAnimation: pointAnimation,
            size: size,
          ),
        ),
        // X轴标签
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.getPadding().left),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(startLabel,
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: mutedColor)),
                Text(middleLabel,
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
                Text(endLabel,
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: mutedColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 折线图绘制组件
class _LineChartPainterWidget extends StatelessWidget {
  final List<double> currentMonthData;
  final List<double> previousMonthData;
  final double currentPoint;
  final double budgetAmount;
  final double maxAmount;
  final Color primaryColor;
  final Color mutedColor;
  final Animation<double> animation;
  final Animation<double> pointAnimation;
  final HomeWidgetSize size;

  const _LineChartPainterWidget({
    required this.currentMonthData,
    required this.previousMonthData,
    required this.currentPoint,
    required this.budgetAmount,
    required this.maxAmount,
    required this.primaryColor,
    required this.mutedColor,
    required this.animation,
    required this.pointAnimation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: pointAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _LineChartPainter(
                currentMonthData: currentMonthData,
                previousMonthData: previousMonthData,
                currentPoint: currentPoint,
                budgetAmount: budgetAmount,
                maxAmount: maxAmount,
                primaryColor: primaryColor,
                mutedColor: mutedColor,
                animation: animation.value,
                pointAnimation: pointAnimation.value,
                size: size,
              ),
            );
          },
        );
      },
    );
  }
}

/// 折线图绘制器
class _LineChartPainter extends CustomPainter {
  final List<double> currentMonthData;
  final List<double> previousMonthData;
  final double currentPoint;
  final double budgetAmount;
  final double maxAmount;
  final Color primaryColor;
  final Color mutedColor;
  final double animation;
  final double pointAnimation;
  final HomeWidgetSize size;

  _LineChartPainter({
    required this.currentMonthData,
    required this.previousMonthData,
    required this.currentPoint,
    required this.budgetAmount,
    required this.maxAmount,
    required this.primaryColor,
    required this.mutedColor,
    required this.animation,
    required this.pointAnimation,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final padding = size.getPadding().left.toDouble();
    final chartWidth = canvasSize.width - padding * 2;
    final chartHeight = canvasSize.height - size.getPadding().bottom;

    // 绘制上个月虚线
    _drawDashedLine(
      canvas,
      previousMonthData,
      chartWidth,
      chartHeight,
      padding,
      mutedColor,
      canvasSize,
    );

    // 绘制当前月份渐变填充
    _drawGradientFill(
      canvas,
      currentMonthData,
      chartWidth,
      chartHeight,
      padding,
      primaryColor,
      canvasSize,
    );

    // 绘制当前月份实线
    _drawSolidLine(
      canvas,
      currentMonthData,
      chartWidth,
      chartHeight,
      padding,
      primaryColor,
      canvasSize,
    );

    // 绘制当前点
    _drawCurrentPoint(
      canvas,
      currentMonthData,
      chartWidth,
      chartHeight,
      padding,
      primaryColor,
      canvasSize,
    );

    // 绘制底线
    final linePaint = Paint()
      ..color = const Color(0xFFe5e7eb)
      ..strokeWidth = 1;

    final isDark = primaryColor == const Color(0xFFf06431);
    if (!isDark) {
      canvas.drawLine(
        Offset(padding, canvasSize.height - 8),
        Offset(canvasSize.width - padding, canvasSize.height - 8),
        linePaint,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    List<double> data,
    double width,
    double height,
    double padding,
    Color color,
    Size canvasSize,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = _createPath(data, width, height, padding, canvasSize);
    final dashPath = _createDashedPath(path);

    canvas.drawPath(dashPath, paint);
  }

  void _drawGradientFill(
    Canvas canvas,
    List<double> data,
    double width,
    double height,
    double padding,
    Color color,
    Size canvasSize,
  ) {
    final path = _createPath(data, width, height, padding, canvasSize);

    // 创建闭合路径用于填充
    final fillPath = Path();
    final pathMetrics = path.computeMetrics();
    final metric = pathMetrics.first;

    final extractPath = metric.extractPath(0, metric.length * animation);
    fillPath.addPath(extractPath, Offset.zero);

    // 添加底部闭合
    final firstPoint = _getPointAtIndex(data, 0, width, height, padding, canvasSize);
    final lastPoint = _getPointAtIndex(
      data,
      (data.length - 1 * animation).floor().clamp(0, data.length - 1),
      width,
      height,
      padding,
      canvasSize,
    );

    fillPath.lineTo(lastPoint.dx, canvasSize.height - 8);
    fillPath.lineTo(firstPoint.dx, canvasSize.height - 8);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.2 * animation),
        color.withOpacity(0),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height));

    canvas.drawPath(fillPath, paint);
  }

  void _drawSolidLine(
    Canvas canvas,
    List<double> data,
    double width,
    double height,
    double padding,
    Color color,
    Size canvasSize,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = _createPath(data, width, height, padding, canvasSize);
    final pathMetrics = path.computeMetrics();
    final metric = pathMetrics.first;

    final extractPath = metric.extractPath(0, metric.length * animation);
    canvas.drawPath(extractPath, paint);
  }

  void _drawCurrentPoint(
    Canvas canvas,
    List<double> data,
    double width,
    double height,
    double padding,
    Color color,
    Size canvasSize,
  ) {
    // 只在主动画接近完成时才开始绘制当前点
    if (animation < 0.9) return;

    final pointIndex = data.length - 1;
    final point = _getPointAtIndex(data, pointIndex, width, height, padding, canvasSize);

    // 计算缩放比例：基于点动画值
    final scale = pointAnimation.clamp(0.0, 1.0);

    // 外圈光晕
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 * scale)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 8 * scale, glowPaint);

    // 内圈实心点
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 5 * scale, dotPaint);
  }

  Path _createPath(List<double> data, double width, double height, double padding, Size canvasSize) {
    final path = Path();
    if (data.isEmpty) return path;

    final firstPoint = _getPointAtIndex(data, 0, width, height, padding, canvasSize);
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < data.length; i++) {
      final point = _getPointAtIndex(data, i, width, height, padding, canvasSize);
      // 使用二次贝塞尔曲线平滑连接
      final previousPoint = _getPointAtIndex(data, i - 1, width, height, padding, canvasSize);
      final controlPoint1 = Offset(
        previousPoint.dx + (point.dx - previousPoint.dx) / 2,
        previousPoint.dy,
      );
      final controlPoint2 = Offset(
        previousPoint.dx + (point.dx - previousPoint.dx) / 2,
        point.dy,
      );
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        point.dx,
        point.dy,
      );
    }

    return path;
  }

  Offset _getPointAtIndex(
    List<double> data,
    int index,
    double width,
    double height,
    double padding,
    Size canvasSize,
  ) {
    if (index >= data.length) index = data.length - 1;
    if (index < 0) index = 0;

    final x = padding + (width / (data.length - 1)) * index;
    final y = (canvasSize.height - 8) - (data[index] / maxAmount) * height;
    return Offset(x, y);
  }

  Path _createDashedPath(Path source) {
    final dashPath = Path();
    const dashWidth = 3.0;
    const dashSpace = 3.0;

    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;

      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }

    return dashPath;
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.pointAnimation != pointAnimation;
  }
}
