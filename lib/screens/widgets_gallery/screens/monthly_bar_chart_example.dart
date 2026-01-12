import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/index.dart';

/// 月度柱状图统计卡片示例
///
/// 此示例展示如何使用 [MonthlyBarChartCard] 可复用组件。
/// 该组件用于展示全年12个月的数据趋势,高亮显示当前月份。
class MonthlyBarChartExample extends StatelessWidget {
  const MonthlyBarChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('月度柱状图统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFEBF1F5),
        child: const Center(
          child: MonthlyBarChartCard(
            totalValue: 890.93,
            currentMonth: 5, // June (0-indexed)
            monthlyData: [
              MonthlyData(month: 'Jan', value: 35),
              MonthlyData(month: 'Feb', value: 60),
              MonthlyData(month: 'Mar', value: 45),
              MonthlyData(month: 'Apr', value: 55),
              MonthlyData(month: 'May', value: 40),
              MonthlyData(month: 'Jun', value: 80),
              MonthlyData(month: 'Jul', value: 38),
              MonthlyData(month: 'Aug', value: 65),
              MonthlyData(month: 'Sep', value: 25),
              MonthlyData(month: 'Oct', value: 55),
              MonthlyData(month: 'Nov', value: 30),
              MonthlyData(month: 'Dec', value: 45),
            ],
          ),
        ),
      ),
    );
  }
}
