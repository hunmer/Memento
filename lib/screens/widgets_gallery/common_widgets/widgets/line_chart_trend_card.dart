import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 折线图趋势小组件
class LineChartTrendCardWidget extends StatefulWidget {
  /// 数值
  final double value;

  /// 标签
  final String label;

  /// 变化百分比（正数上升，负数下降）
  final double changePercent;

  /// 数据点（0-100之间，表示图表高度百分比）
  final List<double> dataPoints;

  /// 单位前缀
  final String unit;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const LineChartTrendCardWidget({
    super.key,
    required this.value,
    required this.label,
    required this.changePercent,
    required this.dataPoints,
    this.unit = '',
    this.inline = false,
  });

  /// 从 props 创建实例
  factory LineChartTrendCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return LineChartTrendCardWidget(
      value: (props['value'] as num?)?.toDouble() ?? 0.0,
      label: props['label'] as String? ?? '',
      changePercent: (props['changePercent'] as num?)?.toDouble() ?? 0.0,
      dataPoints: (props['dataPoints'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      unit: props['unit'] as String? ?? '',
      inline: props['inline'] as bool? ?? false,
    );
  }

  @override
  State<LineChartTrendCardWidget> createState() =>
      _LineChartTrendCardWidgetState();
}

class _LineChartTrendCardWidgetState extends State<LineChartTrendCardWidget>
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
    final primaryColor = isDark ? const Color(0xFFFB7185) : const Color(0xFFF43F5E);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryTextColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final gridColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final axisColor = isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 数值和标签区域
                  _buildHeader(
                    textColor,
                    secondaryTextColor,
                    primaryColor,
                    axisColor,
                  ),
                  const SizedBox(height: 32),
                  // 折线图区域
                  _buildChart(primaryColor, gridColor, axisColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      Color textColor, Color secondaryTextColor, Color primaryColor, Color axisColor) {
    final isPositive = widget.changePercent >= 0;
    final changeColor = isPositive ? const Color(0xFF10B981) : primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主数值
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.unit.isNotEmpty)
              Text(
                widget.unit,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.2,
                ),
              ),
            AnimatedFlipCounter(
              value: widget.value * _animation.value,
              fractionDigits: 0,
              textStyle: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 标签和变化率
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
                letterSpacing: 1.5,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isPositive) ...[
                  const Text(
                    '▼',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF43F5E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                Text(
                  '${isPositive ? '+' : ''}${widget.changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(Color primaryColor, Color gridColor, Color axisColor) {
    return SizedBox(
      height: 128,
      child: CustomPaint(
        size: const Size(double.infinity, 128),
        painter: _LineChartPainter(
          dataPoints: widget.dataPoints,
          progress: _animation.value,
          lineColor: primaryColor,
          gridColor: gridColor,
          axisColor: axisColor,
        ),
      ),
    );
  }
}

/// 折线图绘制器
class _LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final double progress;
  final Color lineColor;
  final Color gridColor;
  final Color axisColor;

  _LineChartPainter({
    required this.dataPoints,
    required this.progress,
    required this.lineColor,
    required this.gridColor,
    required this.axisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 绘制Y轴线
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, 0),
      Offset(0, height),
      axisPaint,
    );

    // 绘制水平网格线
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.5;

    const gridLines = 4;
    for (int i = 1; i <= gridLines; i++) {
      final y = (height / gridLines) * i;
      canvas.drawLine(
        Offset(8, y),
        Offset(width, y),
        gridPaint,
      );
    }

    if (dataPoints.length < 2) return;

    // 计算点的位置
    final points = <Offset>[];
    final stepX = width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final normalizedY = 100 - dataPoints[i]; // 反转Y轴
      final y = (normalizedY / 100) * height;
      points.add(Offset(x, y));
    }

    // 绘制填充区域（渐变）
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, points.first.dy);

    // 只绘制到进度位置
    final maxIndex = ((points.length - 1) * progress).floor();
    final partialProgress = ((points.length - 1) * progress) - maxIndex;

    for (int i = 1; i <= maxIndex; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    if (maxIndex < points.length - 1) {
      final nextPoint = points[maxIndex + 1];
      final currentPoint = points[maxIndex];
      final partialX =
          currentPoint.dx + (nextPoint.dx - currentPoint.dx) * partialProgress;
      final partialY =
          currentPoint.dy + (nextPoint.dy - currentPoint.dy) * partialProgress;
      fillPath.lineTo(partialX, partialY);
    }

    fillPath.lineTo(points[maxIndex.clamp(0, points.length - 1)].dx, height);
    fillPath.lineTo(points.first.dx, height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColor.withOpacity(0.25 * progress),
        lineColor.withOpacity(0),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(fillPath.getBounds());
    canvas.drawPath(fillPath, fillPaint);

    // 绘制折线
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i <= maxIndex; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    if (maxIndex < points.length - 1) {
      final nextPoint = points[maxIndex + 1];
      final currentPoint = points[maxIndex];
      final partialX =
          currentPoint.dx + (nextPoint.dx - currentPoint.dx) * partialProgress;
      final partialY =
          currentPoint.dy + (nextPoint.dy - currentPoint.dy) * partialProgress;
      linePath.lineTo(partialX, partialY);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
