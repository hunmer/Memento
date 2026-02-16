import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 每日步数数据模型
///
/// 表示单日的步数数据，包含日期简写、完整日期、步数、
/// 百分比变化（可选）和选中状态。
class DailyStepData {
  /// 日期简写（如 "Mon", "Tue"）
  final String day;

  /// 步数
  final int steps;

  /// 完整日期（如 "17 Jun 2024"）
  final String date;

  /// 百分比变化（如 "+2,4%"）
  final String? percentage;

  /// 是否选中
  final bool isSelected;

  const DailyStepData({
    required this.day,
    required this.steps,
    required this.date,
    this.percentage,
    this.isSelected = false,
  });

  /// 从 JSON 创建
  factory DailyStepData.fromJson(Map<String, dynamic> json) {
    return DailyStepData(
      day: json['day'] as String? ?? '',
      steps: json['steps'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      percentage: json['percentage'] as String?,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'steps': steps,
      'date': date,
      'percentage': percentage,
      'isSelected': isSelected,
    };
  }
}

/// 每周步数进度卡片组件
///
/// 显示一周内的每日步数统计，包含总步数、平均值、
/// 日期范围以及带有平均值参考线的柱状图。
///
/// 特性：
/// - 动画数字计数器（使用 AnimatedFlipCounter）
/// - 柱状图独立延迟动画
/// - 平均值参考线
/// - 深色模式适配
/// - 可选某一天查看详情
/// - 根据尺寸自动调整所有元素大小
///
/// 示例用法：
/// ```dart
/// WeeklyStepsProgressCard(
///   title: 'Steps',
///   totalSteps: 16254,
///   dateRange: '17-23 Jun 2024',
///   averageSteps: 6028,
///   dailyData: [
///     DailyStepData(
///       day: 'Mon',
///       steps: 4500,
///       date: '17 Jun 2024',
///     ),
///     DailyStepData(
///       day: 'Fri',
///       steps: 12800,
///       date: '21 Jun 2024',
///       percentage: '+2,4%',
///       isSelected: true,
///     ),
///   ],
///   onDaySelected: (index) {
///     print('选中第 $index 天');
///   },
/// )
/// ```
class WeeklyStepsProgressCard extends StatefulWidget {
  /// 卡片标题（默认为 "Steps"）
  final String title;

  /// 总步数
  final int totalSteps;

  /// 日期范围显示文本
  final String dateRange;

  /// 平均步数
  final int averageSteps;

  /// 每日数据列表
  final List<DailyStepData> dailyData;

  /// 图标（默认为 Icons.directions_walk）
  final IconData? icon;

  /// 小组件尺寸（默认为 MediumSize）
  final HomeWidgetSize size;

  /// 日期选择回调
  final ValueChanged<int>? onDaySelected;

  /// 菜单按钮回调
  final VoidCallback? onMenuPressed;

  const WeeklyStepsProgressCard({
    super.key,
    this.title = 'Steps',
    required this.totalSteps,
    required this.dateRange,
    required this.averageSteps,
    required this.dailyData,
    this.icon,
    this.size = const MediumSize(),
    this.onDaySelected,
    this.onMenuPressed,
  });

