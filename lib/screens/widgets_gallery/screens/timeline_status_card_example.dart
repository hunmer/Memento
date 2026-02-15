import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/models/timeline_status_card_data.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/timeline_status_card.dart';

/// 时间线状态卡片示例
class TimelineStatusCardExample extends StatelessWidget {
  const TimelineStatusCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('时间线状态卡片')),
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
                    child: TimelineStatusCardWidget(
                      data: TimelineStatusCardData(
                        location: 'Tiburon',
                        title: 'Cleaner',
                        description: 'Electricity is cleaner until 2:00 PM.',
                        progressPercent: 0.65,
                        currentTimeLabel: 'Now',
                        timeLabels: ['12PM', '3PM'],
                      ),
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
                    child: TimelineStatusCardWidget(
                      data: TimelineStatusCardData(
                        location: 'Tiburon',
                        title: 'Cleaner',
                        description: 'Electricity is cleaner until 2:00 PM.',
                        progressPercent: 0.65,
                        currentTimeLabel: 'Now',
                        timeLabels: ['12PM', '3PM'],
                      ),
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
                    child: TimelineStatusCardWidget(
                      data: TimelineStatusCardData(
                        location: 'Tiburon',
                        title: 'Cleaner',
                        description: 'Electricity is cleaner until 2:00 PM.',
                        progressPercent: 0.65,
                        currentTimeLabel: 'Now',
                        timeLabels: ['12PM', '3PM'],
                      ),
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
