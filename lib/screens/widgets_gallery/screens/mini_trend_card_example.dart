import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/mini_trend_card.dart';

/// 迷你趋势卡片示例
class MiniTrendCardExample extends StatelessWidget {
  const MiniTrendCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('迷你趋势卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
        child: const Center(
          child: MiniTrendCardWidget(
            title: 'Heart Rate',
            icon: Icons.monitor_heart,
            currentValue: 72,
            unit: 'bpm',
            subtitle: 'Resting Rate',
            weekDays: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
            trendData: [20, 22, 15, 35, 25, 35, 28, 32, 25, 40, 45, 35, 50, 60],
          ),
        ),
      ),
    );
  }
}
