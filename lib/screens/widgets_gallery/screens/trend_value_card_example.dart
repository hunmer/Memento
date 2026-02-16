import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/trend_value_card.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 趋势数值卡片示例
class TrendValueCardExample extends StatelessWidget {
  const TrendValueCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('趋势数值卡片')),
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
                    child: TrendValueCardWidget(
                      value: 167.4,
                      unit: 'lbs',
                      trendValue: -0.8,
                      trendUnit: 'lbs',
                      chartData: [30, 40, 60, 80, 50, 30, 38, 30, 32, 40],
                      date: 'Jan 12, 2028',
                      additionalInfo: ['26.1 BMI', 'Overweight'],
                      trendLabel: 'vs last week',
                      primaryColor: const Color(0xFFF59E0B),
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
                    child: TrendValueCardWidget(
                      value: 167.4,
                      unit: 'lbs',
                      trendValue: -0.8,
                      trendUnit: 'lbs',
                      chartData: [30, 40, 60, 80, 50, 30, 38, 30, 32, 40],
                      date: 'Jan 12, 2028',
                      additionalInfo: ['26.1 BMI', 'Overweight'],
                      trendLabel: 'vs last week',
                      primaryColor: const Color(0xFFF59E0B),
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
                    child: TrendValueCardWidget(
                      value: 167.4,
                      unit: 'lbs',
                      trendValue: -0.8,
                      trendUnit: 'lbs',
                      chartData: [30, 40, 60, 80, 50, 30, 38, 30, 32, 40],
                      date: 'Jan 12, 2028',
                      additionalInfo: ['26.1 BMI', 'Overweight'],
                      trendLabel: 'vs last week',
                      primaryColor: const Color(0xFFF59E0B),
                      size: const LargeSize(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸 (4x1)'),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: TrendValueCardWidget(
                      value: 167.4,
                      unit: 'lbs',
                      trendValue: -0.8,
                      trendUnit: 'lbs',
                      chartData: [30, 40, 60, 80, 50, 30, 38, 30, 32, 40],
                      date: 'Jan 12, 2028',
                      additionalInfo: ['26.1 BMI', 'Overweight'],
                      trendLabel: 'vs last week',
                      primaryColor: const Color(0xFFF59E0B),
                      size: const WideSize(),
                      inline: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸 (4x2)'),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 320,
                    child: TrendValueCardWidget(
                      value: 167.4,
                      unit: 'lbs',
                      trendValue: -0.8,
                      trendUnit: 'lbs',
                      chartData: [30, 40, 60, 80, 50, 30, 38, 30, 32, 40],
                      date: 'Jan 12, 2028',
                      additionalInfo: ['26.1 BMI', 'Overweight'],
                      trendLabel: 'vs last week',
                      primaryColor: const Color(0xFFF59E0B),
                      size: const Wide2Size(),
                      inline: true,
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
