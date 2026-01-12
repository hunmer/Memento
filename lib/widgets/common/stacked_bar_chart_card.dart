import 'package:flutter/material.dart';

/// 图表分类数据
class ChartCategory {
  final String name;
  final Color color;

  const ChartCategory({
    required this.name,
    required this.color,
  });
}

/// 图表分段数值
class ChartSegmentValue {
  final double value;
  final int categoryIndex;

  const ChartSegmentValue({
    required this.value,
    required this.categoryIndex,
  });
}

/// 堆叠柱状图卡片小组件
///
/// 用于展示堆叠柱状图数据的卡片组件，支持动画效果和主题适配。
/// 适用于展示多种分类的堆叠数据，如时间序列数据、对比数据等。
///
/// 使用示例：
/// ```dart
/// StackedBarChartCard(
///   title: 'America',
///   description: 'Lorem ipsum dolor sit amet...',
///   categories: [
///     ChartCategory(name: '2010', color: Color(0xFF0F4C81)),
///     ChartCategory(name: '2011', color: Color(0xFF48C6E0)),
///   ],
///   data: [
///     [ChartSegmentValue(value: 15, categoryIndex: 0)],
///     [ChartSegmentValue(value: 25, categoryIndex: 1)],
///   ],
///   subtitle: 'Historic World Population',
/// )
/// ```
class StackedBarChartCard extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 卡片描述
  final String description;

  /// 分类列表
  final List<ChartCategory> categories;

  /// 数据列表（外层为列，内层为分段）
  final List<List<ChartSegmentValue>> data;

  /// 子标题
  final String subtitle;

  /// 是否显示筛选按钮
  final bool showFilterButton;

  /// 筛选按钮点击回调
  final VoidCallback? onFilterPressed;

  const StackedBarChartCard({
    super.key,
    required this.title,
    required this.description,
    required this.categories,
    required this.data,
    required this.subtitle,
    this.showFilterButton = true,
    this.onFilterPressed,
  });

  @override
  State<StackedBarChartCard> createState() => _StackedBarChartCardState();
}

class _StackedBarChartCardState extends State<StackedBarChartCard>
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
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题栏
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFF3F4F6)
                              : const Color(0xFF111827),
                        ),
                      ),
                      if (widget.showFilterButton)
                        _FilterButton(
                          isDark: isDark,
                          onPressed: widget.onFilterPressed,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 堆叠柱状图
                  SizedBox(
                    height: 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(widget.data.length, (columnIndex) {
                        final start = (columnIndex * 0.04).clamp(0.0, 0.5);
                        final end = (start + 0.5).clamp(0.0, 1.0);
                        final columnAnimation = CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            start,
                            end,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                        return Padding(
                          padding: EdgeInsets.only(
                            right: columnIndex < widget.data.length - 1 ? 6 : 0,
                          ),
                          child: _StackedBarColumn(
                            segments: widget.data[columnIndex],
                            categories: widget.categories,
                            isDark: isDark,
                            animation: columnAnimation,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 分类图例
                  Row(
                    children:
                        List.generate(widget.categories.length, (index) {
                      final category = widget.categories[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < widget.categories.length - 1 ? 24 : 0,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 12,
                              decoration: BoxDecoration(
                                color: category.color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFF3F4F6)
                                    : const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // 描述信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFF3F4F6)
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          height: 1.5,
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

/// 堆叠柱子组件
class _StackedBarColumn extends StatelessWidget {
  final List<ChartSegmentValue> segments;
  final List<ChartCategory> categories;
  final bool isDark;
  final Animation<double> animation;

  const _StackedBarColumn({
    required this.segments,
    required this.categories,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: segments.map((segment) {
            if (segment.value == 0) {
              return const SizedBox.shrink();
            }
            final height = 2.0 + segment.value * 1.1; // 基础高度 + 比例高度
            final color = categories[segment.categoryIndex].color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: height * animation.value,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// 筛选按钮组件
class _FilterButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onPressed;

  const _FilterButton({
    required this.isDark,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.tune,
          size: 24,
          color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
        ),
      ),
    );
  }
}
