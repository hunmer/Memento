import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 分类堆叠消费卡片示例
class CategoryStackWidgetExample extends StatelessWidget {
  const CategoryStackWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('分类堆叠消费卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: CategoryStackWidget(
            title: 'Today Spending',
            currentAmount: 322,
            targetAmount: 443,
            currency: '\$',
            categories: [
              CategoryData(
                label: 'House',
                amount: 31,
                color: Color(0xFFFFD60A),
                percentage: 0.45,
              ),
              CategoryData(
                label: 'Food',
                amount: 37,
                color: Color(0xFFFF453A),
                percentage: 0.25,
              ),
              CategoryData(
                label: 'Fitness',
                amount: 43,
                color: Color(0xFF0A84FF),
                percentage: 0.20,
              ),
              CategoryData(
                label: 'Other',
                amount: 11,
                color: Color(0xFF8E8E93),
                percentage: 0.10,
              ),
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
  final double amount;
  final Color color;
  final double percentage;

  const CategoryData({
    required this.label,
    required this.amount,
    required this.color,
    required this.percentage,
  });

  /// 从 JSON 创建
  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      label: json['label'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF000000),
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'amount': amount,
      'color': color.value,
      'percentage': percentage,
    };
  }
}

/// 分类堆叠消费小组件
class CategoryStackWidget extends StatefulWidget {
  final String title;
  final double currentAmount;
  final double targetAmount;
  final String currency;
  final List<CategoryData> categories;

  const CategoryStackWidget({
    super.key,
    required this.title,
    required this.currentAmount,
    required this.targetAmount,
    this.currency = '\$',
    required this.categories,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory CategoryStackWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final categoriesList = (props['categories'] as List<dynamic>?)
            ?.map((e) => CategoryData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return CategoryStackWidget(
      title: props['title'] as String? ?? '',
      currentAmount: (props['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetAmount: (props['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currency: props['currency'] as String? ?? '\$',
      categories: categoriesList,
    );
  }

  @override
  State<CategoryStackWidget> createState() => _CategoryStackWidgetState();
}

class _CategoryStackWidgetState extends State<CategoryStackWidget>
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和金额
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: const Color(0xFF8E8E93),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            Text(
                              widget.currency,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 80,
                              height: 40,
                              child: AnimatedFlipCounter(
                                value: widget.currentAmount * _animation.value,
                                wholeDigits: 3,
                                fractionDigits: 0,
                                textStyle: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 40,
                              child: Text(
                                '${widget.currency}${widget.targetAmount}',
                                style: TextStyle(
                                  color: const Color(0xFF8E8E93),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 分类堆叠图和列表
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 堆叠柱状图
                      _StackedBarChart(
                        categories: widget.categories,
                        animation: _animation,
                      ),
                      const SizedBox(width: 16),
                      // 分类列表
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: List.generate(widget.categories.length, (
                            index,
                          ) {
                            final category = widget.categories[index];
                            final itemAnimation = CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                0.2 + index * 0.08,
                                0.7 + index * 0.08,
                                curve: Curves.easeOutCubic,
                              ),
                            );

                            return _CategoryItem(
                              category: category,
                              animation: itemAnimation,
                              currency: widget.currency,
                            );
                          }),
                        ),
                      ),
                    ],
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

/// 堆叠柱状图组件
class _StackedBarChart extends StatelessWidget {
  final List<CategoryData> categories;
  final Animation<double> animation;

  const _StackedBarChart({required this.categories, required this.animation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 40,
      height: 96,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            categories.map((category) {
              final height = category.percentage * 96;
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Container(
                    height: height * animation.value,
                    decoration: BoxDecoration(color: category.color),
                  );
                },
              );
            }).toList(),
      ),
    );
  }
}

/// 分类项组件
class _CategoryItem extends StatelessWidget {
  final CategoryData category;
  final Animation<double> animation;
  final String currency;

  const _CategoryItem({
    required this.category,
    required this.animation,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: category != categories.last ? 6 : 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.label,
                    style: TextStyle(
                      color:
                          isDark
                              ? const Color(0xFFD4D4D8)
                              : const Color(0xFF3F3F46),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 50,
                height: 16,
                child: AnimatedFlipCounter(
                  value: category.amount * animation.value,
                  wholeDigits: 2,
                  fractionDigits: 0,
                  prefix: currency,
                  textStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<CategoryData> get categories => [category];
}
