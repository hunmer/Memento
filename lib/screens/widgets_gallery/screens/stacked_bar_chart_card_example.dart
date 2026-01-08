import 'package:flutter/material.dart';

/// 堆叠柱状图卡片示例
class StackedBarChartCardExample extends StatelessWidget {
  const StackedBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('堆叠柱状图卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: StackedBarChartCardWidget(
            title: 'America',
            description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt.',
            categories: [
              ChartCategory(name: '2010', color: Color(0xFF0F4C81)),
              ChartCategory(name: '2011', color: Color(0xFF48C6E0)),
              ChartCategory(name: '2012', color: Color(0xFFA8DFF0)),
            ],
            data: [
                // 第1列
                [
                  ChartSegmentValue(value: 0, categoryIndex: 0),
                  ChartSegmentValue(value: 15, categoryIndex: 0),
                  ChartSegmentValue(value: 20, categoryIndex: 1),
                  ChartSegmentValue(value: 30, categoryIndex: 2),
                  ChartSegmentValue(value: 25, categoryIndex: 0),
                ],
                // 第2列
                [
                  ChartSegmentValue(value: 5, categoryIndex: 0),
                  ChartSegmentValue(value: 35, categoryIndex: 1),
                  ChartSegmentValue(value: 15, categoryIndex: 2),
                  ChartSegmentValue(value: 45, categoryIndex: 0),
                ],
                // 第3列
                [
                  ChartSegmentValue(value: 5, categoryIndex: 0),
                  ChartSegmentValue(value: 40, categoryIndex: 1),
                  ChartSegmentValue(value: 10, categoryIndex: 2),
                  ChartSegmentValue(value: 45, categoryIndex: 0),
                ],
                // 第4列
                [
                  ChartSegmentValue(value: 8, categoryIndex: 0),
                  ChartSegmentValue(value: 25, categoryIndex: 1),
                  ChartSegmentValue(value: 17, categoryIndex: 2),
                  ChartSegmentValue(value: 50, categoryIndex: 0),
                ],
                // 第5列
                [
                  ChartSegmentValue(value: 6, categoryIndex: 0),
                  ChartSegmentValue(value: 28, categoryIndex: 1),
                  ChartSegmentValue(value: 16, categoryIndex: 2),
                  ChartSegmentValue(value: 50, categoryIndex: 0),
                ],
                // 第6列
                [
                  ChartSegmentValue(value: 7, categoryIndex: 0),
                  ChartSegmentValue(value: 20, categoryIndex: 1),
                  ChartSegmentValue(value: 13, categoryIndex: 2),
                  ChartSegmentValue(value: 60, categoryIndex: 0),
                ],
                // 第7列
                [
                  ChartSegmentValue(value: 12, categoryIndex: 0),
                  ChartSegmentValue(value: 18, categoryIndex: 1),
                  ChartSegmentValue(value: 35, categoryIndex: 2),
                  ChartSegmentValue(value: 35, categoryIndex: 0),
                ],
                // 第8列
                [
                  ChartSegmentValue(value: 5, categoryIndex: 0),
                  ChartSegmentValue(value: 45, categoryIndex: 1),
                  ChartSegmentValue(value: 15, categoryIndex: 2),
                  ChartSegmentValue(value: 35, categoryIndex: 0),
                ],
                // 第9列
                [
                  ChartSegmentValue(value: 9, categoryIndex: 0),
                  ChartSegmentValue(value: 10, categoryIndex: 1),
                  ChartSegmentValue(value: 41, categoryIndex: 2),
                  ChartSegmentValue(value: 40, categoryIndex: 0),
                ],
                // 第10列
                [
                  ChartSegmentValue(value: 10, categoryIndex: 0),
                  ChartSegmentValue(value: 15, categoryIndex: 1),
                  ChartSegmentValue(value: 35, categoryIndex: 2),
                  ChartSegmentValue(value: 40, categoryIndex: 0),
                ],
                // 第11列
                [
                  ChartSegmentValue(value: 6, categoryIndex: 0),
                  ChartSegmentValue(value: 40, categoryIndex: 1),
                  ChartSegmentValue(value: 24, categoryIndex: 2),
                  ChartSegmentValue(value: 30, categoryIndex: 0),
                ],
                // 第12列
                [
                  ChartSegmentValue(value: 5, categoryIndex: 0),
                  ChartSegmentValue(value: 45, categoryIndex: 1),
                  ChartSegmentValue(value: 20, categoryIndex: 2),
                  ChartSegmentValue(value: 30, categoryIndex: 0),
                ],
            ],
            subtitle: 'Historic World Population',
          ),
        ),
      ),
    );
  }
}

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
class StackedBarChartCardWidget extends StatefulWidget {
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

  const StackedBarChartCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.categories,
    required this.data,
    required this.subtitle,
  });

  @override
  State<StackedBarChartCardWidget> createState() => _StackedBarChartCardWidgetState();
}

class _StackedBarChartCardWidgetState extends State<StackedBarChartCardWidget>
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
                          color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
                        ),
                      ),
                      _FilterButton(isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 堆叠柱状图
                  SizedBox(
                    height: 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(widget.data.length, (columnIndex) {
                        final columnAnimation = CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            columnIndex * 0.05,
                            0.5 + columnIndex * 0.05,
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
                    children: List.generate(widget.categories.length, (index) {
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
                                color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
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
                          color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
            final height = 4.0 + segment.value * 1.5; // 基础高度 + 比例高度
            final color = categories[segment.categoryIndex].color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
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

  const _FilterButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
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
