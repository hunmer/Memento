import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/dual_bar_chart_card.dart';

/// 双柱状图统计卡片示例
class DualBarChartCardExample extends StatelessWidget {
  const DualBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('双柱状图统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: DualBarChartCardWidget(
            title: '血压监测',
            date: 'Jan 12, 2028',
            primaryValue: 129,
            secondaryValue: 68,
            primaryLabel: 'sys',
            secondaryLabel: 'dia',
            warningStage: 'Stage 2',
            chartData: [
              DualBarData(primary: 32, secondary: 24),
              DualBarData(primary: 12, secondary: 32),
              DualBarData(primary: 20, secondary: 16),
              DualBarData(primary: 32, secondary: 28),
              DualBarData(primary: 36, secondary: 40),
              DualBarData(primary: 44, secondary: 40),
              DualBarData(primary: 16, secondary: 32),
              DualBarData(primary: 40, secondary: 28),
              DualBarData(primary: 32, secondary: 36),
              DualBarData(primary: 16, secondary: 48),
              DualBarData(primary: 8, secondary: 56),
              DualBarData(primary: 24, secondary: 32),
              DualBarData(primary: 36, secondary: 28),
              DualBarData(primary: 20, secondary: 36),
              DualBarData(primary: 36, secondary: 36),
              DualBarData(primary: 8, secondary: 28),
              DualBarData(primary: 24, secondary: 36),
              DualBarData(primary: 36, secondary: 8),
            ],
          ),
        ),
      ),
    );
  }
}
