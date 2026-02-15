import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 每周水平数据模型
///
/// 用于表示某一天的水平值（如压力、情绪等）
class WeeklyLevelData {
  /// 星期几标签（如 'Mon', 'Tue' 等）
  final String day;

  /// 水平值 (0.0 - 1.0)
  final double value;

  /// 是否被选中
  final bool isSelected;

  const WeeklyLevelData({
    required this.day,
    required this.value,
    required this.isSelected,
  });

  /// 从 JSON 创建
  factory WeeklyLevelData.fromJson(Map<String, dynamic> json) {
    return WeeklyLevelData(
      day: json['day'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'value': value,
      'isSelected': isSelected,
    };
  }

  /// 创建副本
  WeeklyLevelData copyWith({
    String? day,
    double? value,
    bool? isSelected,
  }) {
    return WeeklyLevelData(
      day: day ?? this.day,
      value: value ?? this.value,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// 水平监测卡片组件
///
/// 用于展示水平值（如压力、情绪等）的监测卡片，支持动画效果和主题适配。
/// 显示当前分数、状态描述和一周水平值的柱状图。
///
/// 使用示例：
/// ```dart
/// LevelMonitorCard(
///   title: 'Stress Level',
///   icon: Icons.error_outline,
///   currentScore: 4.2,
///   status: 'Stressed Out',
///   weeklyData: [
///     WeeklyLevelData(day: 'Mon', value: 0.45, isSelected: false),
///     WeeklyLevelData(day: 'Tue', value: 0.25, isSelected: false),
///     // ... 更多数据
///   ],
///   onTodayTap: () => print('Today tapped'),
///   onBarTap: (index, data) => print('Bar $index tapped'),
/// )
/// ```
class LevelMonitorCard extends StatefulWidget {
  /// 标题
  final String title;

  /// 图标
  final IconData icon;

  /// 当前分数
  final double currentScore;

  /// 状态描述
  final String status;

  /// 分数单位（如 'pts'）
  final String scoreUnit;

  /// 一周数据
  final List<WeeklyLevelData> weeklyData;

  /// "Today" 按钮点击回调
  final VoidCallback? onTodayTap;

  /// 柱状图点击回调
  final void Function(int index, WeeklyLevelData data)? onBarTap;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

  const LevelMonitorCard({
    super.key,
    required this.title,
    required this.icon,
    required this.currentScore,
    required this.status,
    required this.weeklyData,
    this.scoreUnit = 'pts',
    this.onTodayTap,
    this.onBarTap,
    this.inline = false,
    this.size = const MediumSize(),
  });

  @override
  State<LevelMonitorCard> createState() => _LevelMonitorCardState();
}

class _LevelMonitorCardState extends State<LevelMonitorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scoreAnimation;
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _scoreAnimation = Tween<double>(begin: 0.0, end: widget.currentScore).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // 为每个进度条创建动画
    _barAnimations = List.generate(
      widget.weeklyData.length,
      (index) => Tween<double>(begin: 0.0, end: widget.weeklyData[index].value)
          .animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.2 + (index * 0.1),
            0.8 + (index * 0.03),
            curve: Curves.easeOut,
          ),
        ),
      ),
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
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
            child: _buildContent(isDark),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isDark) {
    final backgroundColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = isDark
        ? primaryColor.withOpacity(0.15)
        : primaryColor.withOpacity(0.1);

    return Container(
      width: widget.inline ? double.maxFinite : 380,
      padding: widget.size.getPadding(),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          _buildHeader(isDark, primaryColor, surfaceColor),
          SizedBox(height: widget.size.getTitleSpacing()),

          // 分数和进度条在同一行
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 当前分数和状态
              Flexible(
                flex: 3,
                child: _buildScoreSection(isDark, primaryColor),
              ),
              const SizedBox(width: 8),
              // 每周进度条靠右
              Flexible(
                flex: 7,
                child: _buildWeeklyBars(isDark, primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primaryColor, Color surfaceColor) {
    final iconSize = widget.size.getIconSize();
    final containerSize = iconSize * widget.size.iconContainerScale;

    return Row(
      children: [
        // 左侧图标和标题区域
        Expanded(
          child: Row(
            children: [
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: primaryColor,
                  size: iconSize,
                ),
              ),
              SizedBox(width: widget.size.getItemSpacing()),
              Flexible(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: widget.size.getTitleFontSize(),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Today 按钮
        InkWell(
          onTap: widget.onTodayTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.size.getItemSpacing(),
              vertical: widget.size.getItemSpacing() / 2,
            ),
            child: Row(
              children: [
                Text(
                  'Today',
                  style: TextStyle(
                    fontSize: widget.size.getLegendFontSize(),
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                SizedBox(width: widget.size.getItemSpacing()),
                Icon(
                  Icons.chevron_right,
                  size: iconSize * 0.8,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection(bool isDark, Color primaryColor) {
    final scoreFontSize = widget.size.getLargeFontSize() * 0.7;
    final unitFontSize = widget.size.getLargeFontSize() * 0.35;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedBuilder(
              animation: _scoreAnimation,
              builder: (context, child) {
                return AnimatedFlipCounter(
                  value: _scoreAnimation.value,
                  fractionDigits: 1,
                  textStyle: TextStyle(
                    fontSize: scoreFontSize,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                );
              },
            ),
            SizedBox(width: widget.size.getItemSpacing()),
            Padding(
              padding: EdgeInsets.only(bottom: widget.size.getItemSpacing()),
              child: Text(
                widget.scoreUnit,
                style: TextStyle(
                  fontSize: unitFontSize,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: widget.size.getItemSpacing()),
        Flexible(
          child: Text(
            widget.status,
            style: TextStyle(
              fontSize: widget.size.getSubtitleFontSize(),
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyBars(bool isDark, Color primaryColor) {
    // 计算所有柱子的总宽度
    final barWidth = widget.size.getBarWidth();
    final barSpacing = widget.size.getItemSpacing();
    final totalBarWidth = (barWidth + barSpacing) * widget.weeklyData.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        // 如果总宽度不超过最大宽度，不需要滚动
        if (totalBarWidth <= maxWidth) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.weeklyData.length, (index) {
              final data = widget.weeklyData[index];
              return _WeeklyBar(
                day: data.day.substring(0, 1),
                value: data.value,
                animation: _barAnimations[index],
                isSelected: data.isSelected,
                primaryColor: primaryColor,
                isDark: isDark,
                onTap: () => widget.onBarTap?.call(index, data),
                size: widget.size,
              );
            }),
          );
        }

        // 需要滚动，设置固定宽度以触发滚动
        return SizedBox(
          width: maxWidth,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.weeklyData.length, (index) {
                final data = widget.weeklyData[index];
                return _WeeklyBar(
                  day: data.day.substring(0, 1),
                  value: data.value,
                  animation: _barAnimations[index],
                  isSelected: data.isSelected,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => widget.onBarTap?.call(index, data),
                  size: widget.size,
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// 每周进度条单项
class _WeeklyBar extends StatelessWidget {
  final String day;
  final double value;
  final Animation<double> animation;
  final bool isSelected;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback? onTap;
  final HomeWidgetSize size;

  const _WeeklyBar({
    required this.day,
    required this.value,
    required this.animation,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFE5E7EB);
    final barWidth = size.getBarWidth();
    final barHeight = size.getLargeFontSize() * 1.15;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: size.getItemSpacing() / 2),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      height: barHeight * animation.value,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.getItemSpacing()),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: size.getLegendFontSize(),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.grey.shade900)
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
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
