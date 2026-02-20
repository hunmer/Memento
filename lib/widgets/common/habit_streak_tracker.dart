import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 连续打卡追踪器
///
/// 用于展示打卡的连续天数、最长连续天数和完成状态。
/// 支持动画效果，包含进入动画和网格逐项动画。
/// 根据 HomeWidgetSize 自动调整所有元素的大小。
class HabitStreakTracker extends StatefulWidget {
  /// 当前连续天数
  final int currentStreak;

  /// 最长连续天数
  final int longestStreak;

  /// 总天数
  final int totalDays;

  /// 已完成的天数列表
  final List<int> completedDays;

  /// 主题颜色（默认使用靛蓝色）
  final Color? primaryColor;

  /// 背景颜色（默认自动适配深色/浅色模式）
  final Color? backgroundColor;

  /// 卡片宽度（默认 340）
  final double? width;

  /// 卡片内边距（默认 32）
  final EdgeInsetsGeometry? padding;

  /// 卡片圆角（默认 28）
  final double? borderRadius;

  /// 是否显示阴影（默认 true）
  final bool showShadow;

  /// 标题文本（默认 'Weekly Streak'）
  final String? titleText;

  /// 最长连续标签文本（默认 'Longest Streak'）
  final String? longestStreakLabel;

  /// 小组件尺寸（用于调整所有元素大小）
  final HomeWidgetSize size;

  const HabitStreakTracker({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDays,
    required this.completedDays,
    this.primaryColor,
    this.backgroundColor,
    this.width,
    this.padding,
    this.borderRadius,
    this.showShadow = true,
    this.titleText,
    this.longestStreakLabel,
    this.size = const MediumSize(),
  });

  @override
  State<HabitStreakTracker> createState() => _HabitStreakTrackerState();
}

class _HabitStreakTrackerState extends State<HabitStreakTracker>
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
            child: _buildContent(isDark),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isDark) {
    final effectiveBackgroundColor =
        widget.backgroundColor ??
        (isDark ? const Color(0xFF27272A) : Colors.white);
    final effectivePrimaryColor =
        widget.primaryColor ?? const Color(0xFF3f51b5);
    final size = widget.size;

    // 根据尺寸获取各个值
    final titleFontSize = size.getSubtitleFontSize();
    final largeFontSize = size.getLargeFontSize() * 0.6; // 约 28-34px
    const smallSpacing = 4.0;
    final mediumSpacing = size.getSmallSpacing() * 2; // 约 8-12px
    final largeSpacing = size.getItemSpacing(); // 约 8-16px
    final strokeWidth = size.getStrokeWidth() * 0.25; // 约 2-3px
    final dayFontSize = size.getLegendFontSize() * 1.0; // 约 10-14px
    final iconSize = size.getIconSize() * 0.7; // 约 16-20px

    return Container(
      width: widget.width ?? 340,
      padding: widget.padding ?? size.getPadding(),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? size.getIconSize() * 0.8,
        ),
        boxShadow:
            widget.showShadow
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: size.getIconSize(),
                    offset: Offset(0, mediumSpacing),
                  ),
                ]
                : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
            children: [
              // 当前连续打卡
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titleText ?? 'Weekly Streak',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: smallSpacing),
                  AnimatedFlipCounter(
                    value: widget.currentStreak * _animation.value,
                    suffix: ' Days',
                    textStyle: TextStyle(
                      fontSize: largeFontSize,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
              SizedBox(height: largeSpacing),

              // 分隔线
              Container(
                height: strokeWidth,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                      width: strokeWidth,
                    ),
                  ),
                ),
              ),
              SizedBox(height: largeSpacing),

              // 最长连续打卡
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.longestStreakLabel ?? 'Longest Streak',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${widget.longestStreak} days',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // 日期网格
              _buildDaysGrid(
                isDark,
                effectivePrimaryColor,
                dayFontSize,
                iconSize,
              ),
            ],
          ),
    );
  }

  Widget _buildDaysGrid(
    bool isDark,
    Color primaryColor,
    double dayFontSize,
    double iconSize,
  ) {
    // 计算延迟步长，确保 Interval end <= 1.0
    final elementCount = widget.totalDays;
    final baseEnd = 0.6;
    final maxStep = (1.0 - baseEnd) / (elementCount - 1);
    final step = maxStep * 0.8; // 留安全余量

    // 根据尺寸计算间距
    final size = widget.size;
    final itemSpacing = size.getSmallSpacing();

    // 计算每一天圆形的尺寸（基于可用宽度和总天数）
    final daySize = dayFontSize * 2 + iconSize; // 动态计算大小

    return Expanded(
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // 横向滚动
        itemCount: widget.totalDays,
        itemBuilder: (context, index) {
          final dayNumber = index + 1;
          final isCompleted = widget.completedDays.contains(dayNumber);
          final isCurrent = dayNumber <= widget.currentStreak;

          // 计算每个元素的延迟动画
          final itemAnimation = CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * step,
              baseEnd + index * step,
              curve: Curves.easeOutCubic,
            ),
          );

          return Padding(
            padding: EdgeInsets.only(
              right: index < widget.totalDays - 1 ? itemSpacing : 0,
            ),
            child: SizedBox(
              width: daySize,
              child: _DayItem(
                dayNumber: dayNumber,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                primaryColor: primaryColor,
                isDark: isDark,
                animation: itemAnimation,
                dayFontSize: dayFontSize,
                iconSize: iconSize,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 日期单项组件
class _DayItem extends StatelessWidget {
  final int dayNumber;
  final bool isCompleted;
  final bool isCurrent;
  final Color primaryColor;
  final bool isDark;
  final Animation<double> animation;
  final double dayFontSize;
  final double iconSize;

  const _DayItem({
    required this.dayNumber,
    required this.isCompleted,
    required this.isCurrent,
    required this.primaryColor,
    required this.isDark,
    required this.animation,
    required this.dayFontSize,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animation.value),
          child: Opacity(opacity: animation.value, child: _buildContent()),
        );
      },
    );
  }

  Widget _buildContent() {
    const smallSpacing = 2.0;
    final strokeWidth = dayFontSize * 0.15; // 约 1.5-2px

    if (isCurrent && isCompleted) {
      // 已完成 - 实心圆
      return Container(
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: iconSize * 0.2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNumber.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: dayFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: smallSpacing),
            Icon(Icons.check_circle, color: Colors.white, size: iconSize),
          ],
        ),
      );
    } else if (isCompleted) {
      // 已完成但不在当前连续中
      return Container(
        decoration: BoxDecoration(
          color:
              isDark
                  ? Colors.grey.shade700.withOpacity(0.5)
                  : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNumber.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: dayFontSize,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade900,
              ),
            ),
            SizedBox(height: smallSpacing),
            Icon(
              Icons.check_circle,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade300,
              size: iconSize,
            ),
          ],
        ),
      );
    } else {
      // 未完成 - 虚线边框
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            width: strokeWidth,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNumber.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: dayFontSize,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
            SizedBox(height: smallSpacing),
            Icon(
              Icons.check_circle,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              size: iconSize,
            ),
          ],
        ),
      );
    }
  }
}
