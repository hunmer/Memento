import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/daily_bar_chart_card.dart';

/// 每日条形图卡片示例
class DailyBarChartCardExample extends StatelessWidget {
  const DailyBarChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('每日条形图卡片')),
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
                    child: DailyBarChartCardWidget(
                      size: const SmallSize(),
                      title: 'Monthly Steps',
                      subtitle: 'January 2025',
                      value: 187297,
                      unit: 'steps',
                      bars: const [
                        DailyBarData(height: 0.30, color: DailyBarColor.red),
                        DailyBarData(height: 0.45, color: DailyBarColor.red),
                        DailyBarData(height: 0.65, color: DailyBarColor.teal),
                        DailyBarData(height: 0.25, color: DailyBarColor.red),
                        DailyBarData(height: 0.40, color: DailyBarColor.red),
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
                    child: DailyBarChartCardWidget(
                      size: const MediumSize(),
                      title: 'Monthly Steps',
                      subtitle: 'January 2025',
                      value: 187297,
                      unit: 'steps',
                      bars: const [
                        DailyBarData(height: 0.30, color: DailyBarColor.red),
                        DailyBarData(height: 0.45, color: DailyBarColor.red),
                        DailyBarData(height: 0.65, color: DailyBarColor.teal),
                        DailyBarData(height: 0.25, color: DailyBarColor.red),
                        DailyBarData(height: 0.40, color: DailyBarColor.red),
                        DailyBarData(height: 0.70, color: DailyBarColor.teal),
                        DailyBarData(height: 0.55, color: DailyBarColor.teal),
                        DailyBarData(height: 0.15, color: DailyBarColor.red),
                        DailyBarData(height: 0.85, color: DailyBarColor.teal),
                        DailyBarData(height: 0.35, color: DailyBarColor.red),
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
                    child: DailyBarChartCardWidget(
                      size: const LargeSize(),
                      title: 'Monthly Steps',
                      subtitle: 'January 2025',
                      value: 187297,
                      unit: 'steps',
                      bars: const [
                        DailyBarData(height: 0.30, color: DailyBarColor.red),
                        DailyBarData(height: 0.45, color: DailyBarColor.red),
                        DailyBarData(height: 0.65, color: DailyBarColor.teal),
                        DailyBarData(height: 0.25, color: DailyBarColor.red),
                        DailyBarData(height: 0.40, color: DailyBarColor.red),
                        DailyBarData(height: 0.70, color: DailyBarColor.teal),
                        DailyBarData(height: 0.55, color: DailyBarColor.teal),
                        DailyBarData(height: 0.15, color: DailyBarColor.red),
                        DailyBarData(height: 0.85, color: DailyBarColor.teal),
                        DailyBarData(height: 0.35, color: DailyBarColor.red),
                        DailyBarData(height: 0.20, color: DailyBarColor.red),
                        DailyBarData(height: 0.60, color: DailyBarColor.teal),
                        DailyBarData(height: 0.52, color: DailyBarColor.teal),
                        DailyBarData(height: 0.90, color: DailyBarColor.teal),
                        DailyBarData(height: 0.40, color: DailyBarColor.red),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (4x1)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    height: 220,
                    child: DailyBarChartCardWidget(
                      size: const WideSize(),
                      title: 'Monthly Steps',
                      subtitle: 'January 2025',
                      value: 187297,
                      unit: 'steps',
                      bars: const [
                        DailyBarData(height: 0.30, color: DailyBarColor.red),
                        DailyBarData(height: 0.45, color: DailyBarColor.red),
                        DailyBarData(height: 0.65, color: DailyBarColor.teal),
                        DailyBarData(height: 0.25, color: DailyBarColor.red),
                        DailyBarData(height: 0.40, color: DailyBarColor.red),
                        DailyBarData(height: 0.70, color: DailyBarColor.teal),
                        DailyBarData(height: 0.55, color: DailyBarColor.teal),
                        DailyBarData(height: 0.15, color: DailyBarColor.red),
                        DailyBarData(height: 0.85, color: DailyBarColor.teal),
                        DailyBarData(height: 0.35, color: DailyBarColor.red),
                        DailyBarData(height: 0.50, color: DailyBarColor.teal),
                        DailyBarData(height: 0.40, color: DailyBarColor.red),
                        DailyBarData(height: 0.60, color: DailyBarColor.teal),
                        DailyBarData(height: 0.25, color: DailyBarColor.red),
                        DailyBarData(height: 0.75, color: DailyBarColor.teal),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (4x2)'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    height: 320,
                    child: DailyBarChartCardWidget(
                      size: const Wide2Size(),
                      title: 'Monthly Steps',
                      subtitle: 'January 2025',
                      value: 187297,
                      unit: 'steps',
                      bars: const [
                        DailyBarData(height: 0.30, color: DailyBarColor.red),
                        DailyBarData(height: 0.45, color: DailyBarColor.red),
                        DailyBarData(height: 0.65, color: DailyBarColor.teal),
                        DailyBarData(height: 0.25, color: DailyBarColor.red),
                        DailyBarData(height: 0.40, color: DailyBarColor.red),
                        DailyBarData(height: 0.70, color: DailyBarColor.teal),
                        DailyBarData(height: 0.55, color: DailyBarColor.teal),
                        DailyBarData(height: 0.15, color: DailyBarColor.red),
                        DailyBarData(height: 0.85, color: DailyBarColor.teal),
                        DailyBarData(height: 0.35, color: DailyBarColor.red),
                        DailyBarData(height: 0.20, color: DailyBarColor.red),
                        DailyBarData(height: 0.60, color: DailyBarColor.teal),
                        DailyBarData(height: 0.52, color: DailyBarColor.teal),
                        DailyBarData(height: 0.90, color: DailyBarColor.teal),
                        DailyBarData(height: 0.40, color: DailyBarColor.red),
                        DailyBarData(height: 0.30, color: DailyBarColor.red),
                        DailyBarData(height: 0.55, color: DailyBarColor.teal),
                        DailyBarData(height: 0.45, color: DailyBarColor.red),
                        DailyBarData(height: 0.75, color: DailyBarColor.teal),
                        DailyBarData(height: 0.65, color: DailyBarColor.teal),
                        DailyBarData(height: 0.25, color: DailyBarColor.red),
                        DailyBarData(height: 0.80, color: DailyBarColor.teal),
                        DailyBarData(height: 0.50, color: DailyBarColor.red),
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
