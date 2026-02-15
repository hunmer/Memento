import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 曲线数据点模型
class CurveDataPoint {
  final double value;
  final String? label;

  const CurveDataPoint({required this.value, this.label});
}

/// 曲线进度卡片小组件
class CurveProgressCardWidget extends StatefulWidget {
  /// 曲线数据点列表
  final List<CurveDataPoint> dataPoints;

  /// 单位
  final String unit;

  /// 图标
  final IconData icon;

  /// 分类标签
  final String categoryLabel;

  /// 更新时间文本
  final String lastUpdated;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const CurveProgressCardWidget({
    super.key,
    required this.dataPoints,
    this.unit = '',
    this.icon = Icons.schedule,
    this.categoryLabel = 'Progress',
    this.lastUpdated = '',
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory CurveProgressCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final List<dynamic> pointsData =
        props['dataPoints'] as List<dynamic>? ?? [];
    final List<CurveDataPoint> dataPoints =
        pointsData.map((pointData) {
          final pointMap = pointData as Map<String, dynamic>;
          return CurveDataPoint(
            value: (pointMap['value'] as num?)?.toDouble() ?? 0.0,
            label: pointMap['label'] as String?,
          );
        }).toList();

    return CurveProgressCardWidget(
      dataPoints: dataPoints,
      unit: props['unit'] as String? ?? '',
      icon:
          props['icon'] != null
              ? IconData(props['icon'] as int, fontFamily: 'MaterialIcons')
              : Icons.schedule,
      categoryLabel: props['categoryLabel'] as String? ?? 'Progress',
      lastUpdated: props['lastUpdated'] as String? ?? '',
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<CurveProgressCardWidget> createState() =>
      _CurveProgressCardWidgetState();
}

class _CurveProgressCardWidgetState extends State<CurveProgressCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
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

    // 颜色定义
    final backgroundColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final secondaryTextColor =
        isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final accentColor = const Color(0xFF4ADE80);

    // 从数据点计算值
    final currentValue =
        widget.dataPoints.isNotEmpty ? widget.dataPoints.last.value : 0.0;
    final previousValue =
        widget.dataPoints.length > 1 ? widget.dataPoints.first.value : 0.0;
    final change = currentValue - previousValue;
    final changePercent =
        previousValue != 0 ? (change / previousValue * 100) : 0.0;
    final changeColor = change >= 0 ? accentColor : Colors.red;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Container(
              width: widget.inline ? double.maxFinite : 360,
              padding: widget.size.getPadding(),
              constraints: widget.size.getHeightConstraints(),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标签行
                  _buildHeaderRow(
                    icon: widget.icon,
                    label: widget.categoryLabel,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  SizedBox(
                    height:
                        widget.size.getTitleSpacing() *
                        (widget.size is SmallSize ? 0.6 : 1.0),
                  ),

                  // 主内容区域：曲线图（居中显示）
                  _buildMainContent(
                    isDark: isDark,
                    accentColor: accentColor,
                    backgroundColor: backgroundColor,
                  ),
                  SizedBox(
                    height:
                        widget.size.getTitleSpacing() *
                        (widget.size is SmallSize ? 0.6 : 1.0),
                  ),

                  // 底部信息行
                  _buildFooterRow(
                    currentValue: currentValue,
                    change: change,
                    changePercent: changePercent,
                    changeColor: changeColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 顶部标签行
  Widget _buildHeaderRow({
    required IconData icon,
    required String label,
    required Color secondaryTextColor,
  }) {
    final iconSize = widget.size.getIconSize() * 0.9;
    return Row(
      children: [
        Icon(icon, size: iconSize, color: secondaryTextColor),
        SizedBox(width: widget.size.getItemSpacing()),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: widget.size.getSubtitleFontSize(),
            fontWeight: FontWeight.bold,
            letterSpacing: 2.4,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  /// 主内容区域：曲线图（居中显示）
  Widget _buildMainContent({
    required bool isDark,
    required Color accentColor,
    required Color backgroundColor,
  }) {
    return Center(
      child: SizedBox(
        width: widget.size.getStrokeWidth() * 18,
        height: widget.size.getStrokeWidth() * 10,
        child: CustomPaint(
          painter: _CurveProgressPainter(
            dataPoints: widget.dataPoints,
            progress: _progressAnimation.value,
            strokeWidth: widget.size.getStrokeWidth() * 0.4,
            progressColor: accentColor,
            backgroundColor: backgroundColor,
          ),
        ),
      ),
    );
  }

  /// 底部信息行
  Widget _buildFooterRow({
    required double currentValue,
    required double change,
    required double changePercent,
    required Color changeColor,
    required Color secondaryTextColor,
  }) {
    final changePrefix = change >= 0 ? '+' : '';
    final changeText = '$changePrefix${changePercent.toStringAsFixed(2)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 数值 + 单位 + 变化量（同一行）
        SizedBox(
          height: widget.size.getLargeFontSize() * 0.35 * 1.1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 数值 + 单位
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: widget.size.getLargeFontSize() * 0.35,
                    child: AnimatedFlipCounter(
                      value: currentValue * _progressAnimation.value,
                      fractionDigits: currentValue % 1 != 0 ? 2 : 0,
                      textStyle: TextStyle(
                        fontSize: widget.size.getLargeFontSize() * 0.35,
                        fontWeight: FontWeight.w800,
                        color: changeColor,
                        height: 1.0,
                      ),
                    ),
                  ),
                  if (widget.unit.isNotEmpty) ...[
                    SizedBox(width: widget.size.getSmallSpacing()),
                    SizedBox(
                      height: widget.size.getSubtitleFontSize(),
                      child: Text(
                        widget.unit,
                        style: TextStyle(
                          fontSize: widget.size.getSubtitleFontSize(),
                          fontWeight: FontWeight.w500,
                          color: changeColor,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // 变化量
              SizedBox(
                height: widget.size.getSubtitleFontSize(),
                child: Text(
                  changeText,
                  style: TextStyle(
                    fontSize: widget.size.getSubtitleFontSize(),
                    fontWeight: FontWeight.bold,
                    color: changeColor,
                    letterSpacing: 0.5,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: widget.size.getSmallSpacing()),
        // 更新时间（单独一行，右边对齐）
        SizedBox(
          height: widget.size.getSubtitleFontSize(),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              widget.lastUpdated,
              style: TextStyle(
                fontSize: widget.size.getSubtitleFontSize(),
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 曲线进度图绘制器
class _CurveProgressPainter extends CustomPainter {
  final List<CurveDataPoint> dataPoints;
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _CurveProgressPainter({
    required this.dataPoints,
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // 计算数据的最大值和最小值
    final values = dataPoints.map((p) => p.value).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue == 0 ? 1.0 : maxValue - minValue;

    // 创建曲线路径
    final path = _createCurvePath(
      size: size,
      dataPoints: dataPoints,
      minValue: minValue,
      valueRange: valueRange,
    );

    // 使用 PathMetrics 实现进度动画
    final pathMetric = path.computeMetrics().first;
    final extractPath = pathMetric.extractPath(
      0.0,
      pathMetric.length * progress,
    );

    final paint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(extractPath, paint);

    // 绘制进度点（动画显示）- 在曲线上的实际位置
    if (progress > 0.1) {
      // 获取当前进度在曲线上的切线信息
      final currentOffset = pathMetric.length * progress;
      final tangent = pathMetric.getTangentForOffset(currentOffset);

      if (tangent != null) {
        final dotPaint =
            Paint()
              ..color = progressColor
              ..style = PaintingStyle.fill;

        final borderPaint =
            Paint()
              ..color = backgroundColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth;

        canvas.drawCircle(tangent.position, strokeWidth * 1.5, dotPaint);
        canvas.drawCircle(tangent.position, strokeWidth * 1.5, borderPaint);
      }
    }
  }

  /// 创建平滑曲线路径
  Path _createCurvePath({
    required Size size,
    required List<CurveDataPoint> dataPoints,
    required double minValue,
    required double valueRange,
  }) {
    final path = Path();

    if (dataPoints.length == 1) {
      // 只有一个点时，绘制一条水平线
      final y =
          size.height -
          ((dataPoints[0].value - minValue) / valueRange) * size.height * 0.8 -
          size.height * 0.1;
      path.moveTo(0, y);
      path.lineTo(size.width, y);
      return path;
    }

    // 计算每个点的位置
    final points = <Offset>[];
    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final normalizedValue = (dataPoints[i].value - minValue) / valueRange;
      final y =
          size.height -
          (normalizedValue * size.height * 0.8 + size.height * 0.1);
      points.add(Offset(x, y));
    }

    // 使用 Catmull-Rom 样条曲线或简单的二次贝塞尔曲线
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      // 只有两个点时，绘制直线
      path.lineTo(points[1].dx, points[1].dy);
    } else {
      // 多个点时，使用平滑曲线
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

        final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _CurveProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.dataPoints != dataPoints;
  }
}
