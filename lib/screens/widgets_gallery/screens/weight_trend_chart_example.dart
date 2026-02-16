import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
                _buildSectionTitle('小尺寸 (1x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: CardTrendLineChart(
                      size: const SmallSize(),
                      icon: Icons.thermostat,
                      currentValue: 37.2,
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
                _buildSectionTitle('中尺寸 (2x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: CardTrendLineChart(
                      size: const MediumSize(),
                      icon: Icons.thermostat,
                      currentValue: 37.2,
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
                _buildSectionTitle('大尺寸 (2x2)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: CardTrendLineChart(
                      size: const LargeSize(),
                      icon: Icons.thermostat,
                      currentValue: 37.2,
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
                _buildSectionTitle('中宽尺寸 (4x1) - 宽度填满屏幕'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    height: 220,
                    child: CardTrendLineChart(
                      size: const WideSize(),
                      icon: Icons.trending_up,
                      currentValue: 65.5,
                      valueUnit: 'kg',
                      primaryColor: const Color(0xFF4ECDC4),
                      dataPoints: const [
                        TrendDataPoint(label: '周一', value: 66.2),
                        TrendDataPoint(label: '周二', value: 65.9),
                        TrendDataPoint(label: '周三', value: 66.0),
                        TrendDataPoint(label: '周四', value: 65.7),
                        TrendDataPoint(label: '周五', value: 65.5),
                        TrendDataPoint(label: '周六', value: 65.8),
                        TrendDataPoint(label: '周日', value: 65.5),
                      ],
                      timeFilters: const ['周', '月', '季', '年'],
                      onTimeFilterChanged: (index) {
                        debugPrint('选择时间范围: $index');
                      },
                      initialFilterIndex: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (4x2) - 宽度填满屏幕'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    height: 320,
                    child: CardTrendLineChart(
                      size: const Wide2Size(),
                      icon: Icons.fitness_center,
                      currentValue: 65.5,
                      valueUnit: 'kg',
                      primaryColor: const Color(0xFF6C5CE7),
                      dataPoints: const [
                        TrendDataPoint(label: '1日', value: 68.5),
                        TrendDataPoint(label: '5日', value: 68.0),
                        TrendDataPoint(label: '10日', value: 67.2),
                        TrendDataPoint(label: '15日', value: 66.5),
                        TrendDataPoint(label: '20日', value: 66.0),
                        TrendDataPoint(label: '25日', value: 65.5),
                        TrendDataPoint(label: '30日', value: 65.5),
                      ],
                      timeFilters: const ['周', '月', '季', '年'],
                      onTimeFilterChanged: (index) {
                        debugPrint('选择时间范围: $index');
                      },
                      initialFilterIndex: 1,
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
