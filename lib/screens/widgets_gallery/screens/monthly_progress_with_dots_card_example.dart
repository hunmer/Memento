import 'package:flutter/material.dart';

/// 月度进度圆点卡片示例
class MonthlyProgressWithDotsCardExample extends StatelessWidget {
  const MonthlyProgressWithDotsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('月度进度圆点卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: MonthlyProgressWithDotsCardWidget(
            month: 'September',
            currentDay: 18,
            totalDays: 31,
            percentage: 58,
            backgroundColor: Color(0xFF148690),
          ),
        ),
      ),
    );
  }
}

/// 月度进度圆点小组件
class MonthlyProgressWithDotsCardWidget extends StatelessWidget {
  /// 月份名称
  final String month;

  /// 当前天数
  final int currentDay;

  /// 总天数
  final int totalDays;

  /// 百分比
  final int percentage;

  /// 背景颜色
  final Color backgroundColor;

  /// 已过日期的颜色（圆点颜色）
  final Color? activeDotColor;

  /// 未过日期的颜色（圆点颜色）
  final Color? inactiveDotColor;

  const MonthlyProgressWithDotsCardWidget({
    super.key,
    required this.month,
    required this.currentDay,
    required this.totalDays,
    required this.percentage,
    required this.backgroundColor,
    this.activeDotColor,
    this.inactiveDotColor,
  });

  @override
  Widget build(BuildContext context) {
    // 颜色定义
    const defaultActiveDotColor = Color(0xFFFDE047);
    const defaultInactiveDotColor = Color(0x33FFFFFF);
    final textColor = Colors.white;
    const subtitleColor = Color(0x99FFFFFF);

    final effectiveActiveDotColor = activeDotColor ?? defaultActiveDotColor;
    final effectiveInactiveDotColor = inactiveDotColor ?? defaultInactiveDotColor;

    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 圆点矩阵（3行，每行11个点，代表33天）
          _DotMatrixGrid(
            currentDay: currentDay,
            activeDotColor: effectiveActiveDotColor,
            inactiveDotColor: effectiveInactiveDotColor,
          ),

          // 底部信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                month,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${currentDay}d/${totalDays}d • Passed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    percentage.toString(),
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 圆点矩阵网格
class _DotMatrixGrid extends StatelessWidget {
  final int currentDay;
  final Color activeDotColor;
  final Color inactiveDotColor;

  const _DotMatrixGrid({
    required this.currentDay,
    required this.activeDotColor,
    required this.inactiveDotColor,
  });

  @override
  Widget build(BuildContext context) {
    final dots = _generateDotStates();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int col = 0; col < 11; col++)
                  _Dot(
                    isActive: dots[row * 11 + col],
                    activeColor: activeDotColor,
                    inactiveColor: inactiveDotColor,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// 生成圆点状态列表
  List<bool> _generateDotStates() {
    final List<bool> states = [];
    for (int i = 0; i < 33; i++) {
      states.add(i < currentDay);
    }
    return states;
  }
}

/// 单个圆点
class _Dot extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const _Dot({
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
