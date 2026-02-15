import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/chart_icon_display_card.dart';

/// 图标展示图表卡片示例
class ChartIconDisplayCardExample extends StatelessWidget {
  const ChartIconDisplayCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('心情图表卡片')),
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
                    child: ChartIconDisplayCard(
                      size: HomeWidgetSize.small,
                      title: 'This Week',
                      subtitle: 'Your Mood',
                      moods: const [
                        ChartIconEntry(emoji: '😊', label: 'Mon', value: 12),
                        ChartIconEntry(emoji: '😐', label: 'Tue', value: 8),
                        ChartIconEntry(emoji: '😔', label: 'Wed', value: 5),
                      ],
                      displayType: ChartIconType.emoji,
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
                    child: ChartIconDisplayCard(
                      size: HomeWidgetSize.medium,
                      title: 'This Week',
                      subtitle: 'Your Mood',
                      moods: const [
                        ChartIconEntry(emoji: '😊', label: 'Mon', value: 12),
                        ChartIconEntry(emoji: '😐', label: 'Tue', value: 8),
                        ChartIconEntry(emoji: '😔', label: 'Wed', value: 5),
                        ChartIconEntry(emoji: '😊', label: 'Thu', value: 15),
                      ],
                      displayType: ChartIconType.emoji,
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
                    child: ChartIconDisplayCard(
                      size: HomeWidgetSize.large,
                      title: 'This Week',
                      subtitle: 'Your Mood',
                      moods: const [
                        ChartIconEntry(emoji: '😊', label: 'Mon', value: 12),
                        ChartIconEntry(emoji: '😐', label: 'Tue', value: 8),
                        ChartIconEntry(emoji: '😔', label: 'Wed', value: 5),
                        ChartIconEntry(emoji: '😊', label: 'Thu', value: 15),
                        ChartIconEntry(emoji: '😁', label: 'Fri', value: 18),
                      ],
                      displayType: ChartIconType.emoji,
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
