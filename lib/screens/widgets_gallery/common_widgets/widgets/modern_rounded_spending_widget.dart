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

  /// 分类项目组（每个分类下的详细项目列表）
  final List<CategoryItemGroup> categoryItems;

  /// 单位（默认为空字符串，可设置为 "分钟"、"小时" 等）
  final String unit;

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
    this.categoryItems = const [],
    this.unit = '',
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从属性 Map 创建组件（用于公共小组件系统）
  static ModernRoundedSpendingWidget fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    return ModernRoundedSpendingWidget(
      title: props['title'] as String? ?? 'Spending',
      currentSpending: (props['currentAmount'] as num?)?.toDouble() ??
          (props['currentSpending'] as num?)?.toDouble() ?? 0.0,
      budget: (props['budgetAmount'] as num?)?.toDouble() ??
          (props['budget'] as num?)?.toDouble() ?? 100.0,
      categories: (props['categories'] as List<dynamic>?)
              ?.map((e) => SpendingCategory.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      categoryItems: (props['categoryItems'] as List<dynamic>?)
              ?.map((e) => CategoryItemGroup.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      unit: props['unit'] as String? ?? '',
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
              constraints: const BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
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
                          fontSize: widget.size.getSubtitleFontSize(),
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
                            '${(widget.currentSpending * _animation.value).toInt()}${widget.unit}',
                            style: TextStyle(
                              fontSize: widget.size.getTitleFontSize(),
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(width: widget.size.getItemSpacing()),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '/ ${widget.budget.toInt()}${widget.unit}',
                              style: TextStyle(
                                fontSize: widget.size.getTitleFontSize(),
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
                    height: widget.size.getItemSpacing(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Row(
                        children:
                            List.generate(widget.categories.length, (index) {
                          final category = widget.categories[index];
                          return Expanded(
                            flex: (category.amount * 100).toInt(),
                            child: Container(
                              height: widget.size.getItemSpacing(),
                              color: category.color,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  SizedBox(height: widget.size.getTitleSpacing()),

                  // 分类列表（添加滚动支持）
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _buildCategoryItems(textColor, secondaryTextColor),
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

  /// 构建分类列表和详细项目
  List<Widget> _buildCategoryItems(Color textColor, Color secondaryTextColor) {
    final widgets = <Widget>[];
    final categoryCount = widget.categories.length;

    for (int i = 0; i < categoryCount; i++) {
      final category = widget.categories[i];

      // 计算动画区间，确保不超过 1.0
      final begin = (0.3 + i * 0.15).clamp(0.0, 0.7);
      final end = (begin + 0.2).clamp(0.0, 1.0);

      final itemAnimation = CurvedAnimation(
        parent: _animationController,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

      // 查找该分类的详细项目
      final itemGroup = widget.categoryItems.firstWhere(
        (g) => g.categoryName == category.name,
        orElse: () => const CategoryItemGroup(categoryName: '', items: []),
      );

      // 分类项（包含详细项目在右侧）
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: widget.size.getItemSpacing()),
          child: _CategoryItem(
            category: category,
            detailItems: itemGroup.items,
            animation: itemAnimation,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            unit: widget.unit,
            size: widget.size,
          ),
        ),
      );
    }

    return widgets;
  }
}

/// 分类列表项
class _CategoryItem extends StatelessWidget {
  final SpendingCategory category;
  final List<CategoryItem> detailItems;
  final Animation<double> animation;
  final Color textColor;
  final Color secondaryTextColor;
  final String unit;
  final HomeWidgetSize size;

  const _CategoryItem({
    required this.category,
    required this.detailItems,
    required this.animation,
    required this.textColor,
    required this.secondaryTextColor,
    required this.unit,
    required this.size,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：颜色块、名称和详细信息
                Expanded(
                  child: Row(
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
                      // 分类名称
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: size.getSubtitleFontSize() + 2,
                          fontWeight: FontWeight.w500,
                          color: textColor.withOpacity(0.87),
                        ),
                      ),
                      // 详细信息（副标题，显示在名称右侧）
                      if (detailItems.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            detailItems.map((e) => e.title).join(' · '),
                            style: TextStyle(
                              fontSize: size.getSubtitleFontSize(),
                              fontWeight: FontWeight.w400,
                              color: secondaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 右侧：金额（单位在数值后方）
                Text(
                  '${category.amount.toInt()}$unit',
                  style: TextStyle(
                    fontSize: size.getSubtitleFontSize() + 2,
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
