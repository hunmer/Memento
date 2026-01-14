import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 时间线事件数据模型
class TimelineEvent {
  /// 事件所在小时（0-23）
  final int hour;

  /// 事件标题
  final String title;

  /// 事件时间显示（如 '9:45AM'）
  final String time;

  /// 主题颜色
  final Color color;

  /// 浅色模式背景色
  final Color backgroundColorLight;

  /// 深色模式背景色
  final Color backgroundColorDark;

  /// 浅色模式文本颜色
  final Color textColorLight;

  /// 深色模式文本颜色
  final Color textColorDark;

  /// 浅色模式次要文本颜色（可选）
  final Color? subtextLight;

  /// 深色模式次要文本颜色（可选）
  final Color? subtextDark;

  const TimelineEvent({
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

  /// 创建副本
  TimelineEvent copyWith({
    int? hour,
    String? title,
    String? time,
    Color? color,
    Color? backgroundColorLight,
    Color? backgroundColorDark,
    Color? textColorLight,
    Color? textColorDark,
    Color? subtextLight,
    Color? subtextDark,
  }) {
    return TimelineEvent(
      hour: hour ?? this.hour,
      title: title ?? this.title,
      time: time ?? this.time,
      color: color ?? this.color,
      backgroundColorLight: backgroundColorLight ?? this.backgroundColorLight,
      backgroundColorDark: backgroundColorDark ?? this.backgroundColorDark,
      textColorLight: textColorLight ?? this.textColorLight,
      textColorDark: textColorDark ?? this.textColorDark,
      subtextLight: subtextLight ?? this.subtextLight,
      subtextDark: subtextDark ?? this.subtextDark,
    );
  }

  /// 从 JSON 创建
  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      hour: json['hour'] as int,
      title: json['title'] as String,
      time: json['time'] as String,
      color: Color(json['color'] as int),
      backgroundColorLight: Color(json['backgroundColorLight'] as int),
      backgroundColorDark: Color(json['backgroundColorDark'] as int),
      textColorLight: Color(json['textColorLight'] as int),
      textColorDark: Color(json['textColorDark'] as int),
      subtextLight: json['subtextLight'] != null
          ? Color(json['subtextLight'] as int)
          : null,
      subtextDark: json['subtextDark'] != null
          ? Color(json['subtextDark'] as int)
          : null,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'title': title,
      'time': time,
      'color': color.value,
      'backgroundColorLight': backgroundColorLight.value,
      'backgroundColorDark': backgroundColorDark.value,
      'textColorLight': textColorLight.value,
      'textColorDark': textColorDark.value,
      if (subtextLight != null) 'subtextLight': subtextLight!.value,
      if (subtextDark != null) 'subtextDark': subtextDark!.value,
    };
  }
}

/// 特殊事件数据模型
class SpecialEvent {
  /// 事件标题
  final String title;

  /// 事件图标
  final IconData icon;

  const SpecialEvent({
    required this.title,
    required this.icon,
  });

  /// 创建副本
  SpecialEvent copyWith({
    String? title,
    IconData? icon,
  }) {
    return SpecialEvent(
      title: title ?? this.title,
      icon: icon ?? this.icon,
    );
  }

  /// 从 JSON 创建
  factory SpecialEvent.fromJson(Map<String, dynamic> json) {
    return SpecialEvent(
      title: json['title'] as String,
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'iconCodePoint': icon.codePoint,
    };
  }
}

/// 时间线日程卡片组件
///
/// 用于展示今明两天的日程安排，支持动画效果和主题适配。
/// 显示时间线事件列表，支持浅色/深色模式切换。
///
/// 使用示例：
/// ```dart
/// TimelineScheduleCard(
///   todayWeekday: 'Monday',
///   todayDay: 7,
///   tomorrowWeekday: 'Tuesday',
///   tomorrowDay: 8,
///   todayEvents: [
///     TimelineEvent(
///       hour: 10,
///       title: 'Farmers Market',
///       time: '9:45AM',
///       color: Color(0xFFF3A541),
///       backgroundColorLight: Color(0xFFFEF7EC),
///       backgroundColorDark: Color(0xFF4A3816),
///       textColorLight: Color(0xFF6B4916),
///       textColorDark: Color(0xFFFFD699),
///     ),
///     // ... 更多事件
///   ],
///   tomorrowEvents: [...],
///   tomorrowSpecialEvent: SpecialEvent(
///     title: "Ravi's Birthday",
///     icon: Icons.card_giftcard,
///   ),
/// )
/// ```
class TimelineScheduleCard extends StatefulWidget {
  /// 今天的星期名称
  final String todayWeekday;

  /// 今天的日期
  final int todayDay;

  /// 明天的星期名称
  final String tomorrowWeekday;

  /// 明天的日期
  final int tomorrowDay;

  /// 今天的事件列表
  final List<TimelineEvent> todayEvents;

  /// 明天的事件列表
  final List<TimelineEvent> tomorrowEvents;

  /// 明天的特殊事件（可选）
  final SpecialEvent? tomorrowSpecialEvent;

  /// 今天的更多事件数量（可选）
  final int? todayMoreEventsCount;

  /// 今天的更多事件颜色（可选）
  final List<Color>? todayMoreEventsColors;

  /// 明天的更多事件数量（可选）
  final int? tomorrowMoreEventsCount;

  /// 明天的更多事件颜色（可选）
  final List<Color>? tomorrowMoreEventsColors;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const TimelineScheduleCard({
    super.key,
    required this.todayWeekday,
    required this.todayDay,
    required this.tomorrowWeekday,
    required this.tomorrowDay,
    required this.todayEvents,
    required this.tomorrowEvents,
    this.tomorrowSpecialEvent,
    this.todayMoreEventsCount,
    this.todayMoreEventsColors,
    this.tomorrowMoreEventsCount,
    this.tomorrowMoreEventsColors,
    this.inline = false,
  });

  @override
  State<TimelineScheduleCard> createState() => _TimelineScheduleCardState();
}

class _TimelineScheduleCardState extends State<TimelineScheduleCard>
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
              height: widget.inline ? double.maxFinite : 500,
              width: widget.inline ? double.maxFinite : 500,
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
                      moreEventsCount: widget.todayMoreEventsCount ?? 0,
                      moreEventsColors: widget.todayMoreEventsColors ?? [],
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
                      moreEventsCount: widget.tomorrowMoreEventsCount ?? 0,
                      moreEventsColors: widget.tomorrowMoreEventsColors ?? [],
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
  final List<TimelineEvent> events;
  final Animation<double> animation;
  final Color primaryColor;
  final bool isDark;
  final bool isToday;
  final SpecialEvent? specialEvent;
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
                    color: isDark
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
                    color: isDark
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
                        color: isDark
                            ? const Color(0xFFD4D4D8)
                            : const Color(0xFF71717A),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        specialEvent!.title,
                        style: TextStyle(
                          color: isDark
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
  final TimelineEvent event;
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
                color: isDark
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
                color: isDark
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
                      color: isDark ? event.textColorDark : event.textColorLight,
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
                        color: isDark ? event.subtextDark : event.subtextLight,
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
                  color: isDark
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
