import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/performance_bar_chart.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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
                      size: const SmallSize(),
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
                      size: const MediumSize(),
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
                      size: const LargeSize(),
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
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: PerformanceBarChartWidget(
                    size: const WideSize(),
                    growthPercentage: 280,
                    timePeriod: 'In the past 30 days performance metrics',
                    barData: const [
                      PerformanceBarData(value: 12, label: '12%'),
                      PerformanceBarData(value: 78, label: '78%'),
                      PerformanceBarData(value: 62, label: '62%'),
                      PerformanceBarData(value: 70, label: '70%'),
                      PerformanceBarData(value: 75, label: '75%'),
                      PerformanceBarData(value: 95, label: '95%'),
                      PerformanceBarData(value: 88, label: '88%'),
                      PerformanceBarData(value: 92, label: '92%'),
                    ],
                    footerLabel: 'See All Details',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: PerformanceBarChartWidget(
                    size: const Wide2Size(),
                    growthPercentage: 280,
                    timePeriod:
                        'In the past 30 days performance metrics and analysis',
                    barData: const [
                      PerformanceBarData(value: 12, label: '12%'),
                      PerformanceBarData(value: 78, label: '78%'),
                      PerformanceBarData(value: 62, label: '62%'),
                      PerformanceBarData(value: 70, label: '70%'),
                      PerformanceBarData(value: 75, label: '75%'),
                      PerformanceBarData(value: 95, label: '95%'),
                      PerformanceBarData(value: 88, label: '88%'),
                      PerformanceBarData(value: 92, label: '92%'),
                      PerformanceBarData(value: 85, label: '85%'),
                      PerformanceBarData(value: 90, label: '90%'),
                    ],
                    footerLabel: 'See All Details and Analytics',
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
