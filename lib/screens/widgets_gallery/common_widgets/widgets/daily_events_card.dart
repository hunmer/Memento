import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:Memento/screens/home_screen/models/home_widget_size.dart';
import '../models/daily_event_data.dart';

/// 每日事件卡片小组件
///
/// 显示星期、日期和当日事件列表，支持动画效果
class DailyEventsCardWidget extends StatefulWidget {
  /// 星期标签
  final String weekday;

  /// 日期（几号）
  final int day;

  /// 事件数据列表
  final List<DailyEventData> events;

  /// 是否为内联模式（内联模式使用 double.maxFinite，非内联模式使用固定尺寸）
  final bool inline;

  const DailyEventsCardWidget({
    super.key,
    required this.weekday,
    required this.day,
    required this.events,
    this.inline = false,
  });

  /// 从属性 Map 创建组件（用于公共小组件系统）
  static DailyEventsCardWidget fromProps(
    Map<String, dynamic> props,
    HomeWidgetSize size,
  ) {
    final eventsList = props['events'] as List<dynamic>?;
    final events = eventsList?.map((e) => DailyEventData.fromJson(e as Map<String, dynamic>)).toList() ?? const [];

    return DailyEventsCardWidget(
      weekday: props['weekday'] as String? ?? 'Monday',
      day: props['day'] as int? ?? 1,
      events: events,
      inline: props['inline'] as bool? ?? false,
    );
  }

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
              width: widget.inline ? double.maxFinite : 200,
              height: widget.inline ? double.maxFinite : 200,
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
  final DailyEventData event;
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
              margin: EdgeInsets.only(bottom: _events.length > 1 ? 8 : 0),
              height: 42,
              decoration: BoxDecoration(
                color: Color(isDark
                    ? event.backgroundColorDarkValue
                    : event.backgroundColorLightValue),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: Color(event.colorValue),
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
                              color: Color(isDark
                                  ? event.textColorDarkValue
                                  : event.textColorLightValue),
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
                              color: Color(isDark
                                  ? event.subtextDarkValue
                                  : event.subtextLightValue),
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

  // 用于获取父组件的事件列表（这里只是占位，实际使用时通过参数传递）
  List<DailyEventData> get _events => [event];
}
