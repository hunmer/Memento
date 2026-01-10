import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

/// 支出对比图表示例
class ExpenseComparisonChartExample extends StatelessWidget {
  const ExpenseComparisonChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('支出对比图表')),
      body: Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        child: const Center(
          child: ExpenseComparisonChartWidget(
            currentAmount: 2048.00,
            changePercent: 3.5,
            dailyData: [
              DailyExpenseData(lastMonth: 40, currentMonth: 25),
              DailyExpenseData(lastMonth: 60, currentMonth: 35),
              DailyExpenseData(lastMonth: 30, currentMonth: 50),
              DailyExpenseData(lastMonth: 45, currentMonth: 15),
              DailyExpenseData(lastMonth: 20, currentMonth: 30),
              DailyExpenseData(lastMonth: 35, currentMonth: 45),
              DailyExpenseData(lastMonth: 50, currentMonth: 20),
              DailyExpenseData(lastMonth: 40, currentMonth: 55),
              DailyExpenseData(lastMonth: 65, currentMonth: 30),
              DailyExpenseData(lastMonth: 30, currentMonth: 80),
              DailyExpenseData(lastMonth: 55, currentMonth: 15),
              DailyExpenseData(lastMonth: 25, currentMonth: 35),
              DailyExpenseData(lastMonth: 45, currentMonth: 50),
              DailyExpenseData(lastMonth: 35, currentMonth: 65),
              DailyExpenseData(lastMonth: 70, currentMonth: 20),
              DailyExpenseData(lastMonth: 40, currentMonth: 30),
              DailyExpenseData(lastMonth: 20, currentMonth: 45),
              DailyExpenseData(lastMonth: 60, currentMonth: 25),
              DailyExpenseData(lastMonth: 30, currentMonth: 80),
              DailyExpenseData(lastMonth: 45, currentMonth: 10),
              DailyExpenseData(lastMonth: 55, currentMonth: 35),
              DailyExpenseData(lastMonth: 25, currentMonth: 60),
              DailyExpenseData(lastMonth: 65, currentMonth: 70),
              DailyExpenseData(lastMonth: 35, currentMonth: 40),
              DailyExpenseData(lastMonth: 50, currentMonth: 20),
              DailyExpenseData(lastMonth: 20, currentMonth: 50),
              DailyExpenseData(lastMonth: 45, currentMonth: 30),
              DailyExpenseData(lastMonth: 30, currentMonth: 25),
              DailyExpenseData(lastMonth: 40, currentMonth: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// 日支出数据模型
class DailyExpenseData {
  final double lastMonth;
  final double currentMonth;

  const DailyExpenseData({
    required this.lastMonth,
    required this.currentMonth,
  });
}

/// 支出对比图表小组件
class ExpenseComparisonChartWidget extends StatefulWidget {
  final double currentAmount;
  final double changePercent;
  final List<DailyExpenseData> dailyData;

  const ExpenseComparisonChartWidget({
    super.key,
    required this.currentAmount,
    required this.changePercent,
    required this.dailyData,
  });

  @override
  State<ExpenseComparisonChartWidget> createState() =>
      _ExpenseComparisonChartWidgetState();
}

class _ExpenseComparisonChartWidgetState
    extends State<ExpenseComparisonChartWidget>
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
              width: 400,
              padding: const EdgeInsets.all(32),
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
                            '本月支出',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
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
                              const SizedBox(width: 16),
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
                          const SizedBox(height: 8),
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
                                const SizedBox(width: 2),
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
                  const SizedBox(height: 32),
                  // 柱状图
                  _BarChartWidget(
                    data: widget.dailyData,
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

/// 柱状图组件
class _BarChartWidget extends StatelessWidget {
  final List<DailyExpenseData> data;
  final Animation<double> animation;
  final bool isDark;
  final Color primaryColor;

  const _BarChartWidget({
    required this.data,
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
  final Animation<double> animation;
  final bool isDark;
  final Color primaryColor;

  const _BarItemWidget({
    required this.lastMonth,
    required this.currentMonth,
    required this.animation,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final lastMonthHeight = (lastMonth / 100 * 128) * animation.value;
        final currentMonthHeight = (currentMonth / 100 * 128) * animation.value;

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
