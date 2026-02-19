import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 事件日历卡片
///
/// 用于显示日期、周历和事件列表的卡片组件，支持动画效果和深色模式。
/// 适用于日程管理、事件提醒、日历应用等场景。
///
/// 特性：
/// - 日期显示（日、星期、月份）
/// - 周日历网格视图
/// - 事件列表（支持颜色、时间、位置等）
/// - 提醒事项（带 emoji）
/// - 入场动画（渐入+向上位移）
/// - 深色模式适配
/// - 可配置颜色和尺寸
class EventCalendarCard extends StatefulWidget {
  /// 日期（几号）
  final int day;

  /// 星期
  final String weekday;

  /// 月份
  final String month;

  /// 事件总数
  final int eventCount;

  /// 周日期列表
  final List<int> weekDates;

  /// 周起始日（0=周日, 1=周一, ...）
  final int weekStartDay;

  /// 提醒文本
  final String reminder;

  /// 提醒 emoji
  final String reminderEmoji;

  /// 事件列表
  final List<CalendarEventData> events;

  /// 主色调（用于强调当前日期）
  final Color? primaryColor;

  /// 卡片宽度
  final double? width;

  /// 卡片高度
  final double? height;

  const EventCalendarCard({
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
    this.primaryColor,
    this.width,
    this.height,
  });

  @override
  State<EventCalendarCard> createState() => _EventCalendarCardState();
}

class _EventCalendarCardState extends State<EventCalendarCard>
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
    final primaryColor =
        widget.primaryColor ?? (isDark ? const Color(0xFFEF4444) : const Color(0xFFEF4444));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.width ?? 420,
              height: widget.height ?? 260,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < widget.events.length; i++) ...[
                              if (i > 0) const SizedBox(height: 20),
                              _EventCard(
                                event: widget.events[i],
                                animation: _animation,
                                index: i,
                              ),
                            ],
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
          final endIndex =
              (startIndex + daysPerRow).clamp(0, weekDates.length);
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
                              color: isDark
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
                              color: isPast
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
  final CalendarEventData event;
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
    final start = 0.15 + index * 0.12;
    final end = (0.6 + index * 0.12).clamp(0.0, 1.0);
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        start,
        end,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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

/// 日历事件数据模型
///
/// 表示单个日历事件的详细信息。
class CalendarEventData {
  /// 事件标题
  final String title;

  /// 开始时间
  final String time;

  /// 持续时长
  final String duration;

  /// 位置（可选）
  final String? location;

  /// 事件颜色
  final Color color;

  /// 图标颜色
  final Color iconColor;

  /// 按钮标签（可选）
  final String? buttonLabel;

  const CalendarEventData({
    required this.title,
    required this.time,
    required this.duration,
    this.location,
    required this.color,
    required this.iconColor,
    this.buttonLabel,
  });
}
