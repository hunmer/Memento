import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
                      primaryColor: const Color(0xFFBAE6FD),
                      secondaryColor: const Color(0xFF64748B),
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
                      primaryColor: const Color(0xFFBAE6FD),
                      secondaryColor: const Color(0xFF64748B),
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
                      primaryColor: const Color(0xFFBAE6FD),
                      secondaryColor: const Color(0xFF64748B),
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: VerticalBarChartCardWidget(
                    title: 'Weather Overview',
                    subtitle: 'London - 10 Day Forecast',
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
                    primaryColor: const Color(0xFFBAE6FD),
                    secondaryColor: const Color(0xFF64748B),
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: VerticalBarChartCardWidget(
                    title: 'Complete Weather Analysis',
                    subtitle: 'London - Extended 14 Day Forecast with Trends',
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
                      BarData(value1: 24, value2: 14),
                      BarData(value1: 21, value2: 12),
                    ],
                    primaryColor: const Color(0xFFBAE6FD),
                    secondaryColor: const Color(0xFF64748B),
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
