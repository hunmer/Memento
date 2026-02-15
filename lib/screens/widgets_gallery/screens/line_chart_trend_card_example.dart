import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/line_chart_trend_card.dart';

/// 折线图趋势卡片示例
class LineChartTrendCardExample extends StatelessWidget {
  const LineChartTrendCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('折线图趋势卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
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
                    child: LineChartTrendCardWidget(
                      size: HomeWidgetSize.small,
                      value: 2583,
                      label: 'Earned',
                      changePercent: -5.34,
                      dataPoints: const [85, 70, 78, 35, 45, 20, 65],
                      unit: r'$',
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
                    child: LineChartTrendCardWidget(
                      size: HomeWidgetSize.medium,
                      value: 2583,
                      label: 'Earned',
                      changePercent: -5.34,
                      dataPoints: const [85, 70, 78, 35, 45, 20, 65],
                      unit: r'$',
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
                    child: LineChartTrendCardWidget(
                      size: HomeWidgetSize.large,
                      value: 2583,
                      label: 'Earned',
                      changePercent: -5.34,
                      dataPoints: const [85, 70, 78, 35, 45, 20, 65],
                      unit: r'$',
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
