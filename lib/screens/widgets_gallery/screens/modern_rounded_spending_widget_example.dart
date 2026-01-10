import 'package:flutter/material.dart';

/// 消费卡片示例
class ModernRoundedSpendingWidgetExample extends StatelessWidget {
  const ModernRoundedSpendingWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('消费卡片')),
      body: Container(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        child: const Center(
          child: ModernRoundedSpendingWidget(
            title: 'Today Spending',
            currentSpending: 322.0,
            budget: 443.0,
            categories: [
              SpendingCategory(name: 'Food', amount: 37.0, color: Color(0xFFFF3B30)),
              SpendingCategory(name: 'Fitness', amount: 43.0, color: Color(0xFF007AFF)),
              SpendingCategory(name: 'Transport', amount: 31.0, color: Color(0xFFFFCC00)),
              SpendingCategory(name: 'Other', amount: 11.0, color: Color(0xFF8E8E93)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 消费分类数据模型
class SpendingCategory {
  /// 分类名称
  final String name;

  /// 消费金额
  final double amount;

  /// 分类颜色
  final Color color;

  const SpendingCategory({
    required this.name,
    required this.amount,
    required this.color,
  });
}

/// 消费卡片小组件
class ModernRoundedSpendingWidget extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 当前消费金额
  final double currentSpending;

  /// 预算金额
  final double budget;

  /// 消费分类列表
  final List<SpendingCategory> categories;

  const ModernRoundedSpendingWidget({
    super.key,
    required this.title,
    required this.currentSpending,
    required this.budget,
    required this.categories,
  });

  @override
  State<ModernRoundedSpendingWidget> createState() =>
      _ModernRoundedSpendingWidgetState();
}

class _ModernRoundedSpendingWidgetState
    extends State<ModernRoundedSpendingWidget>
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
    final backgroundColor = isDark ? const Color(0xFF000000) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final secondaryTextColor =
        isDark ? const Color(0xFFAEAEB2) : const Color(0xFF8E8E93);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 340,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和金额
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                          height: 1.0,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '\$${(widget.currentSpending * _animation.value).toInt()}',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '/ ${widget.budget.toInt()}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 分段进度条
                  SizedBox(
                    height: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Row(
                        children: List.generate(widget.categories.length, (index) {
                          final category = widget.categories[index];
                          return Expanded(
                            flex: (category.amount * 100).toInt(),
                            child: Container(
                              height: 10,
                              color: category.color,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 分类列表
                  ...List.generate(widget.categories.length, (index) {
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
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _CategoryItem(
                        category: category,
                        animation: itemAnimation,
                        textColor: textColor,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 分类列表项
class _CategoryItem extends StatelessWidget {
  final SpendingCategory category;
  final Animation<double> animation;
  final Color textColor;

  const _CategoryItem({
    required this.category,
    required this.animation,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
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
                // 颜色块和名称
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: category.color.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor.withOpacity(0.87),
                      ),
                    ),
                  ],
                ),
                // 金额
                Text(
                  '\$${category.amount.toInt()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: -0.3,
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
