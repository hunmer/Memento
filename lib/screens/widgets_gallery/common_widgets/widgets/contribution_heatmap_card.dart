import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 贡献热力图小组件
class ContributionHeatmapCardWidget extends StatefulWidget {
  final String title;
  final String contributionCount;
  final List<String> years;
  final String selectedYear;
  final List<String> months;
  final List<List<int>> heatmapData;
  final String description;
  final String showMoreLabel;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const ContributionHeatmapCardWidget({
    super.key,
    required this.title,
    required this.contributionCount,
    required this.years,
    required this.selectedYear,
    required this.months,
    required this.heatmapData,
    required this.description,
    required this.showMoreLabel,
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory ContributionHeatmapCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final yearsList = (props['years'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['2024'];
    final monthsList = (props['months'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    final heatmapDataList = (props['heatmapData'] as List<dynamic>?)
            ?.map((e) => (e as List<dynamic>).map((v) => v as int).toList())
            .toList() ??
        [
          [0, 0, 0, 0, 0, 0],
          [0, 1, 2, 1, 0, 0],
          [0, 2, 3, 2, 1, 0],
          [0, 1, 2, 3, 2, 1],
          [0, 0, 1, 2, 1, 0],
          [0, 0, 0, 1, 0, 0],
        ];

    return ContributionHeatmapCardWidget(
      title: props['title'] as String? ?? '',
      contributionCount: props['contributionCount'] as String? ?? '',
      years: yearsList,
      selectedYear: props['selectedYear'] as String? ?? yearsList.first,
      months: monthsList,
      heatmapData: heatmapDataList,
      description: props['description'] as String? ?? '',
      showMoreLabel: props['showMoreLabel'] as String? ?? 'Show more',
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<ContributionHeatmapCardWidget> createState() =>
      _ContributionHeatmapCardWidgetState();
}

class _ContributionHeatmapCardWidgetState extends State<ContributionHeatmapCardWidget>
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
    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final primaryColor = const Color(0xFF0070AD);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 360,
              constraints: widget.inline ? null : const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: widget.size.getPadding(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题和设置按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: widget.size.getTitleFontSize(),
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                              height: 1.2,
                            ),
                          ),
                        ),
                        _SettingsButton(isDark: isDark),
                      ],
                    ),
                    SizedBox(height: widget.size.getItemSpacing()),
                    // 贡献计数
                    Text(
                      widget.contributionCount,
                      style: TextStyle(
                        fontSize: widget.size.getSubtitleFontSize(),
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    // 年份选择器
                    Wrap(
                      spacing: 8,
                      children: widget.years.map((year) {
                        final isSelected = year == widget.selectedYear;
                        return _YearButton(
                          year: year,
                          isSelected: isSelected,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          size: widget.size,
                        );
                      }).toList(),
                    ),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    // 描述
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: widget.size.getSubtitleFontSize(),
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    // 热力图
                    _ContributionHeatmap(
                      months: widget.months,
                      data: widget.heatmapData,
                      animation: _animation,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      size: widget.size,
                    ),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    // 底部信息
                    _HeatmapFooter(
                      isDark: isDark,
                      primaryColor: primaryColor,
                      size: widget.size,
                    ),
                    SizedBox(height: widget.size.getTitleSpacing()),
                    // 显示更多按钮
                    _ShowMoreButton(
                      label: widget.showMoreLabel,
                      isDark: isDark,
                      size: widget.size,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 设置按钮组件
class _SettingsButton extends StatelessWidget {
  final bool isDark;

  const _SettingsButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.settings,
        size: 20,
        color: Color(0xFF6B7280),
      ),
    );
  }
}

/// 年份按钮组件
class _YearButton extends StatelessWidget {
  final String year;
  final bool isSelected;
  final bool isDark;
  final Color primaryColor;
  final HomeWidgetSize size;

  const _YearButton({
    required this.year,
    required this.isSelected,
    required this.isDark,
    required this.primaryColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : (isDark ? const Color(0xFF1F2937) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        year,
        style: TextStyle(
          fontSize: size.getSubtitleFontSize(),
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151)),
        ),
      ),
    );
  }
}

/// 贡献热力图组件
class _ContributionHeatmap extends StatelessWidget {
  final List<String> months;
  final List<List<int>> data;
  final Animation<double> animation;
  final bool isDark;
  final Color primaryColor;
  final HomeWidgetSize size;

  const _ContributionHeatmap({
    required this.months,
    required this.data,
    required this.animation,
    required this.isDark,
    required this.primaryColor,
    required this.size,
  });

  Color _getColorForLevel(int level) {
    switch (level) {
      case 0:
        return isDark ? const Color(0xFF374151) : const Color(0xFFE0F2FE);
      case 1:
        return isDark ? const Color(0xFF0369A1) : primaryColor;
      case 2:
        return isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0C2B64);
      case 3:
        return isDark ? const Color(0xFF0EA5E9) : const Color(0xFF7DD3FC);
      case 4:
        return isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD);
      default:
        return isDark ? const Color(0xFF374151) : const Color(0xFFE0F2FE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 月份标签
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: months.map((month) {
              return Expanded(
                child: Center(
                  child: Text(
                    month,
                    style: TextStyle(
                      fontSize: size.getLegendFontSize(),
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 热力图网格 (6列 x 6行)
        SizedBox(
          height: 160,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: months.length * 6,
            itemBuilder: (context, index) {
              final col = index % 6;
              final row = index ~/ 6;
              // data[col][row] 因为外层是列（月份），内层是行
              final level = col < data.length && row < data[col].length
                  ? data[col][row]
                  : 0;

              // 确保所有 Interval 的 end 值不超过 1.0
              // elementCount = 36, baseEnd = 0.6
              // step <= (1.0 - 0.6) / 35 = 0.0114
              final step = 0.01;
              final itemAnimation = CurvedAnimation(
                parent: animation,
                curve: Interval(
                  index * step,
                  0.6 + index * step,
                  curve: Curves.easeOutCubic,
                ),
              );

              return AnimatedBuilder(
                animation: itemAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + 0.2 * itemAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getColorForLevel(level),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 热力图底部信息
class _HeatmapFooter extends StatelessWidget {
  final bool isDark;
  final Color primaryColor;
  final HomeWidgetSize size;

  const _HeatmapFooter({
    required this.isDark,
    required this.primaryColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Learn how we\ncount contributions',
            style: TextStyle(
              fontSize: size.getLegendFontSize(),
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
              decoration: TextDecoration.underline,
            ),
          ),
          Row(
            children: [
              Text(
                'Less',
                style: TextStyle(
                  fontSize: size.getLegendFontSize(),
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  _LegendBox(color: isDark ? const Color(0xFF374151) : const Color(0xFFE0F2FE)),
                  const SizedBox(width: 4),
                  _LegendBox(color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0EA5E9)),
                  const SizedBox(width: 4),
                  _LegendBox(color: isDark ? const Color(0xFF0369A1) : primaryColor),
                  const SizedBox(width: 4),
                  _LegendBox(color: isDark ? const Color(0xFF0EA5E9) : const Color(0xFF7DD3FC)),
                ],
              ),
              const SizedBox(width: 4),
              Text(
                'More',
                style: TextStyle(
                  fontSize: size.getLegendFontSize(),
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 图例方块
class _LegendBox extends StatelessWidget {
  final Color color;

  const _LegendBox({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// 显示更多按钮
class _ShowMoreButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final HomeWidgetSize size;

  const _ShowMoreButton({
    required this.label,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: size.getSubtitleFontSize(),
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }
}
