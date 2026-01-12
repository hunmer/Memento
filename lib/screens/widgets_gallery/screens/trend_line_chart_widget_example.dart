import 'package:flutter/material.dart';
import 'package:Memento/widgets/trend_line_chart_widget/index.dart';

/// 趋势折线图示例
class TrendLineChartWidgetExample extends StatelessWidget {
  const TrendLineChartWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('趋势折线图')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFEEF2F6),
        child: const Center(
          child: TrendLineChartWidget(
            title: 'Temperature',
            icon: Icons.thermostat,
            value: 4.875,
            dataPoints: [
              Offset(5, 90),
              Offset(15, 85),
              Offset(25, 70),
              Offset(35, 60),
              Offset(45, 75),
              Offset(50, 90),
              Offset(60, 60),
              Offset(70, 55),
              Offset(80, 85),
              Offset(90, 85),
              Offset(100, 60),
              Offset(110, 55),
              Offset(120, 70),
              Offset(130, 75),
              Offset(140, 80),
              Offset(145, 70),
              Offset(155, 75),
              Offset(160, 65),
              Offset(170, 50),
              Offset(180, 45),
              Offset(190, 60),
              Offset(200, 45),
              Offset(210, 60),
              Offset(220, 50),
              Offset(230, 60),
              Offset(240, 65),
              Offset(250, 45),
              Offset(260, 35),
              Offset(270, 70),
              Offset(280, 20),
              Offset(300, 70),
              Offset(315, 70),
            ],
            timeLabels: ['8:00am', '10:00am', '12:00am', '1:00pm', '3:00pm'],
            primaryColor: Color(0xFF0284C7),
            valueColor: Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }
}
