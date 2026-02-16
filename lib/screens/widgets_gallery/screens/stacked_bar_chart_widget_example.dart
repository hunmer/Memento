import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/widgets/common/index.dart';

/// 堆叠条形图组件示例
///
/// 展示如何使用 StackedBarChartWidget 组件。
/// 该组件用于显示分层的堆叠条形图，支持三层数据（浅色、中间色、深色）。
class StackedBarChartWidgetExample extends StatelessWidget {
  const StackedBarChartWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('堆叠条形图组件')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
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
                    child: StackedBarChartWidget(
                      title: 'Bar chart',
                      subtitle: 'Minim dolor in amet...',
                      growthRate: 86,
                      data: [
                        StackedBarData(
                          lightValue: 25,
                          midValue: 30,
                          darkValue: 45,
                        ),
                        StackedBarData(
                          lightValue: 20,
                          midValue: 45,
                          darkValue: 25,
                        ),
                        StackedBarData(
                          lightValue: 35,
                          midValue: 40,
                          darkValue: 15,
                        ),
                        StackedBarData(
                          lightValue: 15,
                          midValue: 35,
                          darkValue: 25,
                        ),
                        StackedBarData(
                          lightValue: 40,
                          midValue: 25,
                          darkValue: 10,
                        ),
                        StackedBarData(
                          lightValue: 10,
                          midValue: 35,
                          darkValue: 15,
                        ),
                        StackedBarData(
                          lightValue: 25,
                          midValue: 15,
                          darkValue: 10,
                        ),
                        StackedBarData(
                          lightValue: 45,
                          midValue: 10,
                          darkValue: 5,
                        ),
                      ],
                      size: const SmallSize(),
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
                    child: StackedBarChartWidget(
                      title: 'Bar chart',
                      subtitle: 'Minim dolor in amet nulla...',
                      growthRate: 86,
                      data: [
                        StackedBarData(
                          lightValue: 25,
                          midValue: 30,
                          darkValue: 45,
                        ),
                        StackedBarData(
                          lightValue: 20,
                          midValue: 45,
                          darkValue: 25,
                        ),
                        StackedBarData(
                          lightValue: 35,
                          midValue: 40,
                          darkValue: 15,
                        ),
                        StackedBarData(
                          lightValue: 15,
                          midValue: 35,
                          darkValue: 25,
                        ),
                        StackedBarData(
                          lightValue: 40,
                          midValue: 25,
                          darkValue: 10,
                        ),
                        StackedBarData(
                          lightValue: 10,
                          midValue: 35,
                          darkValue: 15,
                        ),
                        StackedBarData(
                          lightValue: 25,
                          midValue: 15,
                          darkValue: 10,
                        ),
                        StackedBarData(
                          lightValue: 45,
                          midValue: 10,
                          darkValue: 5,
                        ),
                      ],
                      size: const MediumSize(),
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
                    child: StackedBarChartWidget(
                      title: 'Bar chart',
                      subtitle:
                          'Minim dolor in amet nulla laboris enim dolore...',
                      growthRate: 86,
                      data: [
                        StackedBarData(
                          lightValue: 25,
                          midValue: 30,
                          darkValue: 45,
                        ),
                        StackedBarData(
                          lightValue: 20,
                          midValue: 45,
                          darkValue: 25,
                        ),
                        StackedBarData(
                          lightValue: 35,
                          midValue: 40,
                          darkValue: 15,
                        ),
                        StackedBarData(
                          lightValue: 15,
                          midValue: 35,
                          darkValue: 25,
                        ),
                        StackedBarData(
                          lightValue: 40,
                          midValue: 25,
                          darkValue: 10,
                        ),
                        StackedBarData(
                          lightValue: 10,
                          midValue: 35,
                          darkValue: 15,
                        ),
                        StackedBarData(
                          lightValue: 25,
                          midValue: 15,
                          darkValue: 10,
                        ),
                        StackedBarData(
                          lightValue: 45,
                          midValue: 10,
                          darkValue: 5,
                        ),
                      ],
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (4x1)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: StackedBarChartWidget(
                    title: 'Stacked Bar Chart Overview',
                    subtitle: 'Monthly Statistics and Data Analysis',
                    growthRate: 86,
                    data: [
                      StackedBarData(
                        lightValue: 25,
                        midValue: 30,
                        darkValue: 45,
                      ),
                      StackedBarData(
                        lightValue: 20,
                        midValue: 45,
                        darkValue: 25,
                      ),
                      StackedBarData(
                        lightValue: 35,
                        midValue: 40,
                        darkValue: 15,
                      ),
                      StackedBarData(
                        lightValue: 15,
                        midValue: 35,
                        darkValue: 25,
                      ),
                      StackedBarData(
                        lightValue: 40,
                        midValue: 25,
                        darkValue: 10,
                      ),
                      StackedBarData(
                        lightValue: 10,
                        midValue: 35,
                        darkValue: 15,
                      ),
                      StackedBarData(
                        lightValue: 25,
                        midValue: 15,
                        darkValue: 10,
                      ),
                      StackedBarData(
                        lightValue: 45,
                        midValue: 10,
                        darkValue: 5,
                      ),
                    ],
                    size: const WideSize(),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (4x2)'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: StackedBarChartWidget(
                    title: 'Complete Stacked Bar Chart Analysis',
                    subtitle:
                        'Comprehensive Monthly Statistics and Trends Overview',
                    growthRate: 86,
                    data: [
                      StackedBarData(
                        lightValue: 25,
                        midValue: 30,
                        darkValue: 45,
                      ),
                      StackedBarData(
                        lightValue: 20,
                        midValue: 45,
                        darkValue: 25,
                      ),
                      StackedBarData(
                        lightValue: 35,
                        midValue: 40,
                        darkValue: 15,
                      ),
                      StackedBarData(
                        lightValue: 15,
                        midValue: 35,
                        darkValue: 25,
                      ),
                      StackedBarData(
                        lightValue: 40,
                        midValue: 25,
                        darkValue: 10,
                      ),
                      StackedBarData(
                        lightValue: 10,
                        midValue: 35,
                        darkValue: 15,
                      ),
                      StackedBarData(
                        lightValue: 25,
                        midValue: 15,
                        darkValue: 10,
                      ),
                      StackedBarData(
                        lightValue: 45,
                        midValue: 10,
                        darkValue: 5,
                      ),
                    ],
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