  @override
  State<WeeklyStepsProgressCard> createState() =>
      _WeeklyStepsProgressCardState();
}

class _WeeklyStepsProgressCardState extends State<WeeklyStepsProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _counterAnimation;

  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _counterAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    // 默认选中最高的步数日期
    if (widget.dailyData.any((d) => d.isSelected)) {
      _selectedIndex = widget.dailyData.indexWhere((d) => d.isSelected);
    } else {
      final maxSteps = widget.dailyData
          .map((d) => d.steps)
          .reduce((a, b) => a > b ? a : b);
      _selectedIndex = widget.dailyData.indexWhere((d) => d.steps == maxSteps);
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectDay(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onDaySelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final size = widget.size;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: size.getPadding(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题栏
                        _buildHeader(context, isDark, primaryColor, size),
                        SizedBox(height: size.getTitleSpacing()),
                        // 总步数和时间切换
                        _buildTotalSection(context, isDark, primaryColor, size),
                        SizedBox(height: size.getTitleSpacing()),
                        // 柱状图区域（不含平均值参考线）
                        _buildChartSection(context, isDark, primaryColor, size),
                      ],
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

  /// 构建标题栏
  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    HomeWidgetSize size,
  ) {
    final iconSize = size.getIconSize();
    final containerSize = iconSize * size.iconContainerScale;
    final titleFontSize = size.getTitleFontSize();
    final labelFontSize = size.getSubtitleFontSize();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon ?? Icons.directions_walk,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(width: size.getSmallSpacing() * 3),
              Flexible(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? const Color(0xFFF3F4F6)
                            : const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.dateRange,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (widget.onMenuPressed != null) ...[
              SizedBox(width: size.getSmallSpacing()),
              IconButton(
                icon: Icon(
                  Icons.more_horiz,
                  color:
                      isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                ),
                onPressed: widget.onMenuPressed,
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 构建总数区域
  Widget _buildTotalSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    HomeWidgetSize size,
  ) {
    final valueFontSize = size.getLargeFontSize() * 0.75; // 约 27/36/42
    final labelFontSize = size.getSubtitleFontSize();

    return SizedBox(
      height: valueFontSize,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: valueFontSize * 4,
            height: valueFontSize,
            child: OverflowBox(
              maxWidth: valueFontSize * 4,
              child: Center(
                child: AnimatedFlipCounter(
                  value: widget.totalSteps.toDouble() * _counterAnimation.value,
                  fractionDigits: 0,
                  textStyle: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? const Color(0xFFF3F4F6)
                            : const Color(0xFF111827),
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          Text(
            'steps',
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建柱状图区域
  Widget _buildChartSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    HomeWidgetSize size,
  ) {
    final maxSteps = widget.dailyData
        .map((d) => d.steps)
        .reduce((a, b) => a > b ? a : b);
    final chartHeight =
        size.getHeightConstraints().maxHeight * 0.5; // 图表高度约为最大高度的一半

    return Expanded(
      child: SizedBox(
        height: chartHeight,
        child: Padding(
          padding: EdgeInsets.only(left: size.getLegendFontSize() * 8),
          child: SizedBox(
            height: chartHeight,
            child: _StepsBars(
              dailyData: widget.dailyData,
              animation: _fadeAnimation,
              selectedIndex: _selectedIndex ?? 0,
              maxSteps: maxSteps,
              averageSteps: widget.averageSteps,
              onTap: _selectDay,
              isDark: isDark,
              primaryColor: primaryColor,
              availableHeight: chartHeight,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}

/// 柱状图组件（私有）
class _StepsBars extends StatelessWidget {
  final List<DailyStepData> dailyData;
  final Animation<double> animation;
  final int selectedIndex;
  final int maxSteps;
  final int averageSteps;
  final Function(int) onTap;
  final bool isDark;
  final Color primaryColor;
  final double availableHeight;
  final HomeWidgetSize size;

  const _StepsBars({
    required this.dailyData,
    required this.animation,
    required this.selectedIndex,
    required this.maxSteps,
    required this.averageSteps,
    required this.onTap,
    required this.isDark,
    required this.primaryColor,
    required this.availableHeight,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final barWidth = size.getBarWidth();
    final legendFontSize = size.getLegendFontSize();
    // 根据是否显示底部文本来计算最大高度
    final showBottomText = size is WideSize || size is Wide2Size;
    // 底部预留空间：间距 + 文本高度
    final bottomSpace = showBottomText ? legendFontSize * 2.5 : 0;
    // 确保柱子最大高度不超过可用空间减去底部空间
    final maxHeight = (availableHeight - bottomSpace).clamp(
      0.0,
      availableHeight,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int index = 0; index < dailyData.length; index++) ...[
          Expanded(
            child: _buildBar(
              dailyData[index],
              index,
              maxHeight,
              barWidth,
              legendFontSize,
              showBottomText,
              isDark,
              primaryColor,
            ),
          ),
          if (index < dailyData.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }

  Widget _buildBar(
    DailyStepData data,
    int index,
    double maxHeight,
    double barWidth,
    double legendFontSize,
    bool showBottomText,
    bool isDark,
    Color primaryColor,
  ) {
    final barHeight = (data.steps / maxSteps) * maxHeight;
    final isSelected = index == selectedIndex;

    // 错开动画
    final step = 0.08;
    final barAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        index * step,
        0.5 + index * step,
        curve: Curves.easeOutCubic,
      ),
    );

    return GestureDetector(
      onTap: () => onTap(index),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight + (showBottomText ? legendFontSize * 2 : 0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 柱子使用 Flexible，会自动适应可用空间
            Flexible(
              child: AnimatedBuilder(
                animation: barAnimation,
                builder: (context, child) {
                  return Container(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    height: barHeight * barAnimation.value,
                    width: barWidth,
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? null
                              : LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors:
                                    isDark
                                        ? [
                                          const Color(0xFFFFD89E),
                                          const Color(0xFFA66C1E),
                                        ]
                                        : [
                                          const Color(0xFFFFD89E),
                                          const Color(0xFFFFF0D9),
                                        ],
                              ),
                      color: isSelected ? primaryColor : null,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(barWidth / 2),
                        topRight: Radius.circular(barWidth / 2),
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                              : null,
                    ),
                  );
                },
              ),
            ),
            // 文本始终在下方，固定显示
            if (showBottomText) SizedBox(height: legendFontSize * 0.5),
            if (showBottomText)
              Text(
                data.day,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: legendFontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected
                          ? isDark
                              ? const Color(0xFFF3F4F6)
                              : const Color(0xFF111827)
                          : isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
