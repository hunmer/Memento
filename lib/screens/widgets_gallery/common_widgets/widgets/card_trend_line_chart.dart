import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 体重趋势图表小组件
///
/// 用于显示带动画的趋势折线图，支持时间范围筛选和交互式工具提示。
/// 适用于体重趋势、温度变化、价格波动等带有时间趋势的数据展示。
///
/// 特性：
/// - 入场动画（渐入+向上位移）
/// - 数值滚动动画
/// - 时间范围筛选标签
/// - 交互式图表工具提示
/// - 深色模式适配
/// - 可配置颜色和尺寸
class CardTrendLineChart extends StatefulWidget {
  /// 卡片标题
  final String? title;

  /// 图标
  final IconData? icon;

  /// 当前数值
  final double currentValue;

  /// 数值单位
  final String valueUnit;

  /// 数据点列表
  final List<TrendDataPoint> dataPoints;

  /// 时间筛选器标签
  final List<String>? timeFilters;

  /// 时间筛选器变更回调
  final ValueChanged<int>? onTimeFilterChanged;

  /// 初始选中的筛选器索引
  final int initialFilterIndex;

  /// 主色调
  final Color? primaryColor;

  /// 是否显示图表背景网格
  final bool showGrid;

  /// 是否显示数据点
  final bool showDots;

