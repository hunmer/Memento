import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/performance_bar_chart.dart';

/// 性能指标柱状图示例
class PerformanceBarChartExample extends StatelessWidget {
  const PerformanceBarChartExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('性能指标柱状图')),
      body: Container(
        color: isDark ? const Color(0xFF132e27) : const Color(0xFFF0F2F5),
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
                    child: PerformanceBarChartWidget(
                      badgeLabel: 'Performance',
                      growthPercentage: 280,
                      timePeriod: 'In the past 30 days',
                      barData: const [
                        PerformanceBarData(value: 12, label: '12%'),
                        PerformanceBarData(value: 78, label: '78%'),
                        PerformanceBarData(value: 62, label: '62%'),
                      ],
                      footerLabel: 'See All',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 200,
                    child: PerformanceBarChartWidget(
                      badgeLabel: 'Performance',
                      growthPercentage: 280,
                      timePeriod: 'In the past 30 days',
                      barData: const [
                        PerformanceBarData(value: 12, label: '12%'),
                        PerformanceBarData(value: 78, label: '78%'),
                        PerformanceBarData(value: 62, label: '62%'),
                        PerformanceBarData(value: 70, label: '70%'),
                        PerformanceBarData(value: 75, label: '75%'),
                      ],
                      footerLabel: 'See All',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 280,
                    child: PerformanceBarChartWidget(
                      badgeLabel: 'Performance',
                      growthPercentage: 280,
                      timePeriod: 'In the past 30 days',
                      barData: const [
                        PerformanceBarData(value: 12, label: '12%'),
                        PerformanceBarData(value: 78, label: '78%'),
                        PerformanceBarData(value: 62, label: '62%'),
                        PerformanceBarData(value: 70, label: '70%'),
                        PerformanceBarData(value: 75, label: '75%'),
                        PerformanceBarData(value: 95, label: '95%'),
                      ],
                      footerLabel: 'See All',
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
