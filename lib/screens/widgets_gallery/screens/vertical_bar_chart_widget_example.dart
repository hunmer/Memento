import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/vertical_bar_chart_card.dart';

/// 垂直条形图卡片示例
class VerticalBarChartExample extends StatelessWidget {
  const VerticalBarChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('垂直条形图卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: VerticalBarChartCardWidget(
            title: 'Weather',
            subtitle: 'London',
            dataLabel1: 'Day',
            dataLabel2: 'Night',
            bars: [
              BarData(value1: 20, value2: 12),
              BarData(value1: 18, value2: 10),
              BarData(value1: 15, value2: 8),
              BarData(value1: 12, value2: 6),
              BarData(value1: 10, value2: 5),
              BarData(value1: 14, value2: 7),
              BarData(value1: 16, value2: 9),
              BarData(value1: 19, value2: 11),
              BarData(value1: 22, value2: 13),
              BarData(value1: 25, value2: 15),
            ],
            primaryColor: Color(0xFFBAE6FD),
            secondaryColor: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
