import 'dart:math' as math;
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 支出分类数据模型
class ExpenseCategoryData {
  final String label;
  final double percentage;
  final Color color;
  final String? subtitle;

  const ExpenseCategoryData({
    required this.label,
    required this.percentage,
    required this.color,
    this.subtitle,
  });

  factory ExpenseCategoryData.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryData(
      label: json['label'] as String? ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
      subtitle: json['subtitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'percentage': percentage,
      'color': color.value,
      if (subtitle != null) 'subtitle': subtitle,
    };
  }
}

class ExpenseDonutChartWidget extends StatefulWidget {
  final String badgeLabel;
  final String timePeriod;
  final double totalAmount;
  final String totalUnit;
  final List<ExpenseCategoryData> categories;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ExpenseDonutChartWidget({
    super.key,
    required this.badgeLabel,
    required this.timePeriod,
    required this.totalAmount,
    required this.totalUnit,
    required this.categories,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  factory ExpenseDonutChartWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final categoriesList =
        (props['categories'] as List<dynamic>?)
            ?.map(
              (e) => ExpenseCategoryData.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        const [];
    return ExpenseDonutChartWidget(
      badgeLabel: props['badgeLabel'] as String? ?? '',
      timePeriod: props['timePeriod'] as String? ?? '',
      totalAmount: (props['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalUnit: props['totalUnit'] as String? ?? '',
      categories: categoriesList,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<ExpenseDonutChartWidget> createState() =>
      _ExpenseDonutChartWidgetState();
}

class _ExpenseDonutChartWidgetState extends State<ExpenseDonutChartWidget>
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
    final primaryColor = const Color(0xFFD8F57E);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 340,
              height: widget.inline ? double.maxFinite : 500,
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.badgeLabel,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: widget.size.getTitleSpacing() / 2),
                      Text(
                        widget.timePeriod,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),
                  Center(
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: _DonutChart(
                        categories: widget.categories,
                        totalAmount: widget.totalAmount,
                        totalUnit: widget.totalUnit,
                        animation: _animation,
                      ),
                    ),
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(widget.categories.length, (
                          index,
                        ) {
                          final category = widget.categories[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: widget.size.getItemSpacing(),
                            ),
                            child: _CategoryItem(
                              label: category.label,
                              subtitle: category.subtitle,
                              percentage: category.percentage,
                              color: category.color,
                              animation: _animation,
                              index: index,
                              size: widget.size,
                            ),
                          );
                        }),
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

class _DonutChart extends StatelessWidget {
  final List<ExpenseCategoryData> categories;
  final double totalAmount;
  final String totalUnit;
  final Animation<double> animation;

  const _DonutChart({
    required this.categories,
    required this.totalAmount,
    required this.totalUnit,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(150, 150),
          painter: _DonutChartPainter(
            categories: categories,
            animation: animation.value,
            isDark: isDark,
          ),
          child: Center(
            child: AnimatedFlipCounter(
              value: totalAmount * animation.value,
              fractionDigits: totalAmount >= 100 ? 0 : 1,
              suffix: totalUnit,
              duration: const Duration(milliseconds: 800),
              textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey.shade900,
                height: 1.0,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ExpenseCategoryData> categories;
  final double animation;
  final bool isDark;

  _DonutChartPainter({
    required this.categories,
    required this.animation,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final strokeWidth = 8.0;

    double startAngle = -math.pi / 2;

    for (final category in categories) {
      final sweepAngle = (category.percentage / 100) * 2 * math.pi * animation;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint =
          Paint()
            ..color = category.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final String? subtitle;
  final double percentage;
  final Color color;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _CategoryItem({
    required this.label,
    this.subtitle,
    required this.percentage,
    required this.color,
    required this.animation,
    required this.index,
    required this.size,
  });

  // 计算延迟动画值
  double _getDelayedAnimationValue(double value) {
    final curve = Curves.easeOutCubic;
    final intervalStart = 0.3 + index * 0.1;
    final intervalEnd = 0.8 + index * 0.05;

    if (value <= intervalStart) return 0.0;
    if (value >= intervalEnd) return 1.0;

    final t = (value - intervalStart) / (intervalEnd - intervalStart);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final delayedValue = _getDelayedAnimationValue(animation.value);
        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(10 * (1 - delayedValue), 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: size.getItemSpacing() * 1.5),
                      Expanded(
                        child:
                            subtitle != null && subtitle!.isNotEmpty
                                ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            isDark
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      subtitle!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            isDark
                                                ? Colors.grey.shade500
                                                : Colors.grey.shade500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )
                                : Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                      ),
                    ],
                  ),
                ),
                AnimatedFlipCounter(
                  value: percentage * delayedValue,
                  fractionDigits: 0,
                  suffix: '%',
                  duration: const Duration(milliseconds: 600),
                  textStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
