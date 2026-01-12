import 'dart:math' as math;
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 分类数据模型
class CategoryChartData {
  final String label;
  final double percentage;
  final Color color;

  const CategoryChartData({
    required this.label,
    required this.percentage,
    required this.color,
  });

  /// 从 JSON 创建
  factory CategoryChartData.fromJson(Map<String, dynamic> json) {
    return CategoryChartData(
      label: json['label'] as String,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'percentage': percentage,
      'color': color.value,
    };
  }
}

/// 分类环形图卡片小组件
class CategoryDonutChartCardWidget extends StatefulWidget {
  /// 顶部徽章标签
  final String badgeLabel;

  /// 时间周期描述
  final String timePeriod;

  /// 总金额数值
  final double totalAmount;

  /// 总金额单位（如 K、M 等）
  final String totalUnit;

  /// 分类数据列表
  final List<CategoryChartData> categories;

  /// 主色调（用于徽章背景）
  final Color? primaryColor;

  const CategoryDonutChartCardWidget({
    super.key,
    required this.badgeLabel,
    required this.timePeriod,
    required this.totalAmount,
    required this.totalUnit,
    required this.categories,
    this.primaryColor,
  });

  /// 从 props 创建实例
  factory CategoryDonutChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final categoriesList = props['categories'] as List<dynamic>?;
    final categories = categoriesList?.map((categoryJson) {
      return CategoryChartData.fromJson(categoryJson as Map<String, dynamic>);
    }).toList() ?? [];

    final primaryColor = props['primaryColor'] as int?;
    return CategoryDonutChartCardWidget(
      badgeLabel: props['badgeLabel'] as String? ?? '',
      timePeriod: props['timePeriod'] as String? ?? '',
      totalAmount: (props['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalUnit: props['totalUnit'] as String? ?? '',
      categories: categories,
      primaryColor: primaryColor != null ? Color(primaryColor) : null,
    );
  }

  @override
  State<CategoryDonutChartCardWidget> createState() =>
      _CategoryDonutChartCardWidgetState();
}

class _CategoryDonutChartCardWidgetState extends State<CategoryDonutChartCardWidget>
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
    final primaryColor = widget.primaryColor ?? const Color(0xFFD8F57E);

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
                  _buildHeaderSection(primaryColor, isDark),
                  const SizedBox(height: 16),
                  // 环形图
                  Center(
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: _DonutChart(
                        categories: widget.categories,
                        totalAmount: widget.totalAmount,
                        totalUnit: widget.totalUnit,
                        animation: _animation,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 分类列表
                  _buildCategoryList(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建头部区域
  Widget _buildHeaderSection(Color primaryColor, bool isDark) {
    return Column(
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
    );
  }

  /// 构建分类列表
  Widget _buildCategoryList(bool isDark) {
    return Column(
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
    );
  }
}

/// 环形图绘制组件
class _DonutChart extends StatelessWidget {
  final List<CategoryChartData> categories;
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
                  value: totalAmount * animation.value,
                  fractionDigits: 0,
                  suffix: totalUnit,
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
  final List<CategoryChartData> categories;
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
    const strokeWidth = 8.0;

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
