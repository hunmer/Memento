import 'package:flutter/material.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

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
            weekStartDay: 0, // Sunday
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

/// 事件数据模型
class EventData {
  final String title;
  final String time;
  final String duration;
  final String? location;
  final Color color;
  final Color iconColor;
  final String? buttonLabel;

  const EventData({
    required this.title,
    required this.time,
    required this.duration,
    this.location,
    required this.color,
    required this.iconColor,
    this.buttonLabel,
  });
}

/// 日历事件小组件
class EventCalendarWidget extends StatefulWidget {
  final int day;
  final String weekday;
  final String month;
  final int eventCount;
  final List<int> weekDates;
  final int weekStartDay;
  final String reminder;
  final String reminderEmoji;
  final List<EventData> events;

  const EventCalendarWidget({
    super.key,
    required this.day,
    required this.weekday,
    required this.month,
    required this.eventCount,
    required this.weekDates,
    required this.weekStartDay,
    required this.reminder,
    required this.reminderEmoji,
    required this.events,
  });

  @override
  State<EventCalendarWidget> createState() => _EventCalendarWidgetState();
}

class _EventCalendarWidgetState extends State<EventCalendarWidget>
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
    final primaryColor = isDark ? const Color(0xFFEF4444) : const Color(0xFFEF4444);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: 420,
              height: 260,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 上部分：日期区域 + 事件列表
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左侧日期区域
                      SizedBox(
                        width: 180,
                        child: Column(
                          children: [
                            _DateSection(
                              day: widget.day,
                              weekday: widget.weekday,
                              month: widget.month,
                              eventCount: widget.eventCount,
                              primaryColor: primaryColor,
                              animation: _animation,
                            ),
                            const SizedBox(height: 16),
                            _WeekCalendar(
                              weekDates: widget.weekDates,
                              currentDay: widget.day,
                              weekStartDay: widget.weekStartDay,
                              primaryColor: primaryColor,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 右侧事件列表
                      Expanded(
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (
                                  int i = 0;
                                  i < widget.events.length;
                                  i++
                                ) ...[
                                  if (i > 0) const SizedBox(height: 20),
                                  _EventCard(
                                    event: widget.events[i],
                                    animation: _animation,
                                    index: i,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 下部分：提醒项（占整行）
                  _ReminderItem(
                    emoji: widget.reminderEmoji,
                    text: widget.reminder,
                    animation: _animation,
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

/// 日期显示部分
class _DateSection extends StatelessWidget {
  final int day;
  final String weekday;
  final String month;
  final int eventCount;
  final Color primaryColor;
  final Animation<double> animation;

  const _DateSection({
    required this.day,
    required this.weekday,
    required this.month,
    required this.eventCount,
    required this.primaryColor,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedFlipCounter(
          value: day.toDouble(),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          textStyle: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w500,
            color: primaryColor,
            height: 1.0,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weekday,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                  height: 1.2,
                ),
              ),
              Text(
                '$month · $eventCount Events',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 周日历网格
class _WeekCalendar extends StatelessWidget {
  final List<int> weekDates;
  final int currentDay;
  final int weekStartDay;
  final Color primaryColor;
  final bool isDark;

  const _WeekCalendar({
    required this.weekDates,
    required this.currentDay,
    required this.weekStartDay,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const int daysPerRow = 7;

    // 计算需要多少行
    final rowCount = (weekDates.length / daysPerRow).ceil();

    return Column(
      children: [
        // 星期标签（只显示一行，7天）
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            7,
            (index) => SizedBox(
              width: 20,
              child: Center(
                child: Text(
                  weekdays[(weekStartDay + index) % 7],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 日期数字（多行）
        ...List.generate(rowCount, (rowIndex) {
          final startIndex = rowIndex * daysPerRow;
          final endIndex = (startIndex + daysPerRow).clamp(0, weekDates.length);
          final rowDates = weekDates.sublist(startIndex, endIndex);

          return Padding(
            padding: EdgeInsets.only(bottom: rowIndex < rowCount - 1 ? 4 : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(rowDates.length, (index) {
                final day = rowDates[index];
                final isCurrent = day == currentDay;
                final isPast = day < currentDay;

                return SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child:
                        isCurrent
                            ? Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? primaryColor.withOpacity(0.15)
                                        : const Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            )
                            : Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    isPast ? FontWeight.w400 : FontWeight.w500,
                                color:
                                    isPast
                                        ? Colors.grey.shade400
                                        : (isDark
                                            ? Colors.grey.shade200
                                            : Colors.grey.shade900),
                              ),
                            ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}

/// 提醒项
class _ReminderItem extends StatelessWidget {
  final String emoji;
  final String text;
  final Animation<double> animation;

  const _ReminderItem({
    required this.emoji,
    required this.text,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Transform.rotate(
          angle: -0.1,
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// 事件卡片
class _EventCard extends StatelessWidget {
  final EventData event;
  final Animation<double> animation;
  final int index;

  const _EventCard({
    required this.event,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        0.15 + index * 0.12,
        0.6 + index * 0.12,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(10 * (1 - itemAnimation.value), 0),
            child: Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: event.color,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: event.iconColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${event.time} · ${event.duration}${event.location != null ? ' · ${event.location}' : ''}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  if (event.buttonLabel != null) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? event.color.withOpacity(0.2)
                              : event.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.buttonLabel!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: event.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
