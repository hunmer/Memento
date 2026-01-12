import 'package:flutter/material.dart';
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
        child: const Center(
          child: MilestoneCardWidget(
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
    );
  }
}
