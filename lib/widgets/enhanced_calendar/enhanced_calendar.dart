import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
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
  final CalendarView calendarView;
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
    this.calendarView = CalendarView.month,
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
  late DateTime? _selectedDay;
  late CalendarController _calendarController;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.config.selectedDay;
    _calendarController = CalendarController();
    _calendarController.displayDate = widget.config.focusedDay;
    _calendarController.selectedDate = widget.config.selectedDay;
  }

  @override
  void didUpdateWidget(EnhancedCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.selectedDay != widget.config.selectedDay) {
      setState(() {
        _selectedDay = widget.config.selectedDay;
        _calendarController.selectedDate = widget.config.selectedDay;
      });
    }
    if (oldWidget.config.focusedDay != widget.config.focusedDay) {
      _calendarController.displayDate = widget.config.focusedDay;
    }
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  DateTime get _focusedDay => widget.config.focusedDay;

  /// 自定义月份单元格构建器
  Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
    final day = details.date;
    final dayKey = DateTime(day.year, day.month, day.day);
    final dayData = widget.config.dayData[dayKey];

    final backgroundImage = dayData?.backgroundImage;
    final count = dayData?.count;
    final isSelected = _selectedDay != null && _isSameDay(day, _selectedDay!);
    final isToday = _isSameDay(day, DateTime.now());
    final isCurrentMonth =
        day.month == _focusedDay.month && day.year == _focusedDay.year;

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

    // 选中日期样式
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
                      _calendarController.selectedDate = day;
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
              Center(child: Text(day.day.toString(), style: textStyle)),
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      key: ValueKey(
        'syncfusion_calendar_${_focusedDay.year}_${_focusedDay.month}',
      ),
      controller: _calendarController,
      view: widget.config.calendarView,
      initialDisplayDate: _focusedDay,
      minDate: DateTime(2010),
      maxDate: DateTime(2030),
      showNavigationArrow: false,
      showDatePickerButton: false,
      headerHeight: 0,
      viewHeaderHeight: 40,
      monthViewSettings: MonthViewSettings(
        showTrailingAndLeadingDates: true,
        monthCellStyle: MonthCellStyle(
          backgroundColor: Colors.transparent,
          trailingDatesBackgroundColor: Colors.transparent,
          leadingDatesBackgroundColor: Colors.transparent,
        ),
      ),
      cellBorderColor: Colors.transparent,
      selectionDecoration: const BoxDecoration(),
      monthCellBuilder: _monthCellBuilder,
      onTap: (CalendarTapDetails details) {
        if (widget.config.enableDateSelection && details.date != null) {
          setState(() {
            _selectedDay = details.date;
            _calendarController.selectedDate = details.date;
          });
          widget.config.onDaySelected?.call(details.date!);
        }
      },
      onLongPress: (CalendarLongPressDetails details) {
        if (details.date != null) {
          widget.config.onDayLongPressed?.call(details.date!);
        }
      },
      onViewChanged: (ViewChangedDetails details) {
        if (details.visibleDates.isNotEmpty) {
          final midDate =
              details.visibleDates[details.visibleDates.length ~/ 2];
          widget.config.onFormatChanged?.call(midDate);
        }
      },
      allowViewNavigation: widget.config.enableNavigation,
    );
  }
}

/// 增强日历组件的简化构造函数
class EnhancedCalendarWidget extends StatelessWidget {
  final Map<DateTime, CalendarDayData> dayData;
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final Function(DateTime)? onDaySelected;
  final Function(DateTime)? onDayLongPressed;
  final Function(DateTime)? onHeaderTapped;
  final CalendarView calendarView;
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
    this.calendarView = CalendarView.month,
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
      calendarView: calendarView,
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

    return EnhancedCalendar(
      key: ValueKey(
        'calendar_state_${focusedMonth.year}_${focusedMonth.month}',
      ),
      config: config,
    );
  }
}
