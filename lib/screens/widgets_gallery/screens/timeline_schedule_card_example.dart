import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

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
          child: TimelineScheduleCardWidget(
            todayWeekday: 'Monday',
            todayDay: 7,
            tomorrowWeekday: 'Tuesday',
            tomorrowDay: 8,
            todayEvents: [
              TimelineEventData(
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
              TimelineEventData(
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
              TimelineEventData(
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
              TimelineEventData(
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
              TimelineEventData(
                hour: 9,
                title: 'Team Goals',
                time: '9AM',
                color: Color(0xFFEE4B55),
                backgroundColorLight: Color(0xFFFCECEC),
                backgroundColorDark: Color(0xFF4A1818),
                textColorLight: Color(0xFF5C1519),
                textColorDark: Color(0xFFF1A9A9),
              ),
              TimelineEventData(
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
              TimelineEventData(
                hour: 14,
                title: 'Team Lunch',
                time: '2PM',
                color: Color(0xFF4BA1F1),
                backgroundColorLight: Color(0xFFEEF7FE),
                backgroundColorDark: Color(0xFF1A3A5A),
                textColorLight: Color(0xFF1A3B5A),
                textColorDark: Color(0xFF9BC9F1),
              ),
              TimelineEventData(
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
            tomorrowSpecialEvent: SpecialEventData(
              title: "Ravi's Birthday",
              icon: Icons.card_giftcard,
            ),
          ),
        ),
      ),
    );
  }
}

/// 时间线事件数据模型
class TimelineEventData {
  final int hour;
  final String title;
  final String time;
  final Color color;
  final Color backgroundColorLight;
  final Color backgroundColorDark;
  final Color textColorLight;
  final Color textColorDark;
  final Color? subtextLight;
  final Color? subtextDark;

  const TimelineEventData({
    required this.hour,
    required this.title,
    required this.time,
    required this.color,
    required this.backgroundColorLight,
    required this.backgroundColorDark,
    required this.textColorLight,
    required this.textColorDark,
    this.subtextLight,
    this.subtextDark,
  });
}

/// 特殊事件数据模型
class SpecialEventData {
  final String title;
  final IconData icon;

  const SpecialEventData({required this.title, required this.icon});
}

/// 时间线日程小组件
class TimelineScheduleCardWidget extends StatefulWidget {
  final String todayWeekday;
  final int todayDay;
  final String tomorrowWeekday;
  final int tomorrowDay;
  final List<TimelineEventData> todayEvents;
  final List<TimelineEventData> tomorrowEvents;
  final SpecialEventData? tomorrowSpecialEvent;

  const TimelineScheduleCardWidget({
    super.key,
    required this.todayWeekday,
    required this.todayDay,
    required this.tomorrowWeekday,
    required this.tomorrowDay,
    required this.todayEvents,
    required this.tomorrowEvents,
    this.tomorrowSpecialEvent,
  });

  @override
  State<TimelineScheduleCardWidget> createState() =>
      _TimelineScheduleCardWidgetState();
}

class _TimelineScheduleCardWidgetState extends State<TimelineScheduleCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.error;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              height: 500,
              width: 500,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 今天的日程
                  Expanded(
                    child: _DayColumn(
                      weekday: widget.todayWeekday,
                      day: widget.todayDay,
                      events: widget.todayEvents,
                      animation: _animation,
                      primaryColor: primaryColor,
                      isDark: isDark,
                      isToday: true,
                      moreEventsCount: 3,
                      moreEventsColors: const [
                        Color(0xFFFED6A3),
                        Color(0xFFF5B8C8),
                        Color(0xFFA5D4F1),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 明天的日程
                  Expanded(
                    child: _DayColumn(
                      weekday: widget.tomorrowWeekday,
                      day: widget.tomorrowDay,
                      events: widget.tomorrowEvents,
                      animation: _animation,
                      primaryColor: primaryColor,
                      isDark: isDark,
                      isToday: false,
                      specialEvent: widget.tomorrowSpecialEvent,
                      moreEventsCount: 2,
                      moreEventsColors: const [
                        Color(0xFFC4B5FD),
                        Color(0xFFF9A8D4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 日期列组件
class _DayColumn extends StatelessWidget {
  final String weekday;
  final int day;
  final List<TimelineEventData> events;
  final Animation<double> animation;
  final Color primaryColor;
  final bool isDark;
  final bool isToday;
  final SpecialEventData? specialEvent;
  final int moreEventsCount;
  final List<Color> moreEventsColors;

  const _DayColumn({
    required this.weekday,
    required this.day,
    required this.events,
    required this.animation,
    required this.primaryColor,
    required this.isDark,
    required this.isToday,
    this.specialEvent,
    this.moreEventsCount = 0,
    this.moreEventsColors = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 星期和日期
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weekday,
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 32,
              child: AnimatedFlipCounter(
                value: day.toDouble() * animation.value,
                wholeDigits: 1,
                fractionDigits: 0,
                textStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 特殊事件（仅明天）
        if (!isToday && specialEvent != null) ...[
          SizedBox(
            height: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : 'Tomorrow',
                  style: TextStyle(
                    color:
                        isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF3F3F46)
                            : const Color(0xFFE4E4E7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        specialEvent!.icon,
                        size: 14,
                        color:
                            isDark
                                ? const Color(0xFFD4D4D8)
                                : const Color(0xFF71717A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        specialEvent!.title,
                        style: TextStyle(
                          color:
                              isDark
                                  ? const Color(0xFF3F3F46)
                                  : const Color(0xFF3A3A3C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        // 时间线事件
        ...events.map((event) {
          return _TimelineEventItem(
            event: event,
            animation: animation,
            isDark: isDark,
          );
        }),
        // 更多事件提示
        if (moreEventsCount > 0)
          _MoreEventsIndicator(
            count: moreEventsCount,
            colors: moreEventsColors,
            isDark: isDark,
            animation: animation,
          ),
      ],
    );
  }
}

/// 时间线事件项组件
class _TimelineEventItem extends StatelessWidget {
  final TimelineEventData event;
  final Animation<double> animation;
  final bool isDark;

  const _TimelineEventItem({
    required this.event,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间标签
          SizedBox(
            width: 20,
            child: Text(
              '${event.hour}',
              style: TextStyle(
                color:
                    isDark
                        ? const Color(0xFF98989D)
                        : const Color(0xFF8E8E93),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          // 事件卡片
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? event.backgroundColorDark
                        : event.backgroundColorLight,
                borderRadius: BorderRadius.circular(6),
                border: Border(
                  left: BorderSide(color: event.color, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color:
                          isDark ? event.textColorDark : event.textColorLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  if (event.subtextLight != null &&
                      event.subtextDark != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.time,
                      style: TextStyle(
                        color:
                            isDark ? event.subtextDark : event.subtextLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 更多事件指示器组件
class _MoreEventsIndicator extends StatelessWidget {
  final int count;
  final List<Color> colors;
  final bool isDark;
  final Animation<double> animation;

  const _MoreEventsIndicator({
    required this.count,
    required this.colors,
    required this.isDark,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const SizedBox(width: 28),
          Row(
            children: [
              Row(
                children: List.generate(
                  colors.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(left: index > 0 ? 2 : 0),
                    child: Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count more events',
                style: TextStyle(
                  color:
                      isDark
                          ? const Color(0xFF98989D)
                          : const Color(0xFF8E8E93),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
