import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/vertical_bar_chart_card.dart';

/// 垂直柱状图卡片示例
class VerticalBarChartCardExample extends StatelessWidget {
  const VerticalBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('垂直柱状图卡片')),
      body: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFE8ECF2),
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
                      size: const SmallSize(),
                      title: 'Vertical bar',
                      subtitle: 'Statistics of the month',
                      dataLabel1: 'Data one',
                      dataLabel2: 'Data two',
                      bars: [
                        BarData(value1: 100, value2: 15),
                        BarData(value1: 25, value2: 35),
                        BarData(value1: 65, value2: 20),
                        BarData(value1: 35, value2: 30),
                        BarData(value1: 50, value2: 45),
                        BarData(value1: 55, value2: 35),
                        BarData(value1: 65, value2: 30),
                      ],
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
                      size: const MediumSize(),
                      title: 'Vertical bar',
                      subtitle: 'Statistics of the month',
                      dataLabel1: 'Data one',
                      dataLabel2: 'Data two',
                      bars: [
                        BarData(value1: 100, value2: 15),
                        BarData(value1: 25, value2: 35),
                        BarData(value1: 65, value2: 20),
                        BarData(value1: 35, value2: 30),
                        BarData(value1: 50, value2: 45),
                        BarData(value1: 55, value2: 35),
                        BarData(value1: 65, value2: 30),
                      ],
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
                      size: const LargeSize(),
                      title: 'Vertical bar',
                      subtitle: 'Statistics of the month',
                      dataLabel1: 'Data one',
                      dataLabel2: 'Data two',
                      bars: [
                        BarData(value1: 100, value2: 15),
                        BarData(value1: 25, value2: 35),
                        BarData(value1: 65, value2: 20),
                        BarData(value1: 35, value2: 30),
                        BarData(value1: 50, value2: 45),
                        BarData(value1: 55, value2: 35),
                        BarData(value1: 65, value2: 30),
                      ],
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
