import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/smooth_line_chart_card.dart';

/// 平滑曲线图表卡片示例（汽车统计风格）
class SmoothLineChartCardExample extends StatelessWidget {
  const SmoothLineChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('平滑曲线图表卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: SmoothLineChartCardWidget(
            title: '汽车',
            subtitle: '统计',
            date: '2022年2月20日',
            dataPoints: [
              DataPoint(x: 0, y: 80),
              DataPoint(x: 50, y: 50),
              DataPoint(x: 100, y: 10),
              DataPoint(x: 150, y: 60),
              DataPoint(x: 200, y: 80),
              DataPoint(x: 250, y: 110),
              DataPoint(x: 300, y: 110),
              DataPoint(x: 350, y: 80),
            ],
            maxValue: 150,
            timeLabels: ['7 am', '9 am', '11 am', '1 pm', '3 pm', '5 pm', '7 pm', '9 pm'],
            primaryColor: Color(0xFFFF7F56),
          ),
        ),
      ),
    );
  }
}
