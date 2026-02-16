import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/bar_chart_stats_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 柱状图统计卡片示例
class BarChartStatsCardExample extends StatelessWidget {
  const BarChartStatsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('柱状图统计卡片')),
      body: Container(
        color: isDark ? Colors.grey.shade900 : const Color(0xFFF3F5F9),
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
                    child: BarChartStatsCardWidget(
                      title: 'Sleep Time',
                      dateRange: '12 - 19 January 2025',
                      averageValue: 6.5,
                      unit: 'hours',
                      icon: Icons.bedtime,
                      iconColor: const Color(0xFF00C968),
                      data: const [3.2, 5.2, 9.5, 5.8, 3.2, 9.2, 7.2],
                      labels: const [
                        '12/01',
                        '13/01',
                        '14/01',
                        '15/01',
                        '16/01',
                        '17/01',
                        '18/01',
                      ],
                      maxValue: 10,
                      size: const SmallSize(),
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
                    child: BarChartStatsCardWidget(
                      title: 'Sleep Time',
                      dateRange: '12 - 19 January 2025',
                      averageValue: 6.5,
                      unit: 'hours',
                      icon: Icons.bedtime,
                      iconColor: const Color(0xFF00C968),
                      data: const [3.2, 5.2, 9.5, 5.8, 3.2, 9.2, 7.2],
                      labels: const [
                        '12/01',
                        '13/01',
                        '14/01',
                        '15/01',
                        '16/01',
                        '17/01',
                        '18/01',
                      ],
                      maxValue: 10,
                      size: const MediumSize(),
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
                    child: BarChartStatsCardWidget(
                      title: 'Sleep Time',
                      dateRange: '12 - 19 January 2025',
                      averageValue: 6.5,
                      unit: 'hours',
                      icon: Icons.bedtime,
                      iconColor: const Color(0xFF00C968),
                      data: const [3.2, 5.2, 9.5, 5.8, 3.2, 9.2, 7.2],
                      labels: const [
                        '12/01',
                        '13/01',
                        '14/01',
                        '15/01',
                        '16/01',
                        '17/01',
                        '18/01',
                      ],
                      maxValue: 10,
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (4x1)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: BarChartStatsCardWidget(
                    title: 'Sleep Time',
                    dateRange: '12 - 19 January 2025',
                    averageValue: 6.5,
                    unit: 'hours',
                    icon: Icons.bedtime,
                    iconColor: const Color(0xFF00C968),
                    data: const [3.2, 5.2, 9.5, 5.8, 3.2, 9.2, 7.2],
                    labels: const [
                      '12/01',
                      '13/01',
                      '14/01',
                      '15/01',
                      '16/01',
                      '17/01',
                      '18/01',
                    ],
                    maxValue: 10,
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (4x2)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 320,
                  child: BarChartStatsCardWidget(
                    title: 'Sleep Time',
                    dateRange: '12 - 19 January 2025',
                    averageValue: 6.5,
                    unit: 'hours',
                    icon: Icons.bedtime,
                    iconColor: const Color(0xFF00C968),
                    data: const [3.2, 5.2, 9.5, 5.8, 3.2, 9.2, 7.2],
                    labels: const [
                      '12/01',
                      '13/01',
                      '14/01',
                      '15/01',
                      '16/01',
                      '17/01',
                      '18/01',
                    ],
                    maxValue: 10,
                    size: const Wide2Size(),
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
