import 'package:flutter/material.dart';
import 'package:Memento/widgets/common/timeline_schedule_card.dart';

/// 时间线日程卡片示例
class TimelineScheduleCardExample extends StatelessWidget {
  const TimelineScheduleCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('时间线日程卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: TimelineScheduleCard(
            todayWeekday: 'Monday',
            todayDay: 7,
            tomorrowWeekday: 'Tuesday',
            tomorrowDay: 8,
            todayEvents: [
              TimelineEvent(
                hour: 10,
                title: 'Farmers Market',
                time: '9:45AM',
                color: Color(0xFFF3A541),
                backgroundColorLight: Color(0xFFFEF7EC),
                backgroundColorDark: Color(0xFF4A3816),
                textColorLight: Color(0xFF6B4916),
                textColorDark: Color(0xFFFFD699),
                subtextLight: Color(0xFFA68B4E),
                subtextDark: Color(0xFFC4A774),
              ),
              TimelineEvent(
                hour: 11,
                title: 'Weekly Prep',
                time: '11:15AM',
                color: Color(0xFF6BD425),
                backgroundColorLight: Color(0xFFEFF9E9),
                backgroundColorDark: Color(0xFF1D3D16),
                textColorLight: Color(0xFF2F5913),
                textColorDark: Color(0xFF9BC968),
                subtextLight: Color(0xFF5D9E33),
                subtextDark: Color(0xFF7DB852),
              ),
              TimelineEvent(
                hour: 13,
                title: 'Product Sprint',
                time: '1PM',
                color: Color(0xFF6BD425),
                backgroundColorLight: Color(0xFFEFF9E9),
                backgroundColorDark: Color(0xFF1D3D16),
                textColorLight: Color(0xFF2F5913),
                textColorDark: Color(0xFF9BC968),
                subtextLight: Color(0xFF5D9E33),
                subtextDark: Color(0xFF7DB852),
              ),
              TimelineEvent(
                hour: 15,
                title: 'Team Goals',
                time: '3PM',
                color: Color(0xFF4BA1F1),
                backgroundColorLight: Color(0xFFEEF7FE),
                backgroundColorDark: Color(0xFF1A3A5A),
                textColorLight: Color(0xFF1A3B5A),
                textColorDark: Color(0xFF9BC9F1),
              ),
            ],
            tomorrowEvents: [
              TimelineEvent(
                hour: 9,
                title: 'Team Goals',
                time: '9AM',
                color: Color(0xFFEE4B55),
                backgroundColorLight: Color(0xFFFCECEC),
                backgroundColorDark: Color(0xFF4A1818),
                textColorLight: Color(0xFF5C1519),
                textColorDark: Color(0xFFF1A9A9),
              ),
              TimelineEvent(
                hour: 10,
                title: 'Design Review',
                time: '10AM',
                color: Color(0xFF6BD425),
                backgroundColorLight: Color(0xFFEFF9E9),
                backgroundColorDark: Color(0xFF1D3D16),
                textColorLight: Color(0xFF2F5913),
                textColorDark: Color(0xFF9BC968),
                subtextLight: Color(0xFF5D9E33),
                subtextDark: Color(0xFF7DB852),
              ),
              TimelineEvent(
                hour: 14,
                title: 'Team Lunch',
                time: '2PM',
                color: Color(0xFF4BA1F1),
                backgroundColorLight: Color(0xFFEEF7FE),
                backgroundColorDark: Color(0xFF1A3A5A),
                textColorLight: Color(0xFF1A3B5A),
                textColorDark: Color(0xFF9BC9F1),
              ),
              TimelineEvent(
                hour: 15,
                title: 'Regroup',
                time: '3PM',
                color: Color(0xFF6BD425),
                backgroundColorLight: Color(0xFFEFF9E9),
                backgroundColorDark: Color(0xFF1D3D16),
                textColorLight: Color(0xFF2F5913),
                textColorDark: Color(0xFF9BC968),
              ),
            ],
            tomorrowSpecialEvent: SpecialEvent(
              title: "Ravi's Birthday",
              icon: Icons.card_giftcard,
            ),
            todayMoreEventsCount: 3,
            todayMoreEventsColors: [
              Color(0xFFFED6A3),
              Color(0xFFF5B8C8),
              Color(0xFFA5D4F1),
            ],
            tomorrowMoreEventsCount: 2,
            tomorrowMoreEventsColors: [
              Color(0xFFC4B5FD),
              Color(0xFFF9A8D4),
            ],
          ),
        ),
      ),
    );
  }
}
