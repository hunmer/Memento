import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

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
/// 日期范围选择器以及带有平均值参考线的柱状图。
///
/// 特性：
/// - 动画数字计数器（使用 AnimatedFlipCounter）
/// - 柱状图独立延迟动画
/// - 平均值参考线
/// - 日期切换按钮（周/月/年）
/// - 深色模式适配
/// - 可选某一天查看详情
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
///   onTimePeriodChanged: (period) {
///     print('切换到: $period');
///   },
///   onDaySelected: (index, data) {
///     print('选中第 $index 天: ${data.day}');
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

  /// 卡片宽度（默认为 380）
  final double? width;

  /// 卡片高度（默认为 500）
  final double? height;

  /// 时间切换按钮回调
  final ValueChanged<String>? onTimePeriodChanged;

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
    this.width,
    this.height,
    this.onTimePeriodChanged,
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
      final maxSteps =
          widget.dailyData.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
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

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
            child: Container(
              width: widget.width ?? 380,
              height: widget.height ?? 500,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题栏
                    _buildHeader(context, isDark, primaryColor),
                    const SizedBox(height: 24),
                    // 总步数和时间切换
                    _buildTotalSection(context, isDark, primaryColor),
                    const SizedBox(height: 24),
                    // 柱状图区域（包含平均值参考线）
                    _buildChartSection(context, isDark, primaryColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建标题栏
  Widget _buildHeader(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        if (widget.onMenuPressed != null)
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            onPressed: widget.onMenuPressed,
          ),
      ],
    );
  }

  /// 构建总数和时间切换区域
  Widget _buildTotalSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 40,
                child: OverflowBox(
                  maxWidth: 140,
                  child: Center(
                    child: AnimatedFlipCounter(
                      value: widget.totalSteps.toDouble() * _counterAnimation.value,
                      fractionDigits: 0,
                      textStyle: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF3F4F6)
                            : const Color(0xFF111827),
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 17,
                child: Text(
                  'steps',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.dateRange,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        // 时间切换按钮
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(child: _buildTimeButton('Week', true, isDark)),
              Expanded(child: _buildTimeButton('Month', false, isDark)),
              Expanded(child: _buildTimeButton('Year', false, isDark)),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建时间切换按钮
  Widget _buildTimeButton(String label, bool isSelected, bool isDark) {
    return InkWell(
      onTap: () => widget.onTimePeriodChanged?.call(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? isDark
                      ? const Color(0xFF374151)
                      : Colors.white
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? isDark
                      ? Colors.white
                      : const Color(0xFF111827)
                  : isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建柱状图区域
  Widget _buildChartSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    final maxSteps = widget.dailyData
        .map((d) => d.steps)
        .reduce((a, b) => a > b ? a : b);
    final chartHeight = 200.0;
    final textHeight = 24.0;
    final barAvailableHeight = chartHeight - textHeight;
    final averageLineTop =
        (1 - widget.averageSteps / maxSteps) * barAvailableHeight;

    return SizedBox(
      height: chartHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 柱状图
          Padding(
            padding: const EdgeInsets.only(left: 85),
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
              ),
            ),
          ),
          // 平均值参考线
          Positioned(
            top: averageLineTop,
            left: 0,
            right: 0,
            child: _buildAverageLine(context, isDark, primaryColor),
          ),
        ],
      ),
    );
  }

  /// 构建平均值参考线
  Widget _buildAverageLine(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 16,
                    child: OverflowBox(
                      maxWidth: 40,
                      child: Center(
                        child: AnimatedFlipCounter(
                          value:
                              widget.averageSteps.toDouble() *
                              _counterAnimation.value,
                          fractionDigits: 0,
                          textStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? const Color(0xFFF3F4F6)
                                    : const Color(0xFF111827),
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  SizedBox(
                    height: 12,
                    child: Text(
                      'steps',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color:
                            isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              border: Border.all(
                color: primaryColor.withOpacity(0.4),
                width: 2,
              ),
            ),
          ),
        ),
      ],
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
  });

  @override
  Widget build(BuildContext context) {
    // 预留文字高度（12 + 12 = 24）
    final maxHeight = availableHeight - 24;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(dailyData.length, (index) {
        final data = dailyData[index];
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

        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(index),
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              maxHeight: availableHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: barAnimation,
                    builder: (context, child) {
                      return Container(
                        constraints: BoxConstraints(maxHeight: maxHeight),
                        height: barHeight * barAnimation.value,
                        width: 20,
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
                          borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 12),
                  Text(
                    data.day,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
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
          ),
        );
      }),
    );
  }
}
