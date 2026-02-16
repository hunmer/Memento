import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 收入趋势小组件
class RevenueTrendCardWidget extends StatefulWidget {
  /// 主要数值
  final double value;

  /// 货币符号
  final String currency;

  /// 百分比变化
  final int percentage;

  /// 时间周期文本
  final String period;

  /// 图表数据点（Y坐标值，0-120范围）
  final List<double> chartData;

  /// 日期标签
  final List<int> dates;

  /// 高亮点的索引
  final int highlightIndex;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const RevenueTrendCardWidget({
    super.key,
    required this.value,
    required this.currency,
    required this.percentage,
    required this.period,
    required this.chartData,
    required this.dates,
    required this.highlightIndex,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory RevenueTrendCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return RevenueTrendCardWidget(
      value: (props['value'] as num?)?.toDouble() ?? 0.0,
      currency: props['currency'] as String? ?? '\$',
      percentage: props['percentage'] as int? ?? 0,
      period: props['period'] as String? ?? 'Weekly',
      chartData:
          (props['chartData'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0, 0, 0, 0, 0],
      dates:
          (props['dates'] as List<dynamic>?)?.map((e) => e as int).toList() ??
          [1, 2, 3, 4, 5],
      highlightIndex: props['highlightIndex'] as int? ?? 0,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<RevenueTrendCardWidget> createState() => _RevenueTrendCardWidgetState();
}

class _RevenueTrendCardWidgetState extends State<RevenueTrendCardWidget>
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

    final backgroundColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final subTextColor = const Color(0xFF9CA3AF);
    final primaryColor = const Color(0xFF6B4EFF);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 340,
              height: widget.inline ? double.maxFinite : 400,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: widget.size.getPadding(),
                child: Column(
                  children: [
                    // 时间筛选按钮
                    _PeriodSelector(
                      period: widget.period,
                      animation: _animation,
                      size: widget.size,
                    ),

                    // 金额和百分比
                    _ValueSection(
                      currency: widget.currency,
                      value: widget.value,
                      percentage: widget.percentage,
                      animation: _animation,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      size: widget.size,
                    ),

                    // 曲线图和日期标签（支持横向滚动）
                    _ScrollableChartSection(
                      chartData: widget.chartData,
                      dates: widget.dates,
                      highlightIndex: widget.highlightIndex,
                      primaryColor: primaryColor,
                      textColor: textColor,
                      animation: _animation,
                      size: widget.size,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 时间周期选择器
class _PeriodSelector extends StatelessWidget {
  final String period;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _PeriodSelector({
    required this.period,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFF9CA3AF);

    final selectorAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: selectorAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: selectorAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - selectorAnimation.value)),
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.getItemSpacing(),
                    vertical: size.getItemSpacing() / 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        period,
                        style: TextStyle(
                          color: textColor,
                          fontSize: size.getSubtitleFontSize(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: size.getItemSpacing() / 2),
                      Icon(
                        Icons.expand_more,
                        color: textColor,
                        size: size.getIconSize() * 0.7,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 数值显示区域
class _ValueSection extends StatelessWidget {
  final String currency;
  final double value;
  final int percentage;
  final Animation<double> animation;
  final Color textColor;
  final Color subTextColor;
  final HomeWidgetSize size;

  const _ValueSection({
    required this.currency,
    required this.value,
    required this.percentage,
    required this.animation,
    required this.textColor,
    required this.subTextColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final valueAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
    );

    final valueSectionHeight = size.getLargeFontSize() * 0.9;
    final currencyHeight = size.getLargeFontSize() * 0.8;

    return AnimatedBuilder(
      animation: valueAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: valueAnimation.value,
          child: Column(
            children: [
              // 金额显示
              SizedBox(
                height: valueSectionHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: currencyHeight,
                      child: Text(
                        currency,
                        style: TextStyle(
                          color: textColor,
                          fontSize: size.getLargeFontSize() * 0.6,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: valueSectionHeight,
                      child: AnimatedFlipCounter(
                        value: value * valueAnimation.value,
                        fractionDigits: 2,
                        textStyle: TextStyle(
                          color: textColor,
                          fontSize: size.getLargeFontSize() * 0.8,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 曲线图表（含日期标签）
class _CurveChart extends StatelessWidget {
  final List<double> data;
  final List<int> dates;
  final Animation<double> animation;
  final int highlightIndex;
  final Color primaryColor;
  final Color textColor;
  final HomeWidgetSize size;
  final bool isScrollable;
  final double contentWidth;
  final double height;

  const _CurveChart({
    required this.data,
    required this.dates,
    required this.animation,
    required this.highlightIndex,
    required this.primaryColor,
    required this.textColor,
    required this.size,
    this.isScrollable = false,
    this.contentWidth = double.infinity,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    );
    final labelsAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(isScrollable ? contentWidth : double.infinity, height),
          painter: _CurveChartPainter(
            data: data,
            dates: dates,
            progress: chartAnimation.value,
            labelsProgress: labelsAnimation.value,
            primaryColor: primaryColor,
            textColor: textColor,
            highlightIndex: highlightIndex,
            isDark: isDark,
            strokeWidth: size.getStrokeWidth() * size.progressStrokeScale,
            glowRadius: size.getIconSize(),
            highlightRadius: size.getIconSize() * 0.35,
            legendFontSize: size.getLegendFontSize(),
          ),
        );
      },
    );
  }
}

/// 曲线图画笔
class _CurveChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final Color primaryColor;
  final int highlightIndex;
  final bool isDark;
  final double strokeWidth;
  final double glowRadius;
  final double highlightRadius;

  _CurveChartPainter({
    required this.data,
    required this.progress,
    required this.primaryColor,
    required this.highlightIndex,
    required this.isDark,
    required this.strokeWidth,
    required this.glowRadius,
    required this.highlightRadius,
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

    // 创建平滑曲线路径（从左侧外部开始）
    final linePath = Path();
    linePath.moveTo(-10, points[0].dy);

    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        linePath.lineTo(points[i].dx, points[i].dy);
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

        linePath.cubicTo(
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
    linePath.lineTo(size.width + 10, points.last.dy);

    // 绘制渐变线条
    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // 创建渐变（从主色到灰色）
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [primaryColor, primaryColor, primaryColor.withOpacity(0.5)],
      stops: const [0.0, 0.7, 1.0],
    );

    linePaint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    // 应用裁剪以实现动画
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    canvas.drawPath(linePath, linePaint);

    // 绘制高亮点
    if (highlightIndex >= 0 && highlightIndex < points.length) {
      final highlightPoint = points[highlightIndex];

      // 外圈光晕
      final glowPaint =
          Paint()
            ..color = primaryColor.withOpacity(0.2)
            ..style = PaintingStyle.fill;
      canvas.drawCircle(highlightPoint, glowRadius, glowPaint);

      // 内圈（背景色）
      final bgPaint =
          Paint()
            ..color = isDark ? const Color(0xFF27272A) : Colors.white
            ..style = PaintingStyle.fill;
      canvas.drawCircle(highlightPoint, highlightRadius, bgPaint);

      // 边框圈
      final borderPaint =
          Paint()
            ..color = primaryColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth;
      canvas.drawCircle(highlightPoint, highlightRadius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CurveChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.glowRadius != glowRadius ||
        oldDelegate.highlightRadius != highlightRadius;
  }
}

/// 可滚动的图表区域（曲线图 + 日期标签）
class _ScrollableChartSection extends StatelessWidget {
  final List<double> chartData;
  final List<int> dates;
  final int highlightIndex;
  final Color primaryColor;
  final Color textColor;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _ScrollableChartSection({
    required this.chartData,
    required this.dates,
    required this.highlightIndex,
    required this.primaryColor,
    required this.textColor,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // 计算每个数据点的宽度
    final itemWidth = size.getIconSize() * 1.6;
    // 计算总宽度（至少为当前可用宽度）
    final contentWidth = (itemWidth * dates.length).clamp(
      200.0,
      double.infinity,
    );
    // 日期标签高度
    final dateLabelsHeight = size.getLegendFontSize() + 4;
    // 图表与标签间距
    final spacing = size.getItemSpacing();

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 根据可用高度动态计算图表高度
          // 可用高度 - 日期标签高度 - 间距 - padding
          final availableHeight = constraints.maxHeight;
          final chartHeight = (availableHeight - dateLabelsHeight - spacing)
              .clamp(50.0, 140.0);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: size.getItemSpacing()),
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 曲线图
                  SizedBox(
                    height: chartHeight,
                    width: contentWidth,
                    child: _CurveChart(
                      data: chartData,
                      animation: animation,
                      highlightIndex: highlightIndex,
                      primaryColor: primaryColor,
                      size: size,
                      isScrollable: true,
                      contentWidth: contentWidth,
                    ),
                  ),

                  SizedBox(height: spacing),

                  // 日期标签（固定高度）
                  SizedBox(
                    height: dateLabelsHeight,
                    child: _DateLabels(
                      dates: dates,
                      highlightIndex: highlightIndex,
                      primaryColor: primaryColor,
                      textColor: textColor,
                      animation: animation,
                      size: size,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 日期标签
class _DateLabels extends StatelessWidget {
  final List<int> dates;
  final int highlightIndex;
  final Color primaryColor;
  final Color textColor;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _DateLabels({
    required this.dates,
    required this.highlightIndex,
    required this.primaryColor,
    required this.textColor,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final labelsAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: labelsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: labelsAnimation.value,
          child: Row(
            children: List.generate(dates.length, (index) {
              final isHighlighted = index == highlightIndex;
              return SizedBox(
                width: size.getIconSize() * 1.6,
                child: Center(
                  child: Text(
                    dates[index].toString(),
                    style: TextStyle(
                      color: isHighlighted ? primaryColor : textColor,
                      fontSize: size.getLegendFontSize(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