  /// 是否显示渐变填充
  final bool showGradient;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const CardTrendLineChart({
    super.key,
    this.title,
    this.icon,
    required this.currentValue,
    required this.valueUnit,
    required this.dataPoints,
    this.timeFilters,
    this.onTimeFilterChanged,
    this.initialFilterIndex = 4,
    this.primaryColor,
    this.showGrid = true,
    this.showDots = true,
    this.showGradient = true,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例
  factory CardTrendLineChart.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return CardTrendLineChart(
      title: props['title'] as String?,
      icon: props['icon'] as IconData?,
      currentValue: (props['currentValue'] as num?)?.toDouble() ?? 0.0,
      valueUnit: props['valueUnit'] as String? ?? '',
      dataPoints:
          (props['dataPoints'] as List?)
              ?.map(
                (e) => TrendDataPoint(
                  label: e['label'] as String,
                  value: (e['value'] as num).toDouble(),
                ),
              )
              .toList() ??
          [],
      timeFilters: props['timeFilters'] as List<String>?,
      initialFilterIndex: props['initialFilterIndex'] as int? ?? 4,
      primaryColor:
          props['primaryColor'] != null
              ? Color(props['primaryColor'] as int)
              : null,
      showGrid: props['showGrid'] as bool? ?? true,
      showDots: props['showDots'] as bool? ?? true,
      showGradient: props['showGradient'] as bool? ?? true,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<CardTrendLineChart> createState() => _CardTrendLineChartState();
}

class _CardTrendLineChartState extends State<CardTrendLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialFilterIndex;
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
    final primaryColor =
        widget.primaryColor ?? Theme.of(context).colorScheme.primary;
    final textColor =
        isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937);
    final mutedColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final backgroundColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 主内容区
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _animation.value)),
                    child: Padding(
                      padding: widget.size.getPadding().copyWith(bottom: 0),
                      child: Column(
                        children: [
                          SizedBox(height: widget.size.getSmallSpacing()),

                          // 数值显示区
                          _buildValueDisplay(
                            isDark,
                            primaryColor,
                            textColor,
                            mutedColor,
                          ),

                          SizedBox(height: widget.size.getSmallSpacing()),

                          // 时间范围筛选标签
                          if (widget.timeFilters != null &&
                              widget.timeFilters!.isNotEmpty)
                            _buildTimeFilterTabs(
                              isDark,
                              primaryColor,
                              textColor,
                              mutedColor,
                            ),

                          if (widget.timeFilters != null &&
                              widget.timeFilters!.isNotEmpty)
                            SizedBox(height: widget.size.getSmallSpacing()),

                          // 图表区域
                          Expanded(
                            child: _buildChart(
                              isDark,
                              primaryColor,
                              mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 数值显示区
  Widget _buildValueDisplay(
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color mutedColor,
  ) {
    // 根据尺寸计算图标容器大小
    final iconContainerSize = widget.size.getIconSize() * 1.6;
    final iconRadius = iconContainerSize * 0.3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 图标
        if (widget.icon != null) ...[
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(iconRadius),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: widget.size.getItemSpacing() * 1.5,
                  offset: Offset(0, widget.size.getItemSpacing() / 2),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: widget.size.getIconSize() * 0.8,
            ),
          ),
          SizedBox(width: widget.size.getSmallSpacing()),
        ],

        // 数值
        SizedBox(
          height: widget.size.getLargeFontSize() * 1.4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: widget.size.getLargeFontSize(),
                child: AnimatedFlipCounter(
                  value: widget.currentValue * _animation.value,
                  fractionDigits: 1,
                  textStyle: TextStyle(
                    fontSize: widget.size.getLargeFontSize() * 0.8,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
              SizedBox(width: widget.size.getSmallSpacing()),
              SizedBox(
                height: widget.size.getSubtitleFontSize(),
                child: Text(
                  widget.valueUnit,
                  style: TextStyle(
                    fontSize: widget.size.getSubtitleFontSize(),
                    fontWeight: FontWeight.w500,
                    color: mutedColor,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 时间范围筛选标签
  Widget _buildTimeFilterTabs(
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      padding: EdgeInsets.all(widget.size.getSmallSpacing()),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(widget.size.getSmallSpacing() * 3),
      ),
      child: Row(
        children: List.generate(widget.timeFilters!.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
                widget.onTimeFilterChanged?.call(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  vertical: widget.size.getSmallSpacing() * 1.5,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? (isDark ? const Color(0xFF4B5563) : Colors.white)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    widget.size.getSmallSpacing() * 2.5,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: widget.size.getSmallSpacing(),
                              offset: Offset(
                                0,
                                widget.size.getSmallSpacing() * 0.5,
                              ),
                            ),
                          ]
                          : null,
                ),
                child: Text(
                  widget.timeFilters![index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: widget.size.getLegendFontSize(),
                    fontWeight: FontWeight.w500,
                    color: isSelected ? textColor : mutedColor,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 图表区域
  Widget _buildChart(bool isDark, Color primaryColor, Color mutedColor) {
    // 计算最小和最大值以设置 Y 轴范围
    final values = widget.dataPoints.map((p) => p.value).toList();
    if (values.isEmpty) {
      return const Expanded(child: Center(child: Text('无数据')));
    }

    final minValue = values.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxValue = values.reduce((a, b) => a > b ? a : b) + 0.5;
    // 基础 X 轴间距根据尺寸调整
    final baseWidth =
        widget.size is WideSize || widget.size is Wide2Size ? 400.0 : 280.0;
    final xInterval =
        baseWidth /
        (widget.dataPoints.length > 1 ? widget.dataPoints.length - 1 : 1);

    return Padding(
      padding: EdgeInsets.only(bottom: widget.size.getItemSpacing()),
      child: CustomPaint(
        size: Size.infinite,
        painter: _TrendLineChartPainter(
          dataPoints: widget.dataPoints,
          animation: _animation,
          primaryColor: primaryColor,
          mutedColor: mutedColor,
          isDark: isDark,
          minValue: minValue,
          maxValue: maxValue,
          xInterval: xInterval,
          showGrid: widget.showGrid,
          showDots: widget.showDots,
          showGradient: widget.showGradient,
          size: widget.size,
        ),
      ),
    );
  }
}

/// 趋势折线图画笔
class _TrendLineChartPainter extends CustomPainter {
  final List<TrendDataPoint> dataPoints;
  final Animation<double> animation;
  final Color primaryColor;
  final Color mutedColor;
  final bool isDark;
  final double minValue;
  final double maxValue;
  final double xInterval;
  final bool showGrid;
  final bool showDots;
  final bool showGradient;
  final HomeWidgetSize size;

  _TrendLineChartPainter({
    required this.dataPoints,
    required this.animation,
    required this.primaryColor,
    required this.mutedColor,
    required this.isDark,
    required this.minValue,
    required this.maxValue,
    required this.xInterval,
    required this.showGrid,
    required this.showDots,
    required this.showGradient,
    required this.size,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (dataPoints.isEmpty) return;

    final padding = size.getPadding().left;
    final chartWidth = canvasSize.width - padding * 2;
    final chartHeight = canvasSize.height - padding * 2;

    // 绘制网格线
    if (showGrid) {
      _drawGrid(canvas, canvasSize, padding);
    }

    // 计算点的位置
    final points = <Offset>[];
    final baseWidth = size is WideSize || size is Wide2Size ? 400.0 : 280.0;
    for (int i = 0; i < dataPoints.length; i++) {
      final x = padding + (i * xInterval / baseWidth) * chartWidth;
      final normalizedValue =
          (dataPoints[i].value - minValue) / (maxValue - minValue);
      final y = padding + chartHeight - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    // 绘制渐变填充
    if (showGradient) {
      _drawGradientFill(canvas, points, canvasSize);
    }

    // 绘制折线
    _drawLine(canvas, points);

    // 绘制数据点
    if (showDots) {
      _drawDots(canvas, points);
    }

    // 绘制X轴标签（小尺寸不显示）
    if (size is! SmallSize) {
      _drawXLabels(canvas, points, canvasSize);
    }
  }

  /// 绘制网格线
  void _drawGrid(Canvas canvas, Size canvasSize, double padding) {
    final gridPaint =
        Paint()
          ..color = mutedColor.withOpacity(0.2)
          ..strokeWidth = size.getStrokeWidth() * 0.1;

    // 水平网格线
    for (int i = 0; i <= 4; i++) {
      final y = padding + (canvasSize.height - padding * 2) * (i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(canvasSize.width - padding, y),
        gridPaint,
      );
    }
  }

  /// 绘制渐变填充
  void _drawGradientFill(Canvas canvas, List<Offset> points, Size size) {
    if (points.isEmpty) return;

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        primaryColor.withOpacity(0.3 * animation.value),
        primaryColor.withOpacity(0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPaint =
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // 使用贝塞尔曲线连接点
    for (int i = 0; i < points.length - 1; i++) {
      final currentPoint = points[i];
      final nextPoint = points[i + 1];
      final controlPoint1 = Offset(
        currentPoint.dx + (nextPoint.dx - currentPoint.dx) / 2,
        currentPoint.dy,
      );
      final controlPoint2 = Offset(
        currentPoint.dx + (nextPoint.dx - currentPoint.dx) / 2,
        nextPoint.dy,
      );
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        nextPoint.dx,
        nextPoint.dy,
      );
    }

    path.lineTo(points.last.dx, size.height);
    path.lineTo(points.first.dx, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);
  }

  /// 绘制折线
  void _drawLine(Canvas canvas, List<Offset> points) {
    if (points.isEmpty) return;

    final linePaint =
        Paint()
          ..color = primaryColor
          ..strokeWidth = size.getStrokeWidth() * 0.3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // 使用贝塞尔曲线连接点
    for (int i = 0; i < points.length - 1; i++) {
      final currentPoint = points[i];
      final nextPoint = points[i + 1];
      final controlPoint1 = Offset(
        currentPoint.dx + (nextPoint.dx - currentPoint.dx) / 2,
        currentPoint.dy,
      );
      final controlPoint2 = Offset(
        currentPoint.dx + (nextPoint.dx - currentPoint.dx) / 2,
        nextPoint.dy,
      );
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        nextPoint.dx,
        nextPoint.dy,
      );
    }

    canvas.drawPath(path, linePaint);
  }

  /// 绘制数据点
  void _drawDots(Canvas canvas, List<Offset> points) {
    final dotRadius = size.getSmallSpacing() * animation.value;
    final dotStrokeWidth = size.getSmallSpacing() * 0.5;

    for (final point in points) {
      // 外圈
      final dotPaint =
          Paint()
            ..color = primaryColor
            ..style = PaintingStyle.fill;
      canvas.drawCircle(point, dotRadius, dotPaint);

      // 内圈
      final innerDotPaint =
          Paint()
            ..color = isDark ? const Color(0xFF111827) : Colors.white
            ..style = PaintingStyle.fill;
      canvas.drawCircle(point, dotRadius - dotStrokeWidth / 2, innerDotPaint);
    }
  }

  /// 绘制X轴标签
  void _drawXLabels(Canvas canvas, List<Offset> points, Size canvasSize) {
    final textStyle = TextStyle(
      color: mutedColor,
      fontSize: size.getLegendFontSize(),
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < dataPoints.length; i++) {
      final point = points[i];
      final textPainter = TextPainter(
        text: TextSpan(text: dataPoints[i].label, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          point.dx - textPainter.width / 2,
          canvasSize.height - size.getPadding().bottom,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLineChartPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value ||
        oldDelegate.dataPoints != dataPoints;
  }
}

/// 趋势数据点模型
///
/// 表示趋势图上的单个数据点。
class TrendDataPoint {
  /// X轴标签
  final String label;

  /// 数值
  final double value;

  const TrendDataPoint({required this.label, required this.value});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendDataPoint &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          value == other.value;

  @override
  int get hashCode => label.hashCode ^ value.hashCode;
}
