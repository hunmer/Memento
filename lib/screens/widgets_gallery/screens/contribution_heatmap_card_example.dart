import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
                    child: ContributionHeatmapCardWidget(
                      size: HomeWidgetSize.small,
                      title: 'Contributions',
                      contributionCount: '12 contributions',
                      years: ['2016', '2017'],
                      selectedYear: '2016',
                      months: ['Nov', 'Dec'],
                      heatmapData: const [
                        [0, 2],
                        [0, 4],
                      ],
                      description: 'Minim dolor in amet.',
                      showMoreLabel: 'Show more',
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
                    child: ContributionHeatmapCardWidget(
                      size: HomeWidgetSize.medium,
                      title: 'Contributions',
                      contributionCount: '86 contributions',
                      years: ['2016', '2017', '2018'],
                      selectedYear: '2016',
                      months: ['Nov', 'Dec', 'Jan', 'Feb'],
                      heatmapData: const [
                        [0, 0, 0, 0],
                        [0, 2, 2, 4],
                        [0, 0, 0, 0],
                      ],
                      description: 'Minim dolor in amet nulla laboris.',
                      showMoreLabel: 'Show more activity',
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
                    child: ContributionHeatmapCardWidget(
                      size: HomeWidgetSize.large,
                      title: 'Sales per employee per month',
                      contributionCount: '263 contributions in the last year',
                      years: ['2016', '2017', '2018', '2019'],
                      selectedYear: '2016',
                      months: ['Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr'],
                      heatmapData: const [
                        [0, 0, 0, 0, 0, 0],
                        [0, 2, 2, 4, 0, 1],
                        [0, 0, 0, 0, 3, 0],
                        [0, 4, 0, 3, 2, 1],
                        [0, 4, 4, 4, 4, 0],
                        [0, 0, 0, 3, 0, 0],
                      ],
                      description: 'Minim dolor in amet nulla laboris enim dolore consequatt.',
                      showMoreLabel: 'Show more activity',
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
