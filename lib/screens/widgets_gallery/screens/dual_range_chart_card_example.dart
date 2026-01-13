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
        child: const Center(
          child: DualRangeChartCardWidget(
            date: 'Jan 12, 2028',
            weekDays: ['Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue'],
            ranges: [
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
              DualRangeData(
                day: 'Sun',
                primaryRange: RangeData(min: 122, max: 140, startPercent: 0.18, heightPercent: 0.30),
                secondaryRange: RangeData(min: 74, max: 81, startPercent: 0.60, heightPercent: 0.12),
              ),
              DualRangeData(
                day: 'Mon',
                primaryRange: RangeData(min: 132, max: 148, startPercent: 0.22, heightPercent: 0.35),
                secondaryRange: RangeData(min: 77, max: 85, startPercent: 0.65, heightPercent: 0.15),
              ),
              DualRangeData(
                day: 'Tue',
                primaryRange: RangeData(min: 126, max: 141, startPercent: 0.10, heightPercent: 0.28),
                secondaryRange: RangeData(min: 73, max: 86, startPercent: 0.50, heightPercent: 0.22),
              ),
            ],
            primarySummary: RangeSummary(min: 129, max: 141, label: 'sys'),
            secondarySummary: RangeSummary(min: 70, max: 99, label: 'mmHg'),
          ),
        ),
      ),
    );
  }
}
