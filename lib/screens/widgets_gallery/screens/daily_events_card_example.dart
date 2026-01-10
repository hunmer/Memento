import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';

/// 日期事件卡片示例
class DailyEventsCardExample extends StatelessWidget {
  const DailyEventsCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('日期事件卡片')),
      body: Container(
        color: isDark ? Colors.black : const Color(0xFFF2F2F7),
        child: const Center(
          child: DailyEventsCardWidget(
            weekday: 'Monday',
            day: 7,
            events: [
              EventData(
                title: 'Farmers Market',
                time: '9:45–11:00AM',
                color: Color(0xFFE8A546),
                backgroundColorLight: Color(0xFFFFF9F0),
                backgroundColorDark: Color(0xFF3d342b),
                textColorLight: Color(0xFF5D4037),
                textColorDark: Color(0xFFFFE0B2),
                subtextLight: Color(0xFF8D6E63),
                subtextDark: Color(0xFFD7CCC8),
              ),
              EventData(
                title: 'Weekly Prep',
                time: '11:15–1:00PM',
                color: Color(0xFF7ED321),
                backgroundColorLight: Color(0xFFF0FFF0),
                backgroundColorDark: Color(0xFF1e3322),
                textColorLight: Color(0xFF2E7D32),
                textColorDark: Color(0xFFA5D6A7),
                subtextLight: Color(0xFF66BB6A),
                subtextDark: Color(0xFF81C784),
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
  final Color color;
  final Color backgroundColorLight;
  final Color backgroundColorDark;
  final Color textColorLight;
  final Color textColorDark;
  final Color subtextLight;
  final Color subtextDark;

  const EventData({
    required this.title,
    required this.time,
    required this.color,
    required this.backgroundColorLight,
    required this.backgroundColorDark,
    required this.textColorLight,
    required this.textColorDark,
    required this.subtextLight,
    required this.subtextDark,
  });
}

/// 日期事件小组件
class DailyEventsCardWidget extends StatefulWidget {
  final String weekday;
  final int day;
  final List<EventData> events;

  const DailyEventsCardWidget({
    super.key,
    required this.weekday,
    required this.day,
    required this.events,
  });

  @override
  State<DailyEventsCardWidget> createState() => _DailyEventsCardWidgetState();
}

class _DailyEventsCardWidgetState extends State<DailyEventsCardWidget>
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
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 星期和日期
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.weekday,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedFlipCounter(
                          value: widget.day.toDouble() * _animation.value,
                          wholeDigits: 1,
                          fractionDigits: 0,
                          textStyle: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 事件列表
                  ...widget.events.asMap().entries.map((entry) {
                    final index = entry.key;
                    final event = entry.value;
                    final itemAnimation = CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        0.2 + index * 0.25,
                        0.6 + index * 0.2,
                        curve: Curves.easeOutCubic,
                      ),
                    );

                    return _EventItem(
                      event: event,
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

/// 事件项组件
class _EventItem extends StatelessWidget {
  final EventData event;
  final Animation<double> animation;
  final bool isDark;

  const _EventItem({
    required this.event,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - animation.value)),
            child: Container(
              margin: EdgeInsets.only(bottom: events.length > 1 ? 8 : 0),
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? event.backgroundColorDark
                    : event.backgroundColorLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: event.color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              color: isDark
                                  ? event.textColorDark
                                  : event.textColorLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.time,
                            style: TextStyle(
                              color: isDark
                                  ? event.subtextDark
                                  : event.subtextLight,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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

  List<EventData> get events => [event];
}
