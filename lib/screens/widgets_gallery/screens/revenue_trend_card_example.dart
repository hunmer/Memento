import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/revenue_trend_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 收入趋势卡片示例
class RevenueTrendCardExample extends StatelessWidget {
  const RevenueTrendCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('收入趋势卡片')),
      body: Container(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFE5E5E5),
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
                    child: RevenueTrendCardWidget(
                      size: const SmallSize(),
                      value: 145.32,
                      currency: '\$',
                      percentage: 12,
                      period: 'Weekly',
                      chartData: [80, 70, 90, 75, 60],
                      dates: [22, 23, 24, 25, 26],
                      highlightIndex: 4,
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
                    child: RevenueTrendCardWidget(
                      size: const MediumSize(),
                      value: 145.32,
                      currency: '\$',
                      percentage: 12,
                      period: 'Weekly',
                      chartData: [80, 70, 90, 75, 60, 50, 40],
                      dates: [22, 23, 24, 25, 26, 27, 28],
                      highlightIndex: 4,
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
                    child: RevenueTrendCardWidget(
                      size: const LargeSize(),
                      value: 145.32,
                      currency: '\$',
                      percentage: 12,
                      period: 'Weekly',
                      chartData: [80, 70, 90, 75, 60, 50, 40, 65, 85],
                      dates: [20, 21, 22, 23, 24, 25, 26, 27, 28],
                      highlightIndex: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: RevenueTrendCardWidget(
                    size: const WideSize(),
                    value: 145.32,
                    currency: '\$',
                    percentage: 12,
                    period: 'Weekly',
                    chartData: [80, 70, 90, 75, 60, 50, 40, 65, 85, 72],
                    dates: [20, 21, 22, 23, 24, 25, 26, 27, 28, 29],
                    highlightIndex: 4,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: RevenueTrendCardWidget(
                    size: const Wide2Size(),
                    value: 145.32,
                    currency: '\$',
                    percentage: 12,
                    period: 'Weekly',
                    chartData: [
                      80,
                      70,
                      90,
                      75,
                      60,
                      50,
                      40,
                      65,
                      85,
                      72,
                      68,
                      78,
                      82,
                    ],
                    dates: [17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29],
                    highlightIndex: 4,
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
