import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 数据点模型
class DataPoint {
  final double x;
  final double y;

  const DataPoint({
    required this.x,
    required this.y,
  });

  /// 从 JSON 创建
  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}

/// 平滑曲线图表小组件
class SmoothLineChartCardWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String date;
  final List<DataPoint> dataPoints;
  final double maxValue;
  final List<String> timeLabels;
  final Color primaryColor;
  final double totalDistance;
  final String distanceUnit;
  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;
  /// 组件尺寸
  final HomeWidgetSize size;

  const SmoothLineChartCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.dataPoints,
    required this.maxValue,
    required this.timeLabels,
    required this.primaryColor,
    this.totalDistance = 0,
    this.distanceUnit = '',
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory SmoothLineChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final pointsList = (props['dataPoints'] as List<dynamic>?)
            ?.map((e) => DataPoint.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final labelsList = (props['timeLabels'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return SmoothLineChartCardWidget(
      title: props['title'] as String? ?? '',
      subtitle: props['subtitle'] as String? ?? '',
      date: props['date'] as String? ?? '',
      dataPoints: pointsList,
      maxValue: (props['maxValue'] as num?)?.toDouble() ?? 100.0,
      timeLabels: labelsList,
      primaryColor: props.containsKey('primaryColor')
          ? Color(props['primaryColor'] as int)
          : const Color(0xFFFF7F56),
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<SmoothLineChartCardWidget> createState() =>
      _SmoothLineChartCardWidgetState();
}

class _SmoothLineChartCardWidgetState extends State<SmoothLineChartCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _selectedPeriod = 0; // 0: Day, 1: Week, 2: Month

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
              width: widget.inline ? double.maxFinite : 340,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: widget.size.getPadding(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDark),
                        SizedBox(height: widget.size.getTitleSpacing()),
                        _buildPeriodToggle(isDark),
                        SizedBox(height: widget.size.getTitleSpacing()),
                        _buildChart(isDark),
                        SizedBox(height: widget.size.getItemSpacing()),
                        _buildTimeLabels(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题区域
  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey.shade900,
                height: 1.0,
              ),
            ),
            SizedBox(width: widget.size.getItemSpacing()),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white : Colors.grey.shade900,
                height: 1.0,
              ),
            ),
          ],
        ),
        SizedBox(height: widget.size.getItemSpacing()),
        Text(
          widget.date,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  /// 构建时间段切换按钮
  Widget _buildPeriodToggle(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.all(widget.size.getSmallSpacing()),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPeriodButton('Day', 0, isDark),
              _buildPeriodButton('Week', 1, isDark),
              _buildPeriodButton('Month', 2, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String label, int index, bool isDark) {
    final isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? widget.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade400),
            height: 1.0,
          ),
        ),
      ),
    );
  }

  /// 构建图表区域
  Widget _buildChart(bool isDark) {
    return SizedBox(
      height: 192,
      child: _SmoothLineChart(
        dataPoints: widget.dataPoints,
        maxValue: widget.maxValue,
        primaryColor: widget.primaryColor,
        animation: _animation,
        isDark: isDark,
      ),
    );
  }

  /// 构建时间标签
  Widget _buildTimeLabels(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.timeLabels.length, (index) {
          final alignment = index == 0
              ? CrossAxisAlignment.start
              : index == widget.timeLabels.length - 1
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.center;
          return SizedBox(
            width: 32,
            child: Text(
              widget.timeLabels[index],
              textAlign: alignment == CrossAxisAlignment.center
                  ? TextAlign.center
                  : alignment == CrossAxisAlignment.start
                      ? TextAlign.left
                      : TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                height: 1.0,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 平滑曲线图表绘制组件
class _SmoothLineChart extends StatelessWidget {
  final List<DataPoint> dataPoints;
  final double maxValue;
  final Color primaryColor;
  final Animation<double> animation;
  final bool isDark;

  const _SmoothLineChart({
    required this.dataPoints,
    required this.maxValue,
    required this.primaryColor,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 192),
      painter: _SmoothLineChartPainter(
        dataPoints: dataPoints,
        maxValue: maxValue,
        primaryColor: primaryColor,
        progress: animation.value,
        isDark: isDark,
      ),
    );
  }
}

/// 平滑曲线图表画笔
class _SmoothLineChartPainter extends CustomPainter {
  final List<DataPoint> dataPoints;
  final double maxValue;
  final Color primaryColor;
  final double progress;
  final bool isDark;

  _SmoothLineChartPainter({
    required this.dataPoints,
    required this.maxValue,
    required this.primaryColor,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    // 绘制垂直网格线
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final gridSpacing = size.width / (dataPoints.length - 1);
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * gridSpacing;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // 计算缩放后的点
    final scaledPoints = dataPoints.map((point) {
      return Offset(
        point.x / dataPoints.last.x * size.width,
        size.height - (point.y / maxValue * size.height * progress),
      );
    }).toList();

    if (scaledPoints.isEmpty) return;

    // 绘制渐变填充
    final fillPath = Path();
    fillPath.moveTo(scaledPoints.first.dx, size.height);

    // 使用 Catmull-Rom 样条曲线绘制平滑曲线
    for (int i = 0; i < scaledPoints.length - 1; i++) {
      final p0 = scaledPoints[i > 0 ? i - 1 : i];
      final p1 = scaledPoints[i];
      final p2 = scaledPoints[i + 1];
      final p3 = scaledPoints[(i + 2) < scaledPoints.length ? i + 2 : i + 1];

      final segments = 20;
      for (int j = 0; j < segments; j++) {
        final t = j / segments;
        final point = _catmullRomSpline(p0, p1, p2, p3, t);
        if (i == 0 && j == 0) {
          fillPath.lineTo(point.dx, point.dy);
        } else {
          fillPath.lineTo(point.dx, point.dy);
        }
      }
    }

    fillPath.lineTo(scaledPoints.last.dx, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withOpacity(0.2 * progress),
        primaryColor.withOpacity(0.0),
      ],
    );
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // 绘制曲线
    final linePath = Path();
    linePath.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);

    for (int i = 0; i < scaledPoints.length - 1; i++) {
      final p0 = scaledPoints[i > 0 ? i - 1 : i];
      final p1 = scaledPoints[i];
      final p2 = scaledPoints[i + 1];
      final p3 = scaledPoints[(i + 2) < scaledPoints.length ? i + 2 : i + 1];

      final segments = 20;
      for (int j = 0; j < segments; j++) {
        final t = j / segments;
        final point = _catmullRomSpline(p0, p1, p2, p3, t);
        linePath.lineTo(point.dx, point.dy);
      }
    }

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // 绘制末端圆点
    final endPoint = scaledPoints.last;
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, 3, dotPaint);

    final dotBorderPaint = Paint()
      ..color = isDark ? const Color(0xFF1F2937) : Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(endPoint, 3, dotBorderPaint);
  }

  /// Catmull-Rom 样条曲线插值
  Offset _catmullRomSpline(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;

    final x = 0.5 * (
      (2 * p1.dx) +
      (-p0.dx + p2.dx) * t +
      (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
      (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3
    );

    final y = 0.5 * (
      (2 * p1.dy) +
      (-p0.dy + p2.dy) * t +
      (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
      (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3
    );

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _SmoothLineChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isDark != isDark;
  }
}
