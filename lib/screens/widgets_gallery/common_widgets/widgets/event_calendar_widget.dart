import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

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

  /// 从 JSON 创建
  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      title: json['title'] as String? ?? '',
      time: json['time'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      location: json['location'] as String?,
      color: Color(json['color'] as int? ?? 0xFF525EAF),
      iconColor: Color(json['iconColor'] as int? ?? 0xFF6264A7),
      buttonLabel: json['buttonLabel'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'duration': duration,
      'location': location,
      'color': color.value,
      'iconColor': iconColor.value,
      'buttonLabel': buttonLabel,
    };
  }
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

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  /// 小组件尺寸
  final HomeWidgetSize size;

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
    this.inline = false,
    this.size = HomeWidgetSize.medium,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory EventCalendarWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final eventsList = (props['events'] as List<dynamic>?)
            ?.map((e) => EventData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final weekDatesList = (props['weekDates'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        [];

    return EventCalendarWidget(
      day: props['day'] as int? ?? 15,
      weekday: props['weekday'] as String? ?? 'Wednesday',
      month: props['month'] as String? ?? 'August',
      eventCount: props['eventCount'] as int? ?? 3,
      weekDates: weekDatesList,
      weekStartDay: props['weekStartDay'] as int? ?? 0,
      reminder: props['reminder'] as String? ?? '',
      reminderEmoji: props['reminderEmoji'] as String? ?? '',
      events: eventsList,
      inline: props['inline'] as bool? ?? false,
      size: size,
    );
  }

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
              width: widget.inline ? double.maxFinite : 420,
              height: widget.inline ? double.maxFinite : 220,
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
              padding: widget.size.getPadding(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              size: widget.size,
                            ),
                            SizedBox(height: widget.size.getTitleSpacing()),
                            _WeekCalendar(
                              weekDates: widget.weekDates,
                              currentDay: widget.day,
                              weekStartDay: widget.weekStartDay,
                              primaryColor: primaryColor,
                              isDark: isDark,
                              size: widget.size,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: widget.size.getItemSpacing()),
                      Expanded(
                        child: Stack(
                          children: [
                            SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (int i = 0; i < widget.events.length; i++) ...[
                                    if (i > 0) SizedBox(height: widget.size.getItemSpacing()),
                                    _EventCard(
                                      event: widget.events[i],
                                      animation: _animation,
                                      index: i,
                                      size: widget.size,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.size.getItemSpacing()),
                  _ReminderItem(
                    emoji: widget.reminderEmoji,
                    text: widget.reminder,
                    animation: _animation,
                    size: widget.size,
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

class _DateSection extends StatelessWidget {
  final int day;
  final String weekday;
  final String month;
  final int eventCount;
  final Color primaryColor;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _DateSection({
    required this.day,
    required this.weekday,
    required this.month,
    required this.eventCount,
    required this.primaryColor,
    required this.animation,
    required this.size,
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
        SizedBox(width: size.getItemSpacing() / 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(weekday, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey.shade900, height: 1.2)),
              Text('$month · $eventCount Events', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade400, height: 1.2)),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  final List<int> weekDates;
  final int currentDay;
  final int weekStartDay;
  final Color primaryColor;
  final bool isDark;
  final HomeWidgetSize size;

  const _WeekCalendar({
    required this.weekDates,
    required this.currentDay,
    required this.weekStartDay,
    required this.primaryColor,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const int daysPerRow = 7;
    final rowCount = (weekDates.length / daysPerRow).ceil();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            7,
            (index) => SizedBox(
              width: 20,
              child: Center(
                child: Text(weekdays[(weekStartDay + index) % 7], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w400, color: Colors.grey.shade400)),
              ),
            ),
          ),
        ),
        SizedBox(height: size.getItemSpacing() / 4),
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
                    child: isCurrent
                        ? Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isDark ? primaryColor.withOpacity(0.15) : const Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 4)],
                            ),
                            child: Center(
                              child: Text('$day', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryColor)),
                            ),
                          )
                        : Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isPast ? FontWeight.w400 : FontWeight.w500,
                              color: isPast ? Colors.grey.shade400 : (isDark ? Colors.grey.shade200 : Colors.grey.shade900),
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

class _ReminderItem extends StatelessWidget {
  final String emoji;
  final String text;
  final Animation<double> animation;
  final HomeWidgetSize size;

  const _ReminderItem({
    required this.emoji,
    required this.text,
    required this.animation,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Transform.rotate(
          angle: -0.1,
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        SizedBox(width: size.getItemSpacing() / 2),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade200 : Colors.grey.shade800, height: 1.2)),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventData event;
  final Animation<double> animation;
  final int index;
  final HomeWidgetSize size;

  const _EventCard({
    required this.event,
    required this.animation,
    required this.index,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(0.15 + index * 0.12, 0.6 + index * 0.12, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: itemAnimation.value,
          child: Transform.translate(
            offset: Offset(10 * (1 - itemAnimation.value), 0),
            child: Container(
              padding: EdgeInsets.only(left: size.getPadding().left),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: event.color, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey.shade900, height: 1.3)),
                  SizedBox(height: size.getItemSpacing() / 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: event.iconColor),
                      SizedBox(width: size.getItemSpacing() / 3),
                      Text('${event.time} · ${event.duration}${event.location != null ? ' · ${event.location}' : ''}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                  if (event.buttonLabel != null) ...[
                    SizedBox(height: size.getItemSpacing() / 4),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? event.color.withOpacity(0.2) : event.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(event.buttonLabel!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: event.color)),
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
