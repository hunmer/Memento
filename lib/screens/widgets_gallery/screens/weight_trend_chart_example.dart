import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/card_trend_line_chart.dart';
import 'package:flutter/material.dart';

/// 体重趋势图表示例
class WeightTrendChartExample extends StatelessWidget {
  const WeightTrendChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('体重趋势图表')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF9FAFB),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('小尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: CardTrendLineChart(
                      icon: Icons.thermostat,
                      currentValue: 37.2,
                      statusText: '体温正常',
                      valueUnit: '°C',
                      primaryColor: const Color(0xFFFF6B6B),
                      dataPoints: const [
                        TrendDataPoint(label: '6:00', value: 36.5),
                        TrendDataPoint(label: '9:00', value: 36.8),
                        TrendDataPoint(label: '12:00', value: 37.1),
                        TrendDataPoint(label: '15:00', value: 37.2),
                        TrendDataPoint(label: '18:00', value: 37.0),
                        TrendDataPoint(label: '21:00', value: 36.7),
                      ],
                      timeFilters: null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: CardTrendLineChart(
                      icon: Icons.thermostat,
                      currentValue: 37.2,
                      statusText: '体温正常',
                      valueUnit: '°C',
                      primaryColor: const Color(0xFFFF6B6B),
                      dataPoints: const [
                        TrendDataPoint(label: '6:00', value: 36.5),
                        TrendDataPoint(label: '9:00', value: 36.8),
                        TrendDataPoint(label: '12:00', value: 37.1),
                        TrendDataPoint(label: '15:00', value: 37.2),
                        TrendDataPoint(label: '18:00', value: 37.0),
                        TrendDataPoint(label: '21:00', value: 36.7),
                      ],
                      timeFilters: null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: CardTrendLineChart(
                      icon: Icons.thermostat,
                      currentValue: 37.2,
                      statusText: '体温正常',
                      valueUnit: '°C',
                      primaryColor: const Color(0xFFFF6B6B),
                      dataPoints: const [
                        TrendDataPoint(label: '6:00', value: 36.5),
                        TrendDataPoint(label: '9:00', value: 36.8),
                        TrendDataPoint(label: '12:00', value: 37.1),
                        TrendDataPoint(label: '15:00', value: 37.2),
                        TrendDataPoint(label: '18:00', value: 37.0),
                        TrendDataPoint(label: '21:00', value: 36.7),
                      ],
                      timeFilters: null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }
}
