import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/event_calendar_widget.dart';

/// 日历事件卡片示例
class EventCalendarWidgetExample extends StatelessWidget {
  const EventCalendarWidgetExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('日历事件卡片')),
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
                    height: 180,
                    child: EventCalendarWidget(
                      day: 15,
                      weekday: 'Wednesday',
                      month: 'August',
                      eventCount: 3,
                      weekDates: const [12, 13, 14, 15, 16, 17, 18],
                      weekStartDay: 0,
                      reminder: 'Do not forget the weekly pill',
                      reminderEmoji: '💊',
                      events: const [
                        EventData(
                          title: 'Meeting with developers',
                          time: '8:15 AM',
                          duration: '45 min',
                          color: Color(0xFF525EAF),
                          iconColor: Color(0xFF6264A7),
                          buttonLabel: 'Go to Meet',
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
                    height: 250,
                    child: EventCalendarWidget(
                      day: 15,
                      weekday: 'Wednesday',
                      month: 'August',
                      eventCount: 3,
                      weekDates: const [12, 13, 14, 15, 16, 17, 18, 19, 20],
                      weekStartDay: 0,
                      reminder: 'Do not forget the weekly pill',
                      reminderEmoji: '💊',
                      events: const [
                        EventData(
                          title: 'Meeting with developers about system design.',
                          time: '8:15 AM',
                          duration: '45 min',
                          color: Color(0xFF525EAF),
                          iconColor: Color(0xFF6264A7),
                          buttonLabel: 'Go to Meet',
                        ),
                        EventData(
                          title: 'Interview with designers',
                          time: '9:30 AM',
                          duration: '45 min',
                          location: 'Office',
                          color: Color(0xFF00832D),
                          iconColor: Color(0xFF00AC47),
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
                    width: 350,
                    height: 350,
                    child: EventCalendarWidget(
                      day: 15,
                      weekday: 'Wednesday',
                      month: 'August',
                      eventCount: 3,
                      weekDates: const [12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
                      weekStartDay: 0,
                      reminder: 'Do not forget the weekly pill',
                      reminderEmoji: '💊',
                      events: const [
                        EventData(
                          title: 'Meeting with developers about system design and its problems.',
                          time: '8:15 AM',
                          duration: '45 min',
                          color: Color(0xFF525EAF),
                          iconColor: Color(0xFF6264A7),
                          buttonLabel: 'Go to Meet',
                        ),
                        EventData(
                          title: 'Interview with designers scheduled for the new marketing project.',
                          time: '9:30 AM',
                          duration: '45 min',
                          location: 'Office',
                          color: Color(0xFF00832D),
                          iconColor: Color(0xFF00AC47),
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
