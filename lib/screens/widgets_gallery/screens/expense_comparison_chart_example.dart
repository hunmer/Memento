import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/expense_comparison_chart_card.dart';

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
          child: ExpenseComparisonChartCardWidget(
            title: '本月支出',
            currentAmount: 2048.00,
            changePercent: 3.5,
            dailyData: [
              DailyExpenseDataModel(lastMonth: 40, currentMonth: 25),
              DailyExpenseDataModel(lastMonth: 60, currentMonth: 35),
              DailyExpenseDataModel(lastMonth: 30, currentMonth: 50),
              DailyExpenseDataModel(lastMonth: 45, currentMonth: 15),
              DailyExpenseDataModel(lastMonth: 20, currentMonth: 30),
              DailyExpenseDataModel(lastMonth: 35, currentMonth: 45),
              DailyExpenseDataModel(lastMonth: 50, currentMonth: 20),
              DailyExpenseDataModel(lastMonth: 40, currentMonth: 55),
              DailyExpenseDataModel(lastMonth: 65, currentMonth: 30),
              DailyExpenseDataModel(lastMonth: 30, currentMonth: 80),
              DailyExpenseDataModel(lastMonth: 55, currentMonth: 15),
              DailyExpenseDataModel(lastMonth: 25, currentMonth: 35),
              DailyExpenseDataModel(lastMonth: 45, currentMonth: 50),
              DailyExpenseDataModel(lastMonth: 35, currentMonth: 65),
              DailyExpenseDataModel(lastMonth: 70, currentMonth: 20),
              DailyExpenseDataModel(lastMonth: 40, currentMonth: 30),
              DailyExpenseDataModel(lastMonth: 20, currentMonth: 45),
              DailyExpenseDataModel(lastMonth: 60, currentMonth: 25),
              DailyExpenseDataModel(lastMonth: 30, currentMonth: 80),
              DailyExpenseDataModel(lastMonth: 45, currentMonth: 10),
              DailyExpenseDataModel(lastMonth: 55, currentMonth: 35),
              DailyExpenseDataModel(lastMonth: 25, currentMonth: 60),
              DailyExpenseDataModel(lastMonth: 65, currentMonth: 70),
              DailyExpenseDataModel(lastMonth: 35, currentMonth: 40),
              DailyExpenseDataModel(lastMonth: 50, currentMonth: 20),
              DailyExpenseDataModel(lastMonth: 20, currentMonth: 50),
              DailyExpenseDataModel(lastMonth: 45, currentMonth: 30),
              DailyExpenseDataModel(lastMonth: 30, currentMonth: 25),
              DailyExpenseDataModel(lastMonth: 40, currentMonth: 10),
            ],
          ),
        ),
      ),
    );
  }
}
