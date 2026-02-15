import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
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
                      size: const SmallSize(),
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
                      size: const MediumSize(),
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
                _buildSectionTitle('中宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 200,
                  child: DailyEventsCardWidget(
                    size: const WideSize(),
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
                      DailyEventData(
                        title: 'Team Meeting',
                        time: '2:00–3:00PM',
                        colorValue: 0xFF3B82F6,
                        backgroundColorLightValue: 0xFFF0F7FF,
                        backgroundColorDarkValue: 0xFF1a2744,
                        textColorLightValue: 0xFF1E40AF,
                        textColorDarkValue: 0xFFBFDBFE,
                        subtextLightValue: 0xFF60A5FA,
                        subtextDarkValue: 0xFF93C5FD,
                      ),
                    ],
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
                      size: const LargeSize(),
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
                _buildSectionTitle('大宽尺寸'),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  height: 280,
                  child: DailyEventsCardWidget(
                    size: const Wide2Size(),
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
                      DailyEventData(
                        title: 'Team Meeting',
                        time: '2:00–3:00PM',
                        colorValue: 0xFF3B82F6,
                        backgroundColorLightValue: 0xFFF0F7FF,
                        backgroundColorDarkValue: 0xFF1a2744,
                        textColorLightValue: 0xFF1E40AF,
                        textColorDarkValue: 0xFFBFDBFE,
                        subtextLightValue: 0xFF60A5FA,
                        subtextDarkValue: 0xFF93C5FD,
                      ),
                      DailyEventData(
                        title: 'Gym Session',
                        time: '5:00–6:00PM',
                        colorValue: 0xFFEC4899,
                        backgroundColorLightValue: 0xFFFDF2F8,
                        backgroundColorDarkValue: 0xFF4a1a2e,
                        textColorLightValue: 0xFFBE185D,
                        textColorDarkValue: 0xFFFBCFE8,
                        subtextLightValue: 0xFFF472B6,
                        subtextDarkValue: 0xFFF9A8D4,
                      ),
                    ],
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
