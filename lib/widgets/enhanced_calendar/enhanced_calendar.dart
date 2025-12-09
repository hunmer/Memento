import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:Memento/utils/image_utils.dart';

/// 日历数据模型，包含背景图片路径
class CalendarDayData {
  final DateTime date;
  final String? backgroundImage;
  final int? count;
  final bool isSelected;
  final bool isToday;
  final bool isCurrentMonth;

  const CalendarDayData({
    required this.date,
    this.backgroundImage,
    this.count,
    this.isSelected = false,
    this.isToday = false,
    this.isCurrentMonth = true,
  });

  CalendarDayData copyWith({
    DateTime? date,
    String? backgroundImage,
    int? count,
    bool? isSelected,
    bool? isToday,
    bool? isCurrentMonth,
  }) {
    return CalendarDayData(
      date: date ?? this.date,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      count: count ?? this.count,
      isSelected: isSelected ?? this.isSelected,
      isToday: isToday ?? this.isToday,
      isCurrentMonth: isCurrentMonth ?? this.isCurrentMonth,
    );
  }
}

/// 日历配置类
class EnhancedCalendarConfig {
  final Map<DateTime, CalendarDayData> dayData;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final bool enableNavigation;
  final bool enableTodayButton;
  final bool enableDateSelection;
  final String? locale;
  final TextStyle? dayTextStyle;
  final TextStyle? selectedDayTextStyle;
  final TextStyle? todayTextStyle;
  final BoxDecoration? selectedDayDecoration;
  final BoxDecoration? todayDecoration;
  final EdgeInsets dayMargin;
  final double dayRadius;
  final Function(DateTime)? onDaySelected;
  final Function(DateTime)? onDayLongPressed;
  final Function(DateTime)? onHeaderTapped;
  final Function(DateTime)? onFormatChanged;

  const EnhancedCalendarConfig({
    required this.dayData,
    required this.focusedDay,
    this.selectedDay,
    this.calendarFormat = CalendarFormat.month,
    this.enableNavigation = true,
    this.enableTodayButton = true,
    this.enableDateSelection = true,
    this.locale,
    this.dayTextStyle,
    this.selectedDayTextStyle,
    this.todayTextStyle,
    this.selectedDayDecoration,
    this.todayDecoration,
    this.dayMargin = const EdgeInsets.all(4),
    this.dayRadius = 8,
    this.onDaySelected,
    this.onDayLongPressed,
    this.onHeaderTapped,
    this.onFormatChanged,
  });
}

/// 支持背景图片的增强日历组件
class EnhancedCalendar extends StatefulWidget {
  final EnhancedCalendarConfig config;

  const EnhancedCalendar({super.key, required this.config});

  @override
  State<EnhancedCalendar> createState() => _EnhancedCalendarState();
}

