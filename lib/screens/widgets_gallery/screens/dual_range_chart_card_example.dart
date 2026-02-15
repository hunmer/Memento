import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/dual_range_chart_card.dart';

/// 双范围图表统计卡片示例
class DualRangeChartCardExample extends StatelessWidget {
  const DualRangeChartCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('双范围图表统计卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF3F4F6),
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
                    child: DualRangeChartCardWidget(
                      date: 'Jan 12, 2028',
                      weekDays: ['Wed', 'Thu', 'Fri'],
                      ranges: const [
                        DualRangeData(
                          day: 'Wed',
                          primaryRange: RangeData(min: 130, max: 145, startPercent: 0.15, heightPercent: 0.25),
                          secondaryRange: RangeData(min: 75, max: 85, startPercent: 0.55, heightPercent: 0.15),
                        ),
                        DualRangeData(
                          day: 'Thu',
                          primaryRange: RangeData(min: 125, max: 150, startPercent: 0.20, heightPercent: 0.40),
                          secondaryRange: RangeData(min: 78, max: 88, startPercent: 0.65, heightPercent: 0.25),
                        ),
                        DualRangeData(
                          day: 'Fri',
                          primaryRange: RangeData(min: 135, max: 142, startPercent: 0.10, heightPercent: 0.20),
                          secondaryRange: RangeData(min: 72, max: 80, startPercent: 0.50, heightPercent: 0.18),
                        ),
                      ],
                      primarySummary: RangeSummary(min: 129, max: 141, label: 'sys'),
                      secondarySummary: RangeSummary(min: 70, max: 99, label: 'mmHg'),
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
                    child: DualRangeChartCardWidget(
                      date: 'Jan 12, 2028',
                      weekDays: ['Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                      ranges: const [
                        DualRangeData(
                          day: 'Wed',
                          primaryRange: RangeData(min: 130, max: 145, startPercent: 0.15, heightPercent: 0.25),
                          secondaryRange: RangeData(min: 75, max: 85, startPercent: 0.55, heightPercent: 0.15),
                        ),
                        DualRangeData(
                          day: 'Thu',
                          primaryRange: RangeData(min: 125, max: 150, startPercent: 0.20, heightPercent: 0.40),
                          secondaryRange: RangeData(min: 78, max: 88, startPercent: 0.65, heightPercent: 0.25),
                        ),
                        DualRangeData(
                          day: 'Fri',
                          primaryRange: RangeData(min: 135, max: 142, startPercent: 0.10, heightPercent: 0.20),
                          secondaryRange: RangeData(min: 72, max: 80, startPercent: 0.50, heightPercent: 0.18),
                        ),
                        DualRangeData(
                          day: 'Sat',
                          primaryRange: RangeData(min: 128, max: 138, startPercent: 0.25, heightPercent: 0.15),
                          secondaryRange: RangeData(min: 76, max: 82, startPercent: 0.58, heightPercent: 0.10),
                        ),
                      ],
                      primarySummary: RangeSummary(min: 129, max: 141, label: 'sys'),
                      secondarySummary: RangeSummary(min: 70, max: 99, label: 'mmHg'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 300,
                    child: DualRangeChartCardWidget(
                      date: 'Jan 12, 2028',
                      weekDays: ['Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue'],
                      ranges: const [
                        DualRangeData(
                          day: 'Wed',
                          primaryRange: RangeData(min: 130, max: 145, startPercent: 0.15, heightPercent: 0.25),
                          secondaryRange: RangeData(min: 75, max: 85, startPercent: 0.55, heightPercent: 0.15),
                        ),
                        DualRangeData(
                          day: 'Thu',
                          primaryRange: RangeData(min: 125, max: 150, startPercent: 0.20, heightPercent: 0.40),
                          secondaryRange: RangeData(min: 78, max: 88, startPercent: 0.65, heightPercent: 0.25),
                        ),
                        DualRangeData(
                          day: 'Fri',
                          primaryRange: RangeData(min: 135, max: 142, startPercent: 0.10, heightPercent: 0.20),
                          secondaryRange: RangeData(min: 72, max: 80, startPercent: 0.50, heightPercent: 0.18),
                        ),
                        DualRangeData(
                          day: 'Sat',
                          primaryRange: RangeData(min: 128, max: 138, startPercent: 0.25, heightPercent: 0.15),
                          secondaryRange: RangeData(min: 76, max: 82, startPercent: 0.58, heightPercent: 0.10),
                        ),
                      ],
                      primarySummary: RangeSummary(min: 129, max: 141, label: 'sys'),
                      secondarySummary: RangeSummary(min: 70, max: 99, label: 'mmHg'),
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
