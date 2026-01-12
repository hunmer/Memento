import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 月度数据模型
class MonthlyData {
  final String month;
  final double value; // 0-100 的百分比

  const MonthlyData({
    required this.month,
    required this.value,
  });
}

/// 月度柱状图统计小组件
///
/// 用于展示全年12个月的数据趋势,高亮显示当前月份。
/// 支持动画效果、深色模式、自定义颜色等配置。
///
/// 使用示例:
/// ```dart
/// MonthlyBarChartCard(
///   totalValue: 890.93,
///   currentMonth: 5, // June (0-indexed)
///   monthlyData: [
///     MonthlyData(month: 'Jan', value: 35),
///     MonthlyData(month: 'Feb', value: 60),
///     // ... 其他月份
///   ],
/// )
/// ```
class MonthlyBarChartCard extends StatefulWidget {
  /// 总数值,显示在卡片顶部
  final double totalValue;

  /// 当前月份索引 (0-11)
  final int currentMonth;

  /// 月度数据列表
  final List<MonthlyData> monthlyData;

  /// 数值前缀(如货币符号)
  final String? prefix;

  /// 数值后缀
  final String? suffix;

  /// 小数位数
  final int fractionDigits;

  /// 主色调,默认使用主题色
  final Color? primaryColor;

  /// 卡片宽度,默认280
  final double? width;

  /// 卡片内边距,默认24
  final EdgeInsetsGeometry? padding;

  /// 圆角半径,默认24
  final double? borderRadius;

  /// 是否显示Max线
  final bool showMaxLine;

  const MonthlyBarChartCard({
    super.key,
    required this.totalValue,
    required this.currentMonth,
    required this.monthlyData,
    this.prefix,
    this.suffix,
    this.fractionDigits = 2,
    this.primaryColor,
    this.width,
    this.padding,
    this.borderRadius,
    this.showMaxLine = true,
  });

  @override
  State<MonthlyBarChartCard> createState() => _MonthlyBarChartCardState();
}

class _MonthlyBarChartCardState extends State<MonthlyBarChartCard>
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
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final primaryColor = widget.primaryColor ??
        (isDark ? const Color(0xFF4FC3F7) : Theme.of(context).colorScheme.primary);
    final barBackgroundColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E7EB);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.width,
              padding: widget.padding ?? const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 24),
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
                children: [
                  // 标题和图标
                  _buildHeader(context, isDark, primaryColor),
                  const SizedBox(height: 32),

                  // 柱状图
                  SizedBox(
                    height: 224,
                    child: Stack(
                      children: [
                        // Max 线
                        if (widget.showMaxLine)
                          _buildMaxLine(context, isDark),
                        // 柱状图
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _BarChart(
                            data: widget.monthlyData,
                            currentMonth: widget.currentMonth,
                            animation: _animation,
                            primaryColor: primaryColor,
                            barBackgroundColor: barBackgroundColor,
                            isDark: isDark,
                          ),
                        ),
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

  Widget _buildHeader(BuildContext context, bool isDark, Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: AnimatedFlipCounter(
            value: widget.totalValue * _animation.value,
            fractionDigits: widget.fractionDigits,
            prefix: widget.prefix ?? '\$',
            suffix: widget.suffix ?? '',
            textStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.bar_chart,
            color: primaryColor,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildMaxLine(BuildContext context, bool isDark) {
    return Positioned(
      top: 22,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 2,
              color: isDark
                  ? Colors.grey.shade700
                  : const Color(0xFFD1D5DB).withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Max',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 柱状图组件
class _BarChart extends StatelessWidget {
  final List<MonthlyData> data;
  final int currentMonth;
  final Animation<double> animation;
  final Color primaryColor;
  final Color barBackgroundColor;
  final bool isDark;

  const _BarChart({
    required this.data,
    required this.currentMonth,
    required this.animation,
    required this.primaryColor,
    required this.barBackgroundColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (index) {
          final item = data[index];
          final isCurrentMonth = index == currentMonth;

          // 为每个柱子创建延迟动画,确保 end <= 1.0
          final step = 0.04;
          final barAnimation = CurvedAnimation(
            parent: animation,
            curve: Interval(
              index * step,
              0.5 + index * step,
              curve: Curves.easeOutCubic,
            ),
          );

          return _BarItem(
            month: item.month,
            value: item.value,
            isCurrentMonth: isCurrentMonth,
            animation: barAnimation,
            primaryColor: primaryColor,
            barBackgroundColor: barBackgroundColor,
            isDark: isDark,
          );
        }),
      ),
    );
  }
}

/// 单个柱子组件
class _BarItem extends StatelessWidget {
  final String month;
  final double value;
  final bool isCurrentMonth;
  final Animation<double> animation;
  final Color primaryColor;
  final Color barBackgroundColor;
  final bool isDark;

  const _BarItem({
    required this.month,
    required this.value,
    required this.isCurrentMonth,
    required this.animation,
    required this.primaryColor,
    required this.barBackgroundColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animatedValue = value * animation.value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 柱子
              Container(
                width: 16,
                height: 140 * animatedValue / 100,
                decoration: BoxDecoration(
                  color: isCurrentMonth ? primaryColor : barBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  boxShadow: isCurrentMonth
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              // 月份标签
              SizedBox(
                width: 32,
                child: Text(
                  month,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.w500,
                    color: isCurrentMonth
                        ? primaryColor
                        : (isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
