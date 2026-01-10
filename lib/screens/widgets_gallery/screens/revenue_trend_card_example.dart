import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 收入趋势卡片示例
class RevenueTrendCardExample extends StatelessWidget {
  const RevenueTrendCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('收入趋势卡片')),
      body: Container(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFE5E5E5),
        child: const Center(
          child: RevenueTrendCardWidget(
            value: 145.32,
            currency: '\$',
            percentage: 12,
            period: 'Weekly',
            chartData: [80, 70, 90, 75, 60, 50, 40],
            dates: [22, 23, 24, 25, 26],
            highlightIndex: 4,
          ),
        ),
      ),
    );
  }
}

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

  const RevenueTrendCardWidget({
    super.key,
    required this.value,
    required this.currency,
    required this.percentage,
    required this.period,
    required this.chartData,
    required this.dates,
    required this.highlightIndex,
  });

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
    final textColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
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
              width: 340,
              height: 400,
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 时间筛选按钮
                    _PeriodSelector(
                      period: widget.period,
                      animation: _animation,
                    ),

                    const SizedBox(height: 24),

                    // 金额和百分比
                    _ValueSection(
                      currency: widget.currency,
                      value: widget.value,
                      percentage: widget.percentage,
                      animation: _animation,
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),

                    const SizedBox(height: 32),

                    // 曲线图
                    Expanded(
                      child: _CurveChart(
                        data: widget.chartData,
                        animation: _animation,
                        highlightIndex: widget.highlightIndex,
                        primaryColor: primaryColor,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 日期标签
                    _DateLabels(
                      dates: widget.dates,
                      highlightIndex: widget.highlightIndex,
                      primaryColor: primaryColor,
                      textColor: textColor,
                      animation: _animation,
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

  const _PeriodSelector({
    required this.period,
    required this.animation,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        period,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more,
                        color: textColor,
                        size: 16,
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

  const _ValueSection({
    required this.currency,
    required this.value,
    required this.percentage,
    required this.animation,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final valueAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: valueAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: valueAnimation.value,
          child: Column(
            children: [
              // 金额显示
              SizedBox(
                height: 54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 22,
                      child: Text(
                        currency,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      height: 52,
                      child: AnimatedFlipCounter(
                        value: value * valueAnimation.value,
                        fractionDigits: 2,
                        textStyle: TextStyle(
                          color: textColor,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 增长百分比
              Text(
                '+$percentage% compared to last week',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 曲线图表
class _CurveChart extends StatelessWidget {
  final List<double> data;
  final Animation<double> animation;
  final int highlightIndex;
  final Color primaryColor;

  const _CurveChart({
    required this.data,
    required this.animation,
    required this.highlightIndex,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: chartAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 140),
          painter: _CurveChartPainter(
            data: data,
            progress: chartAnimation.value,
            primaryColor: primaryColor,
            highlightIndex: highlightIndex,
            isDark: isDark,
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

  _CurveChartPainter({
    required this.data,
    required this.progress,
    required this.primaryColor,
    required this.highlightIndex,
    required this.isDark,
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
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // 创建渐变（从主色到灰色）
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        primaryColor,
        primaryColor,
        primaryColor.withOpacity(0.5),
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    linePaint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    // 应用裁剪以实现动画
    canvas.clipRect(Rect.fromLTWH(
      0,
      0,
      size.width * progress,
      size.height,
    ));

    canvas.drawPath(linePath, linePaint);

    // 绘制高亮点
    if (highlightIndex >= 0 && highlightIndex < points.length) {
      final highlightPoint = points[highlightIndex];

      // 外圈光晕
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(highlightPoint, 14, glowPaint);

      // 内圈（背景色）
      final bgPaint = Paint()
        ..color = isDark ? const Color(0xFF27272A) : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(highlightPoint, 8, bgPaint);

      // 边框圈
      final borderPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(highlightPoint, 8, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CurveChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 日期标签
class _DateLabels extends StatelessWidget {
  final List<int> dates;
  final int highlightIndex;
  final Color primaryColor;
  final Color textColor;
  final Animation<double> animation;

  const _DateLabels({
    required this.dates,
    required this.highlightIndex,
    required this.primaryColor,
    required this.textColor,
    required this.animation,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(dates.length, (index) {
                final isHighlighted = index == highlightIndex;
                return SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      dates[index].toString(),
                      style: TextStyle(
                        color: isHighlighted ? primaryColor : textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
