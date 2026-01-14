import 'package:Memento/screens/widgets_gallery/common_widgets/common_widgets.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/card_trend_line_chart.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:flutter/material.dart';

/// 体重趋势图表示例
class CardTrendLineChartExample extends StatefulWidget {
  const CardTrendLineChartExample({super.key});

  @override
  State<CardTrendLineChartExample> createState() =>
      _CardTrendLineChartExampleState();
}

class _CardTrendLineChartExampleState extends State<CardTrendLineChartExample> {
  // 基础示例数据
  final List<TrendDataPoint> _weightData = const [
    TrendDataPoint(label: '12', value: 68.2),
    TrendDataPoint(label: '13', value: 67.5),
    TrendDataPoint(label: '14', value: 67.8),
    TrendDataPoint(label: '15', value: 66.9),
    TrendDataPoint(label: '16', value: 68.0),
    TrendDataPoint(label: '17', value: 67.5),
    TrendDataPoint(label: '18', value: 67.3),
    TrendDataPoint(label: '19', value: 68.5),
    TrendDataPoint(label: '20', value: 67.8),
    TrendDataPoint(label: '21', value: 67.6),
    TrendDataPoint(label: '22', value: 67.2),
    TrendDataPoint(label: '23', value: 67.8),
  ];

  // 温度数据
  final List<TrendDataPoint> _temperatureData = const [
    TrendDataPoint(label: '6:00', value: 36.5),
    TrendDataPoint(label: '9:00', value: 36.8),
    TrendDataPoint(label: '12:00', value: 37.1),
    TrendDataPoint(label: '15:00', value: 37.2),
    TrendDataPoint(label: '18:00', value: 37.0),
    TrendDataPoint(label: '21:00', value: 36.7),
  ];

  // 支出数据
  final List<TrendDataPoint> _expenseData = const [
    TrendDataPoint(label: '周一', value: 95.2),
    TrendDataPoint(label: '周二', value: 112.8),
    TrendDataPoint(label: '周三', value: 105.5),
    TrendDataPoint(label: '周四', value: 128.5),
    TrendDataPoint(label: '周五', value: 118.3),
    TrendDataPoint(label: '周六', value: 135.7),
    TrendDataPoint(label: '周日', value: 142.1),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('体重趋势图表')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF9FAFB),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 使用公共小组件构建器 - 基础示例
              SizedBox(
                height: 400,
                child: CommonWidgetBuilder.build(
                  context,
                  CommonWidgetId.weightTrendChart,
                  {
                    'title': '体重趋势',
                    'icon': Icons.monitor_weight.codePoint,
                    'currentValue': 67.8,
                    'statusText': 'You\'re on a normal weight range',
                    'valueUnit': 'kg',
                    'dataPoints': _weightData
                        .map((e) => {'label': e.label, 'value': e.value})
                        .toList(),
                    'timeFilters': ['1d', '1w', '1m', '1y', 'All Time'],
                    'initialFilterIndex': 4,
                  },
                  HomeWidgetSize.large,
                ),
              ),
              const SizedBox(height: 24),

              // 温度趋势示例（自定义颜色）
              SizedBox(
                height: 400,
                child: CardTrendLineChart(
                  icon: Icons.thermostat,
                  currentValue: 37.2,
                  statusText: '体温正常',
                  valueUnit: '°C',
                  primaryColor: const Color(0xFFFF6B6B),
                  dataPoints: _temperatureData,
                  timeFilters: null,
                ),
              ),
              const SizedBox(height: 24),

              // 价格趋势示例（不带图标）
              SizedBox(
                height: 400,
                child: CardTrendLineChart(
                  currentValue: 128.5,
                  statusText: '本月累计支出',
                  valueUnit: '元',
                  primaryColor: const Color(0xFF4ECDC4),
                  dataPoints: _expenseData,
                  timeFilters: const ['本周', '上周', '上月'],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
