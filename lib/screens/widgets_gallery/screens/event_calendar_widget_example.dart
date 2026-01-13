import 'package:animated_flip_counter/animated_flip_counter.dart';
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
        child: const Center(
          child: EventCalendarWidget(
            day: 15,
            weekday: 'Wednesday',
            month: 'August',
            eventCount: 3,
            weekDates: [12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25],
            weekStartDay: 0,
            reminder: 'Do not forget the weekly pill',
            reminderEmoji: '💊',
            events: [
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
    );
  }
}
