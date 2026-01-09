import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 支出分类环形图示例
class ExpenseDonutChartExample extends StatelessWidget {
  const ExpenseDonutChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('支出分类环形图')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: ExpenseDonutChartWidget(
            badgeLabel: 'Expenses',
            timePeriod: 'In the past 7 days',
            totalAmount: 32,
            totalUnit: 'K',
            categories: [
              CategoryData(label: 'Relax', percentage: 54, color: Color(0xFF2DD4BF)),
              CategoryData(label: 'Food', percentage: 27, color: Color(0xFF8B5CF6)),
              CategoryData(label: 'Transport', percentage: 12, color: Color(0xFFD8F57E)),
              CategoryData(label: 'Pets', percentage: 7, color: Color(0xFFFDBA74)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 分类数据模型
class CategoryData {
  final String label;
  final double percentage;
  final Color color;

  const CategoryData({
    required this.label,
    required this.percentage,
    required this.color,
  });
}

/// 支出分类环形图小组件
class ExpenseDonutChartWidget extends StatefulWidget {
  final String badgeLabel;
  final String timePeriod;
  final double totalAmount;
  final String totalUnit;
  final List<CategoryData> categories;

  const ExpenseDonutChartWidget({
    super.key,
    required this.badgeLabel,
    required this.timePeriod,
    required this.totalAmount,
    required this.totalUnit,
    required this.categories,
  });

  @override
  State<ExpenseDonutChartWidget> createState() => _ExpenseDonutChartWidgetState();
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
              width: 340,
              height: 500,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(40),
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
                  // 顶部标签
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      const SizedBox(height: 8),
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
                  const SizedBox(height: 16),
                  // 环形图
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: _DonutChart(
                        categories: widget.categories,
                        animation: _animation,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 分类列表
                  Column(
                    children: List.generate(
                      widget.categories.length,
                      (index) {
                        final category = widget.categories[index];
                        final itemAnimation = CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            0.3 + index * 0.1,
                            0.8 + index * 0.05,
                            curve: Curves.easeOutCubic,
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CategoryItem(
                            label: category.label,
                            percentage: category.percentage,
                            color: category.color,
                            animation: itemAnimation,
                          ),
                        );
                      },
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

/// 环形图绘制组件
class _DonutChart extends StatelessWidget {
  final List<CategoryData> categories;
  final Animation<double> animation;

  const _DonutChart({
    required this.categories,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(220, 220),
          painter: _DonutChartPainter(
            categories: categories,
            animation: animation.value,
            isDark: isDark,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedFlipCounter(
                  value: 32 * animation.value,
                  fractionDigits: 0,
                  suffix: 'K',
                  duration: const Duration(milliseconds: 800),
                  textStyle: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
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

/// 环形图绘制器
class _DonutChartPainter extends CustomPainter {
  final List<CategoryData> categories;
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

    double startAngle = -math.pi / 2; // 从顶部开始

    for (final category in categories) {
      final sweepAngle = (category.percentage / 100) * 2 * math.pi * animation;
      final pathColor = category.color;

      final rect = Rect.fromCircle(center: center, radius: radius);

      final paint = Paint()
        ..color = pathColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// 分类列表项
class _CategoryItem extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;
  final Animation<double> animation;

  const _CategoryItem({
    required this.label,
    required this.percentage,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(10 * (1 - animation.value), 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                AnimatedFlipCounter(
                  value: percentage * animation.value,
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
