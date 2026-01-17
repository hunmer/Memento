import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 支出对比图表卡片
///
/// 用于展示支出对比的卡片组件，支持：
/// - 本月支出金额显示（带动画计数）
/// - 变化百分比徽章
/// - 双数据系列柱状图（上月 vs 本月）
/// - 深色/浅色主题适配
class ExpenseComparisonChartCardWidget extends StatefulWidget {
  /// 标题文本
  final String title;

  /// 本月金额
  final double currentAmount;

  /// 单位
  final String unit;

  /// 变化百分比
  final double changePercent;

  /// 日数据列表
  final List<DailyExpenseDataModel> dailyData;

  /// Y轴最大值
  final double maxValue;

  /// X轴标签列表（自定义图例）
  final List<String> labels;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 组件尺寸
  final HomeWidgetSize size;

  const ExpenseComparisonChartCardWidget({
    super.key,
    required this.title,
    required this.currentAmount,
    required this.unit,
    required this.changePercent,
    required this.dailyData,
    this.maxValue = 24.0,
    this.labels = const [],
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于小组件系统）
  factory ExpenseComparisonChartCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final dailyDataList = (props['dailyData'] as List<dynamic>?);
    final dailyData = dailyDataList?.map((item) {
      final map = item as Map<String, dynamic>;
      return DailyExpenseDataModel(
        lastMonth: (map['lastMonth'] as num).toDouble(),
        currentMonth: (map['currentMonth'] as num).toDouble(),
      );
    }).toList() ?? [];

    final labelsList = (props['labels'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return ExpenseComparisonChartCardWidget(
      title: props['title'] as String? ?? '本月支出',
      currentAmount: (props['currentAmount'] as num?)?.toDouble() ?? 0.0,
      unit: props['unit'] as String? ?? '',
      changePercent: (props['changePercent'] as num?)?.toDouble() ?? 0.0,
      dailyData: dailyData,
      maxValue: (props['maxValue'] as num?)?.toDouble() ?? 24.0,
      labels: labelsList,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

  @override
  State<ExpenseComparisonChartCardWidget> createState() =>
      _ExpenseComparisonChartCardWidgetState();
}

class _ExpenseComparisonChartCardWidgetState
    extends State<ExpenseComparisonChartCardWidget>
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 400,
              padding: widget.size.getPadding(),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和金额
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          SizedBox(height: widget.size.getItemSpacing()),
                          SizedBox(
                            height: 48,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AnimatedFlipCounter(
                                  value: widget.currentAmount * _animation.value,
                                  fractionDigits: 2,
                                  textStyle: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.unit,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 图例
                          Row(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF475569)
                                          : const Color(0xFFDBEAFE),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    '上月',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: widget.size.getItemSpacing() * 2),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    '本月',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFFD1D5DB)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: widget.size.getItemSpacing()),
                          // 变化百分比
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0x33EF4444)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              children: [
                                Transform.rotate(
                                  angle: -0.785, // -45度
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: isDark
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                                SizedBox(width: widget.size.getItemSpacing() / 4),
                                Text(
                                  '+${widget.changePercent}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: widget.size.getTitleSpacing()),
                  // 柱状图
                  _BarChartWidget(
                    data: widget.dailyData,
                    maxValue: widget.maxValue,
                    labels: widget.labels,
                    animation: _animation,
                    isDark: isDark,
                    primaryColor: primaryColor,
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

/// 日支出数据模型
class DailyExpenseDataModel {
  final double lastMonth;
  final double currentMonth;

  const DailyExpenseDataModel({
    required this.lastMonth,
    required this.currentMonth,
  });

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'lastMonth': lastMonth,
      'currentMonth': currentMonth,
    };
  }

  /// 从 Map 创建
  factory DailyExpenseDataModel.fromMap(Map<String, dynamic> map) {
    return DailyExpenseDataModel(
      lastMonth: (map['lastMonth'] as num).toDouble(),
      currentMonth: (map['currentMonth'] as num).toDouble(),
    );
  }
}

/// 柱状图组件
class _BarChartWidget extends StatelessWidget {
  final List<DailyExpenseDataModel> data;
  final double maxValue;
  final List<String> labels;
  final Animation<double> animation;
  final bool isDark;
  final Color primaryColor;

  const _BarChartWidget({
    required this.data,
    required this.maxValue,
    required this.labels,
    required this.animation,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 柱状图主体
        SizedBox(
          height: 128,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(data.length, (index) {
              final barAnimation = CurvedAnimation(
                parent: animation,
                curve: Interval(
                  index * 0.015,
                  0.5 + index * 0.015,
                  curve: Curves.easeOutCubic,
                ),
              );
              return Expanded(
                child: _BarItemWidget(
                  lastMonth: data[index].lastMonth,
                  currentMonth: data[index].currentMonth,
                  maxValue: maxValue,
                  animation: barAnimation,
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
              );
            }),
          ),
        ),
        // X轴标签
        const SizedBox(height: 12),
        if (labels.isEmpty)
          // 默认固定标签
          SizedBox(
            height: 24,
            child: Stack(
              children: [
                Positioned(left: 0, top: 0, child: _buildLabel('01')),
                Positioned(left: 0.16, top: 0, child: _buildLabel('05')),
                Positioned(left: 0.33, top: 0, child: _buildLabel('10')),
                Positioned(left: 0.5, top: 0, child: _buildLabel('15')),
                Positioned(left: 0.66, top: 0, child: _buildLabel('20')),
                Positioned(left: 0.83, top: 0, child: _buildLabel('25')),
                Positioned(right: 0, top: 0, child: _buildLabel('30')),
              ],
            ),
          )
        else
          // 自定义标签（均匀分布）
          SizedBox(
            height: 24,
            child: Row(
              children: List.generate(labels.length, (index) {
                final alignment = index == 0
                    ? CrossAxisAlignment.start
                    : index == labels.length - 1
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.center;
                return Expanded(
                  child: SizedBox(
                    width: 32,
                    child: Text(
                      labels[index],
                      textAlign: alignment == CrossAxisAlignment.center
                          ? TextAlign.center
                          : alignment == CrossAxisAlignment.start
                              ? TextAlign.left
                              : TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
        letterSpacing: 0.5,
      ),
    );
  }
}

/// 单个柱状图项
class _BarItemWidget extends StatelessWidget {
  final double lastMonth;
  final double currentMonth;
  final double maxValue;
  final Animation<double> animation;
  final bool isDark;
  final Color primaryColor;

  const _BarItemWidget({
    required this.lastMonth,
    required this.currentMonth,
    required this.maxValue,
    required this.animation,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final lastMonthHeight = maxValue > 0
            ? (lastMonth / maxValue * 128 * animation.value)
            : 0.0;
        final currentMonthHeight = maxValue > 0
                ? (currentMonth / maxValue * 128 * animation.value)
            : 0.0;

        return Container(
          height: 128,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 6,
            height: 128,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 上月柱（背景）
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 6,
                    height: lastMonthHeight,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFDBEAFE),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(99),
                      ),
                    ),
                  ),
                ),
                // 本月柱（前景）
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 6,
                    height: currentMonthHeight,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(99),
                      ),
                    ),
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
