import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/contribution_heatmap_card.dart';

/// 贡献热力图卡片示例
class ContributionHeatmapCardExample extends StatelessWidget {
  const ContributionHeatmapCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('贡献热力图卡片')),
      body: Container(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFEEF2F6),
        child: const Center(
          child: ContributionHeatmapCardWidget(
            title: 'Sales per employee per month',
            contributionCount: '263 contributions in the last year',
            years: ['2016', '2017', '2018', '2019'],
            selectedYear: '2016',
            months: ['Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr'],
            // 6列 x 6行热力图数据
            heatmapData: [
              [0, 0, 0, 0, 0, 0], // Nov
              [0, 2, 2, 4, 0, 1], // Dec
              [0, 0, 0, 0, 3, 0], // Jan
              [0, 4, 0, 3, 2, 1], // Feb
              [0, 4, 4, 4, 4, 0], // Mar
              [0, 0, 0, 3, 0, 0], // Apr
            ],
            description: 'Minim dolor in amet nulla laboris enim dolore consequatt.',
            showMoreLabel: 'Show more activity',
          ),
        ),
      ),
    );
  }
}
