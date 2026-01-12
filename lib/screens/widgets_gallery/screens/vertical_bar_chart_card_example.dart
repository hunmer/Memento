import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/vertical_bar_chart_card.dart';

/// 垂直柱状图卡片示例
class VerticalBarChartCardExample extends StatelessWidget {
  const VerticalBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('垂直柱状图卡片')),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFE8ECF2),
        child: const Center(
          child: VerticalBarChartCardWidget(
            title: 'Vertical bar',
            subtitle: 'Statistics of the month',
            dataLabel1: 'Data one',
            dataLabel2: 'Data two',
            bars: [
              BarData(value1: 100, value2: 15),
              BarData(value1: 25, value2: 35),
              BarData(value1: 65, value2: 20),
              BarData(value1: 35, value2: 30),
              BarData(value1: 50, value2: 45),
              BarData(value1: 55, value2: 35),
              BarData(value1: 65, value2: 30),
            ],
          ),
        ),
      ),
    );
  }
}
