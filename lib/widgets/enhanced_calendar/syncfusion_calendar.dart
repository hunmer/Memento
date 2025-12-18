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

/// Syncfusion 日历组件封装
class SyncfusionCalendarWidget extends StatefulWidget {
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

  /// 是否启用导航
  final bool enableNavigation;

  /// 是否启用日期选择
  final bool enableDateSelection;

  /// 语言设置
  final String? locale;

  const SyncfusionCalendarWidget({
    super.key,
    required this.dayData,
    required this.focusedMonth,
    this.selectedDate,
    this.onDaySelected,
    this.onDayLongPressed,
    this.onHeaderTapped,
    this.enableNavigation = true,
    this.enableDateSelection = true,
    this.locale,
  });

  @override
  State<SyncfusionCalendarWidget> createState() =>
      _SyncfusionCalendarWidgetState();
}

class _SyncfusionCalendarWidgetState extends State<SyncfusionCalendarWidget> {
  late CalendarController _controller;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _controller = CalendarController();
    _controller.displayDate = widget.focusedMonth;
    _selectedDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(SyncfusionCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 同步 selectedDate 状态
    if (oldWidget.selectedDate != widget.selectedDate) {
      setState(() {
        _selectedDate = widget.selectedDate;
      });
    }
    // 同步 focusedMonth
    if (oldWidget.focusedMonth != widget.focusedMonth) {
      _controller.displayDate = widget.focusedMonth;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 构建自定义日期单元格
  Widget _monthCellBuilder(BuildContext context, MonthCellDetails details) {
    final dayKey = DateTime(
      details.date.year,
      details.date.month,
      details.date.day,
    );
    final dayData = widget.dayData[dayKey];

    final backgroundImage = dayData?.backgroundImage;
    final count = dayData?.count;
    final isSelected =
        _selectedDate != null &&
        _isSameDay(details.date, _selectedDate!);
    final isToday = _isSameDay(details.date, DateTime.now());
    final isCurrentMonth =
        details.date.month == widget.focusedMonth.month &&
        details.date.year == widget.focusedMonth.year;

    // 默认文本样式
    TextStyle textStyle = TextStyle(
      color: isCurrentMonth ? Colors.black87 : Colors.grey.shade400,
      fontSize: 16,
    );

    // 今天样式
    if (isToday) {
      textStyle = textStyle.copyWith(
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
      textStyle = textStyle.copyWith(
        color:
            backgroundImage != null
                ? Colors.white
                : Theme.of(context).primaryColor,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
        decorationThickness: 2,
      );
    }

    return GestureDetector(
      onTap:
          widget.enableDateSelection
              ? () {
                setState(() {
                  _selectedDate = details.date;
                });
                widget.onDaySelected?.call(details.date);
              }
              : null,
      onLongPress:
          widget.onDayLongPressed != null
              ? () => widget.onDayLongPressed!.call(details.date)
              : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          // 优先级：背景图片 > 今天高亮 > 默认
          color:
              backgroundImage == null && isToday
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : null,
          image:
              backgroundImage != null
                  ? DecorationImage(
                    image: ImageUtils.createImageProvider(backgroundImage),
                    fit: BoxFit.cover,
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
        child: Stack(
          children: [
            // 日期数字
            Center(child: Text(details.date.day.toString(), style: textStyle)),

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
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
    );
  }

  /// 判断两个日期是否为同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      key: ValueKey(
        'syncfusion_calendar_${widget.focusedMonth.year}_${widget.focusedMonth.month}',
      ),
      view: CalendarView.month,
      controller: _controller,
      initialDisplayDate: widget.focusedMonth,
      // 隐藏头部（外层已经有月份标题）
      headerHeight: 0,
      // 显示周次头部
      viewHeaderHeight: 40,
      // 月视图设置
      monthViewSettings: MonthViewSettings(
        // 禁用滑动切换月份（由外层列表控制）
        navigationDirection: MonthNavigationDirection.vertical,
        showTrailingAndLeadingDates: true,
        dayFormat: 'EEE',
        numberOfWeeksInView: 6,
        monthCellStyle: MonthCellStyle(
          textStyle: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          trailingDatesTextStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
          leadingDatesTextStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
        ),
      ),
      // 使用自定义单元格构建器
      monthCellBuilder: _monthCellBuilder,
      // 禁用内置的点击选择（使用自定义的）
      allowViewNavigation: false,
      showNavigationArrow: false,
      showDatePickerButton: false,
      showTodayButton: false,
      // 禁用触摸滑动
      allowedViews: const [CalendarView.month],
    );
  }
}
