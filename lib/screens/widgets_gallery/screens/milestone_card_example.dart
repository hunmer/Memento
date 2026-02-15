import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/milestone_card.dart';

/// 里程碑追踪卡片示例
class MilestoneCardExample extends StatelessWidget {
  const MilestoneCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('里程碑追踪卡片')),
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
                    child: MilestoneCardWidget(
                      size: const SmallSize(),
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCPuaYriTNZj_aRzOEEhoGRXOuhwyTTRssklQfbQOrtJLboxJj5BPDtQEJiouPbdl8Fyf1fkcO8kDgVUHaWkC2LL_Bwz4NPa-dxLcKp8bNYV6gp7HNf3YCUHbbh6lxYHU2gAfc3Ot1wO6PnfgQAZBwkTNwBYpsrGjTZ9WaQ8TH57VZvwvg2ranIpItpDK_gZRyiBnzHsmJ0CQS6SC1J6PhC05_JOHWl2k63hPclOmqBLBdQArbrj_9drOSPIcDt6ltyq7-Bq-pHDiNW',
                      title: "Will's life",
                      date: 'July 21, 2020',
                      daysCount: 129,
                      value: '0.46',
                      unit: 'years',
                      suffix: 'old',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: MilestoneCardWidget(
                      size: const MediumSize(),
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCPuaYriTNZj_aRzOEEhoGRXOuhwyTTRssklQfbQOrtJLboxJj5BPDtQEJiouPbdl8Fyf1fkcO8kDgVUHaWkC2LL_Bwz4NPa-dxLcKp8bNYV6gp7HNf3YCUHbbh6lxYHU2gAfc3Ot1wO6PnfgQAZBwkTNwBYpsrGjTZ9WaQ8TH57VZvwvg2ranIpItpDK_gZRyiBnzHsmJ0CQS6SC1J6PhC05_JOHWl2k63hPclOmqBLBdQArbrj_9drOSPIcDt6ltyq7-Bq-pHDiNW',
                      title: "Will's life",
                      date: 'July 21, 2020',
                      daysCount: 129,
                      value: '0.46',
                      unit: 'years',
                      suffix: 'old',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大尺寸'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: MilestoneCardWidget(
                      size: const LargeSize(),
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCPuaYriTNZj_aRzOEEhoGRXOuhwyTTRssklQfbQOrtJLboxJj5BPDtQEJiouPbdl8Fyf1fkcO8kDgVUHaWkC2LL_Bwz4NPa-dxLcKp8bNYV6gp7HNf3YCUHbbh6lxYHU2gAfc3Ot1wO6PnfgQAZBwkTNwBYpsrGjTZ9WaQ8TH57VZvwvg2ranIpItpDK_gZRyiBnzHsmJ0CQS6SC1J6PhC05_JOHWl2k63hPclOmqBLBdQArbrj_9drOSPIcDt6ltyq7-Bq-pHDiNW',
                      title: "Will's life",
                      date: 'July 21, 2020',
                      daysCount: 129,
                      value: '0.46',
                      unit: 'years',
                      suffix: 'old',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: MilestoneCardWidget(
                    size: const WideSize(),
                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCPuaYriTNZj_aRzOEEhoGRXOuhwyTTRssklQfbQOrtJLboxJj5BPDtQEJiouPbdl8Fyf1fkcO8kDgVUHaWkC2LL_Bwz4NPa-dxLcKp8bNYV6gp7HNf3YCUHbbh6lxYHU2gAfc3Ot1wO6PnfgQAZBwkTNwBYpsrGjTZ9WaQ8TH57VZvwvg2ranIpItpDK_gZRyiBnzHsmJ0CQS6SC1J6PhC05_JOHWl2k63hPclOmqBLBdQArbrj_9drOSPIcDt6ltyq7-Bq-pHDiNW',
                    title: "Will's life journey and milestones",
                    date: 'July 21, 2020',
                    daysCount: 129,
                    value: '0.46',
                    unit: 'years',
                    suffix: 'old',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 350,
                  child: MilestoneCardWidget(
                    size: const Wide2Size(),
                    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCPuaYriTNZj_aRzOEEhoGRXOuhwyTTRssklQfbQOrtJLboxJj5BPDtQEJiouPbdl8Fyf1fkcO8kDgVUHaWkC2LL_Bwz4NPa-dxLcKp8bNYV6gp7HNf3YCUHbbh6lxYHU2gAfc3Ot1wO6PnfgQAZBwkTNwBYpsrGjTZ9WaQ8TH57VZvwvg2ranIpItpDK_gZRyiBnzHsmJ0CQS6SC1J6PhC05_JOHWl2k63hPclOmqBLBdQArbrj_9drOSPIcDt6ltyq7-Bq-pHDiNW',
                    title: "Will's life journey and milestones tracking",
                    date: 'July 21, 2020',
                    daysCount: 129,
                    value: '0.46',
                    unit: 'years',
                    suffix: 'old',
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
