import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../models/spending_category.dart';

/// 现代圆角消费卡片小组件
///
/// 显示当前消费、预算、分类进度条和分类列表
class ModernRoundedSpendingWidget extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 当前消费金额
  final double currentSpending;

  /// 预算金额
  final double budget;

  /// 消费分类列表
  final List<SpendingCategory> categories;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ModernRoundedSpendingWidget({
    super.key,
    required this.title,
    required this.currentSpending,
    required this.budget,
    required this.categories,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从属性 Map 创建组件（用于公共小组件系统）
  static ModernRoundedSpendingWidget fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return ModernRoundedSpendingWidget(
      title: props['title'] as String? ?? 'Spending',
      currentSpending: (props['currentSpending'] as num?)?.toDouble() ?? 0.0,
      budget: (props['budget'] as num?)?.toDouble() ?? 100.0,
      categories: (props['categories'] as List<dynamic>?)
              ?.map((e) => SpendingCategory.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<ModernRoundedSpendingWidget> createState() =>
      _ModernRoundedSpendingWidgetState();
}

class _ModernRoundedSpendingWidgetState extends State<ModernRoundedSpendingWidget>
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
              width: widget.inline ? double.maxFinite : 340,
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
              padding: widget.size.getPadding(),
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
                      SizedBox(height: widget.size.getItemSpacing()),
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

                  SizedBox(height: widget.size.getTitleSpacing()),

                  // 分段进度条
                  SizedBox(
                    height: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Row(
                        children:
                            List.generate(widget.categories.length, (index) {
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

                  SizedBox(height: widget.size.getTitleSpacing()),

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
                      padding: EdgeInsets.only(bottom: widget.size.getItemSpacing()),
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
