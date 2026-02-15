import 'package:Memento/screens/widgets_gallery/common_widgets/models/daily_event_data.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/daily_events_card.dart';
import 'package:flutter/material.dart';

/// 日期事件卡片示例
class DailyEventsCardExample extends StatelessWidget {
  const DailyEventsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('日期事件卡片')),
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
                    child: DailyEventsCardWidget(
                      weekday: 'Monday',
                      day: 7,
                      events: const [
                        DailyEventData(
                          title: 'Farmers Market',
                          time: '9:45–11:00AM',
                          colorValue: 0xFFE8A546,
                          backgroundColorLightValue: 0xFFFFF9F0,
                          backgroundColorDarkValue: 0xFF3d342b,
                          textColorLightValue: 0xFF5D4037,
                          textColorDarkValue: 0xFFFFE0B2,
                          subtextLightValue: 0xFF8D6E63,
                          subtextDarkValue: 0xFFD7CCC8,
                        ),
                      ],
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
                    child: DailyEventsCardWidget(
                      weekday: 'Monday',
                      day: 7,
                      events: const [
                        DailyEventData(
                          title: 'Farmers Market',
                          time: '9:45–11:00AM',
                          colorValue: 0xFFE8A546,
                          backgroundColorLightValue: 0xFFFFF9F0,
                          backgroundColorDarkValue: 0xFF3d342b,
                          textColorLightValue: 0xFF5D4037,
                          textColorDarkValue: 0xFFFFE0B2,
                          subtextLightValue: 0xFF8D6E63,
                          subtextDarkValue: 0xFFD7CCC8,
                        ),
                        DailyEventData(
                          title: 'Weekly Prep',
                          time: '11:15–1:00PM',
                          colorValue: 0xFF7ED321,
                          backgroundColorLightValue: 0xFFF0FFF0,
                          backgroundColorDarkValue: 0xFF1e3322,
                          textColorLightValue: 0xFF2E7D32,
                          textColorDarkValue: 0xFFA5D6A7,
                          subtextLightValue: 0xFF66BB6A,
                          subtextDarkValue: 0xFF81C784,
                        ),
                      ],
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
                    child: DailyEventsCardWidget(
                      weekday: 'Monday',
                      day: 7,
                      events: const [
                        DailyEventData(
                          title: 'Farmers Market',
                          time: '9:45–11:00AM',
                          colorValue: 0xFFE8A546,
                          backgroundColorLightValue: 0xFFFFF9F0,
                          backgroundColorDarkValue: 0xFF3d342b,
                          textColorLightValue: 0xFF5D4037,
                          textColorDarkValue: 0xFFFFE0B2,
                          subtextLightValue: 0xFF8D6E63,
                          subtextDarkValue: 0xFFD7CCC8,
                        ),
                        DailyEventData(
                          title: 'Weekly Prep',
                          time: '11:15–1:00PM',
                          colorValue: 0xFF7ED321,
                          backgroundColorLightValue: 0xFFF0FFF0,
                          backgroundColorDarkValue: 0xFF1e3322,
                          textColorLightValue: 0xFF2E7D32,
                          textColorDarkValue: 0xFFA5D6A7,
                          subtextLightValue: 0xFF66BB6A,
                          subtextDarkValue: 0xFF81C784,
                        ),
                      ],
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
