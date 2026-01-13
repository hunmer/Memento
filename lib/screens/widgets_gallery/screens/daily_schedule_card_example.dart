import 'package:flutter/material.dart';
import 'package:Memento/screens/widgets_gallery/common_widgets/widgets/daily_schedule_card.dart';

/// 每日日程卡片示例
class DailyScheduleCardExample extends StatelessWidget {
  const DailyScheduleCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('每日日程卡片')),
      body: Container(
        color: isDark ? const Color(0xFFF3F4F6) : Colors.black,
        child: const Center(
          child: DailyScheduleCardWidget(
            todayDate: 'Monday, June 7',
            todayEvents: [
              EventData(
                title: 'Farmers Market',
                startTime: '9:45',
                startPeriod: 'am',
                endTime: '11:00',
                endPeriod: 'am',
                color: EventColor.orange,
                location: null,
              ),
              EventData(
                title: 'Weekly Prep',
                startTime: '11:15',
                startPeriod: 'am',
                endTime: '1:00',
                endPeriod: 'pm',
                color: EventColor.green,
                location: null,
              ),
              EventData(
                title: 'Product Sprint',
                startTime: '1:00',
                startPeriod: 'pm',
                endTime: '2:15',
                endPeriod: 'pm',
                color: EventColor.green,
                location: null,
              ),
              EventData(
                title: 'Team Goals',
                startTime: '3:00',
                startPeriod: 'pm',
                endTime: '4:00',
                endPeriod: 'pm',
                color: EventColor.blue,
                location: null,
              ),
            ],
            tomorrowEvents: [
              EventData(
                title: "Ravi's Birthday",
                startTime: '',
                startPeriod: '',
                endTime: '',
                endPeriod: '',
                color: EventColor.gray,
                location: null,
                isAllDay: true,
                icon: Icons.card_giftcard,
              ),
              EventData(
                title: 'Morning Swim',
                startTime: '9:00',
                startPeriod: 'am',
                endTime: '9:45',
                endPeriod: 'am',
                color: EventColor.red,
                location: 'Home',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
