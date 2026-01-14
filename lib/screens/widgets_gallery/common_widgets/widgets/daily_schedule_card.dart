import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';

/// 活动颜色枚举
enum EventColor { orange, green, blue, red, gray }

/// 活动颜色扩展，提供 JSON 序列化支持
extension EventColorExtension on EventColor {
  String toJson() => name;

  static EventColor fromJson(String value) {
    return EventColor.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventColor.orange,
    );
  }
}

/// 活动数据模型
class EventData {
  final String title;
  final String startTime;
  final String startPeriod;
  final String endTime;
  final String endPeriod;
  final EventColor color;
  final String? location;
  final bool isAllDay;
  final IconData? icon;

  const EventData({
    required this.title,
    required this.startTime,
    required this.startPeriod,
    required this.endTime,
    required this.endPeriod,
    required this.color,
    this.location,
    this.isAllDay = false,
    this.icon,
  });

  /// 从 JSON 创建
  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      title: json['title'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      startPeriod: json['startPeriod'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      endPeriod: json['endPeriod'] as String? ?? '',
      color: EventColorExtension.fromJson(json['color'] as String? ?? 'orange'),
      location: json['location'] as String?,
      isAllDay: json['isAllDay'] as bool? ?? false,
      icon: _parseIcon(json['iconCodePoint'] as int?),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startTime': startTime,
      'startPeriod': startPeriod,
      'endTime': endTime,
      'endPeriod': endPeriod,
      'color': color.toJson(),
      'location': location,
      'isAllDay': isAllDay,
      'iconCodePoint': icon?.codePoint,
    };
  }

  /// 解析图标
  static IconData? _parseIcon(int? codePoint) {
    if (codePoint == null) return null;
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }
}

/// 每日日程小组件
class DailyScheduleCardWidget extends StatefulWidget {
  final String todayDate;
  final List<EventData> todayEvents;
  final List<EventData> tomorrowEvents;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const DailyScheduleCardWidget({
    super.key,
    required this.todayDate,
    required this.todayEvents,
    required this.tomorrowEvents,
    this.inline = false,
  });

  /// 从 props 创建实例（用于公共小组件系统）
  factory DailyScheduleCardWidget.fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final todayEventsList = (props['todayEvents'] as List<dynamic>?)
            ?.map((e) => EventData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    final tomorrowEventsList = (props['tomorrowEvents'] as List<dynamic>?)
            ?.map((e) => EventData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return DailyScheduleCardWidget(
      todayDate: props['todayDate'] as String? ?? '',
      todayEvents: todayEventsList,
      tomorrowEvents: tomorrowEventsList,
      inline: props['inline'] as bool? ?? false,
    );
  }

  @override
  State<DailyScheduleCardWidget> createState() =>
      _DailyScheduleCardWidgetState();
}

class _DailyScheduleCardWidgetState extends State<DailyScheduleCardWidget>
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: Container(
              width: widget.inline ? double.maxFinite : 360,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF171717) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.todayDate,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(widget.todayEvents.length, (index) {
                    final itemAnimation = CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        index * 0.06,
                        0.4 + index * 0.06,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                    return _EventItemWidget(
                      event: widget.todayEvents[index],
                      animation: itemAnimation,
                      isDark: isDark,
                    );
                  }),
                  const SizedBox(height: 24),
                  Text(
                    'Tomorrow',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: isDark ? const Color(0xFF52525B) : const Color(0xFFA1A1AA),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(widget.tomorrowEvents.length, (index) {
                    final itemAnimation = CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        0.25 + index * 0.06,
                        0.65 + index * 0.06,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                    return _EventItemWidget(
                      event: widget.tomorrowEvents[index],
                      animation: itemAnimation,
                      isDark: isDark,
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EventItemWidget extends StatelessWidget {
  final EventData event;
  final Animation<double> animation;
  final bool isDark;

  const _EventItemWidget({
    required this.event,
    required this.animation,
    required this.isDark,
  });

  Color _getBackgroundColor(EventColor color) {
    switch (color) {
      case EventColor.orange:
        return isDark ? const Color(0x33F97316) : const Color(0xFFFEF7EC);
      case EventColor.green:
        return isDark ? const Color(0x3322C55E) : const Color(0xFFEBF9EB);
      case EventColor.blue:
        return isDark ? const Color(0x330284C7) : const Color(0xFFEBF5FA);
      case EventColor.red:
        return isDark ? const Color(0x33DC2626) : const Color(0xFFFEECEE);
      case EventColor.gray:
        return isDark ? const Color(0xFF27272A) : const Color(0xFFF0F2F5);
    }
  }

  Color _getIndicatorColor(EventColor color) {
    switch (color) {
      case EventColor.orange:
        return const Color(0xFFF97316);
      case EventColor.green:
        return const Color(0xFF4ADE80);
      case EventColor.blue:
        return const Color(0xFF60A5FA);
      case EventColor.red:
        return const Color(0xFFF87171);
      case EventColor.gray:
        return const Color(0xFF94A3B8);
    }
  }

  Color _getTextColor(EventColor color) {
    switch (color) {
      case EventColor.orange:
        return isDark ? const Color(0xFFFED7AA) : const Color(0xFF713F12);
      case EventColor.green:
        return isDark ? const Color(0xFFBBF7D0) : const Color(0xFF14532D);
      case EventColor.blue:
        return isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0C4A6E);
      case EventColor.red:
        return isDark ? const Color(0xFFFECACA) : const Color(0xFF7F1D1D);
      case EventColor.gray:
        return isDark ? const Color(0xFFD4D4D8) : const Color(0xFF334155);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (event.isAllDay && event.icon != null) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Opacity(
            opacity: animation.value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - animation.value)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(event.color),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0x3364748B) : const Color(0x9964748B),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Icon(event.icon, size: 16, color: isDark ? Colors.white : const Color(0xFFE2E8F0)),
                        ),
                        const SizedBox(width: 12),
                        Text(event.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _getTextColor(event.color))),
                      ],
                    ),
                    Text('all-day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF78716C) : const Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - animation.value)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 56,
              decoration: BoxDecoration(
                color: _getBackgroundColor(event.color),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(color: _getIndicatorColor(event.color), borderRadius: BorderRadius.circular(99)),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _getTextColor(event.color))),
                        if (event.location != null) ...[
                          const SizedBox(height: 2),
                          Text(event.location!, style: TextStyle(fontSize: 12, color: _getTextColor(event.color).withOpacity(0.7))),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.startTime, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _getTextColor(event.color).withOpacity(0.6))),
                            Text(event.startPeriod, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _getTextColor(event.color).withOpacity(0.6))),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.endTime, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _getTextColor(event.color).withOpacity(0.6))),
                            Text(event.endPeriod, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _getTextColor(event.color).withOpacity(0.6))),
                          ],
                        ),
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