class _EnhancedCalendarState extends State<EnhancedCalendar> {
  late DateTime _focusedDay;
  late DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.config.focusedDay;
    _selectedDay = widget.config.selectedDay;
  }

  @override
  void didUpdateWidget(EnhancedCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部传入的 focusedDay 改变时，更新内部状态
    if (oldWidget.config.focusedDay != widget.config.focusedDay) {
      _focusedDay = widget.config.focusedDay;
    }
    if (oldWidget.config.selectedDay != widget.config.selectedDay) {
      _selectedDay = widget.config.selectedDay;
    }
  }

  /// 自定义日期单元格构建器
  Widget _dayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    final dayKey = DateTime(day.year, day.month, day.day);
    final dayData = widget.config.dayData[dayKey];

    final backgroundImage = dayData?.backgroundImage;
    final count = dayData?.count;
    final isSelected = _selectedDay != null && isSameDay(day, _selectedDay!);
    final isToday = isSameDay(day, DateTime.now());
    final isCurrentMonth = day.month == _focusedDay.month;

    // 默认文本样式
    TextStyle textStyle =
        widget.config.dayTextStyle ??
        TextStyle(
          color: isCurrentMonth ? Colors.black87 : Colors.grey.shade400,
          fontSize: 16,
        );

    // 今天样式
    if (isToday) {
      textStyle =
          widget.config.todayTextStyle ??
          textStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          );
    }

    // 有背景图片时文字颜色改为白色
    if (backgroundImage != null) {
      textStyle = textStyle.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: const Offset(1, 1),
            blurRadius: 2,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ],
      );
    }

    // 选中日期样式（不改变背景，只改变文字）
    if (isSelected) {
      textStyle =
          widget.config.selectedDayTextStyle ??
          textStyle.copyWith(
            color:
                backgroundImage != null
                    ? Colors.white
                    : Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            decorationThickness: 2,
          );
    }

    return Container(
      margin: widget.config.dayMargin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.config.dayRadius),
        // 优先级：背景图片 > 今天高亮 > 默认（移除选中状态的背景颜色）
        color:
            backgroundImage == null && isToday
                ? (widget.config.todayDecoration?.color ??
                    Theme.of(context).primaryColor.withValues(alpha: 0.1))
                : null,
        image:
            backgroundImage != null
                ? DecorationImage(
                  image: ImageUtils.createImageProvider(backgroundImage),
                  fit: BoxFit.cover,
                  opacity: 1,
                  // colorFilter: ColorFilter.mode(
                  //   Colors.black.withValues(alpha: 0.2),
                  //   BlendMode.darken,
                  // ),
                )
                : null,
        border:
            isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : (isToday && backgroundImage == null
                    ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 1.5,
                    )
                    : null),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.config.dayRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.config.dayRadius),
          onTap:
              widget.config.enableDateSelection
                  ? () {
                    setState(() {
                      _selectedDay = day;
                    });
                    widget.config.onDaySelected?.call(day);
                  }
                  : null,
          onLongPress:
              widget.config.onDayLongPressed != null
                  ? () => widget.config.onDayLongPressed!.call(day)
                  : null,
          child: Stack(
            children: [
              // 日期数字
              Center(child: Text(day.day.toString(), style: textStyle)),

              // 计数徽章
              if (count != null && count > 1)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : Theme.of(context).primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 预留方法：未来可以扩展头部右侧按钮功能
  // List<Widget> _buildRightActions(BuildContext context) {
  //   final actions = <Widget>[];
  //
  //   if (widget.config.enableTodayButton) {
  //     actions.add(
  //       IconButton(
  //         icon: const Icon(Icons.today),
  //         onPressed: () {
  //           final today = DateTime.now();
  //           setState(() {
  //             _focusedDay = today;
  //             _selectedDay = today;
  //           });
  //           widget.config.onDaySelected?.call(today);
  //         },
  //         tooltip: '回到今天',
  //       ),
  //     );
  //   }
  //
  //   return actions;
  // }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime(2010),
      lastDay: DateTime(2030),
      focusedDay: _focusedDay,
      selectedDayPredicate:
          (day) => _selectedDay != null && isSameDay(day, _selectedDay!),
      calendarFormat: widget.config.calendarFormat,
      locale: widget.config.locale,
      pageAnimationEnabled: false,

      // 样式配置
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: true,
        markersAutoAligned: true,
      ),

      // 头部配置 - 隐藏默认头部
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 0), // 隐藏标题
        leftChevronVisible: false, // 隐藏左侧导航
        rightChevronVisible: false, // 隐藏右侧导航
        headerPadding: EdgeInsets.zero, // 移除头部padding
        decoration: BoxDecoration(), // 移除默认装饰
      ),

      // 事件处理
      onDaySelected:
          widget.config.enableDateSelection
              ? (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                widget.config.onDaySelected?.call(selectedDay);
              }
              : null,
      onHeaderTapped: widget.config.onHeaderTapped,
      onFormatChanged:
          widget.config.onFormatChanged != null
              ? (format) => widget.config.onFormatChanged!(_focusedDay)
              : null,

      // 自定义构建器
      calendarBuilders: CalendarBuilders(
        defaultBuilder: _dayBuilder,
        selectedBuilder: _dayBuilder,
        todayBuilder: _dayBuilder,
        outsideBuilder: _dayBuilder,
        disabledBuilder: _dayBuilder,
        holidayBuilder: _dayBuilder,
        singleMarkerBuilder: _dayBuilder,
        withinRangeBuilder: _dayBuilder,
        rangeStartBuilder: _dayBuilder,
        rangeEndBuilder: _dayBuilder,
        prioritizedBuilder: _dayBuilder,
      ),
    );
  }
}

/// 增强日历组件的简化构造函数
class EnhancedCalendarWidget extends StatelessWidget {
  /// 日期数据映射，key为日期(年月日)，value为日期数据
  final Map<DateTime, CalendarDayData> dayData;

  /// 当前聚焦的月份
  final DateTime focusedMonth;

  /// 选中的日期
  final DateTime? selectedDate;

  /// 日期选择回调
  final Function(DateTime)? onDaySelected;

  /// 日期长按回调
  final Function(DateTime)? onDayLongPressed;

  /// 头部点击回调
  final Function(DateTime)? onHeaderTapped;

  /// 其他配置
  final CalendarFormat calendarFormat;
  final bool enableNavigation;
  final bool enableTodayButton;
  final bool enableDateSelection;
  final String? locale;

  const EnhancedCalendarWidget({
    super.key,
    required this.dayData,
    required this.focusedMonth,
    this.selectedDate,
    this.onDaySelected,
    this.onDayLongPressed,
    this.onHeaderTapped,
    this.calendarFormat = CalendarFormat.month,
    this.enableNavigation = true,
    this.enableTodayButton = true,
    this.enableDateSelection = true,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final config = EnhancedCalendarConfig(
      dayData: dayData,
      focusedDay: focusedMonth,
      selectedDay: selectedDate,
      calendarFormat: calendarFormat,
      enableNavigation: enableNavigation,
      enableTodayButton: enableTodayButton,
      enableDateSelection: enableDateSelection,
      locale: locale,
      onDaySelected: onDaySelected,
      onDayLongPressed: onDayLongPressed,
      onHeaderTapped: onHeaderTapped,
      dayMargin: const EdgeInsets.all(4),
      dayRadius: 8,
    );

    return EnhancedCalendar(config: config);
  }
}
