import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 图表分类数据
class ChartCategory {
  final String name;
  final Color color;

  const ChartCategory({required this.name, required this.color});

  /// 从 JSON 创建（用于公共小组件系统）
  factory ChartCategory.fromJson(Map<String, dynamic> json) {
    return ChartCategory(
      name: json['name'] as String? ?? '',
      color: Color(json['color'] as int? ?? 0xFF000000),
    );
  }

  /// 转换为 JSON（用于公共小组件系统）
  Map<String, dynamic> toJson() {
    return {'name': name, 'color': color.value};
  }
}

/// 图表分段数值
class ChartSegmentValue {
  final double value;
  final int categoryIndex;

  const ChartSegmentValue({required this.value, required this.categoryIndex});

  /// 从 JSON 创建（用于公共小组件系统）
  factory ChartSegmentValue.fromJson(Map<String, dynamic> json) {
    return ChartSegmentValue(
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      categoryIndex: json['categoryIndex'] as int? ?? 0,
    );
  }

  /// 转换为 JSON（用于公共小组件系统）
  Map<String, dynamic> toJson() {
    return {'value': value, 'categoryIndex': categoryIndex};
  }
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
///   categories: [
///     ChartCategory(name: '2010', color: Color(0xFF0F4C81)),
///     ChartCategory(name: '2011', color: Color(0xFF48C6E0)),
///   ],
///   data: [
///     [ChartSegmentValue(value: 15, categoryIndex: 0)],
///     [ChartSegmentValue(value: 25, categoryIndex: 1)],
///   ],
///   size: const MediumSize(),
///   inline: false,
/// )
/// ```
///
/// 使用 fromProps 从 props 创建：
/// ```dart
/// StackedBarChartCard.fromProps(props, size)
/// ```
class StackedBarChartCard extends StatefulWidget {
  /// 卡片标题
  final String title;

  /// 分类列表
  final List<ChartCategory> categories;

  /// 数据列表（外层为列，内层为分段）
  final List<List<ChartSegmentValue>> data;

  /// 是否显示筛选按钮
  final bool showFilterButton;

  /// 筛选按钮点击回调
  final VoidCallback? onFilterPressed;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const StackedBarChartCard({
    super.key,
    required this.title,
    required this.categories,
    required this.data,
    this.showFilterButton = true,
    this.onFilterPressed,
    this.inline = false,
    this.size = const MediumSize(),
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory StackedBarChartCard.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final categoriesList =
        (props['categories'] as List<dynamic>?)
            ?.map((e) => ChartCategory.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final dataList =
        (props['data'] as List<dynamic>?)
            ?.map(
              (e) =>
                  (e as List<dynamic>)
                      .map(
                        (seg) => ChartSegmentValue.fromJson(
                          seg as Map<String, dynamic>,
                        ),
                      )
                      .toList(),
            )
            .toList() ??
        const [];

    return StackedBarChartCard(
      title: props['title'] as String? ?? '',
      categories: categoriesList,
      data: dataList,
      showFilterButton: props['showFilterButton'] as bool? ?? true,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

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
              width: widget.inline ? double.maxFinite : null,
              height: widget.inline ? double.maxFinite : null,
              constraints:
                  widget.inline ? null : widget.size.getHeightConstraints(),
              padding: widget.size.getPadding(),
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
                children: [
                  // 标题栏 - 固定高度
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: widget.size.getTitleFontSize(),
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? const Color(0xFFF3F4F6)
                                    : const Color(0xFF111827),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (widget.showFilterButton)
                        _FilterButton(
                          isDark: isDark,
                          onPressed: widget.onFilterPressed,
                          size: widget.size,
                        ),
                    ],
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),

                  // 堆叠柱状图 - 使用 Expanded 填充可用高度
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(widget.data.length, (
                        columnIndex,
                      ) {
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
                        return Expanded(
                          child: _StackedBarColumn(
                            segments: widget.data[columnIndex],
                            categories: widget.categories,
                            isDark: isDark,
                            animation: columnAnimation,
                            size: widget.size,
                          ),
                        );
                      }),
                    ),
                  ),

                  // 分类图例 - 固定在卡片底部
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(widget.categories.length, (
                        index,
                      ) {
                        final category = widget.categories[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right:
                                index < widget.categories.length - 1
                                    ? widget.size.getItemSpacing()
                                    : 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: widget.size.getLegendIndicatorWidth(),
                                height: widget.size.getLegendIndicatorHeight(),
                                decoration: BoxDecoration(
                                  color: category.color,
                                  borderRadius: BorderRadius.circular(
                                    widget.size.getLegendIndicatorHeight() / 2,
                                  ),
                                ),
                              ),
                              SizedBox(width: widget.size.getSmallSpacing()),
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: widget.size.getSubtitleFontSize(),
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark
                                          ? const Color(0xFFF3F4F6)
                                          : const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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

/// 堆叠柱子组件
class _StackedBarColumn extends StatelessWidget {
  final List<ChartSegmentValue> segments;
  final List<ChartCategory> categories;
  final bool isDark;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _StackedBarColumn({
    required this.segments,
    required this.categories,
    required this.isDark,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final barSpacing = size.getSmallSpacing();
    final borderRadius = size.getBarWidth() / 2;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: segments.asMap().entries.map((entry) {
        final index = entry.key;
        final segment = entry.value;

        if (segment.value == 0) {
          return const SizedBox.shrink();
        }

        final color = categories[segment.categoryIndex].color;
        final isLast = index == segments.length - 1;
        final isFirst = index == 0;
        final weight = (segment.value * 10).round();

        return Flexible(
          flex: weight > 0 ? weight : 1,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : barSpacing,
            ),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(
                    horizontal: size.getBarSpacing(),
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.vertical(
                      top: isFirst ? Radius.circular(borderRadius) : Radius.zero,
                      bottom: isLast ? Radius.circular(borderRadius) : Radius.zero,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 筛选按钮组件
class _FilterButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onPressed;
  final HomeWidgetSize size;

  const _FilterButton({
    required this.isDark,
    this.onPressed,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(size.getSmallSpacing()),
        child: Icon(
          Icons.tune,
          size: size.getIconSize(),
          color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
        ),
      ),
    );
  }
}
