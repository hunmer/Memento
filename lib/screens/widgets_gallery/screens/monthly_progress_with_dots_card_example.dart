import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/monthly_progress_with_dots_card.dart';

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
