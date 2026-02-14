import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Memento 自定义 SfCalendar 封装组件
///
/// 对 Syncfusion SfCalendar 进行二次封装，提供丰富的自定义选项，
/// 同时保持简洁的 API，适用于日历插件和其他需要日历功能的场景。
class MementoSfCalendar extends StatelessWidget {
  // ============ 视图相关 ============

  /// 日历视图模式
  final CalendarView view;

  /// 日历控制器
  final CalendarController? controller;

  /// 允许的视图列表
  final List<CalendarView>? allowedViews;

  /// 是否允许视图导航（点击月视图日期切换到日视图）
  final bool allowViewNavigation;

  /// 初始显示日期
  final DateTime? initialDisplayDate;

  /// 初始选中日期
  final DateTime? initialSelectedDate;

  /// 每周起始日（1=周一, 7=周日）
  final int firstDayOfWeek;

  // ============ 数据源 ============

  /// 事件数据源
  final CalendarDataSource? dataSource;

  // ============ 月视图配置 ============

  /// 月视图设置（完整覆盖）
  /// 如果提供此参数，将忽略下面的便捷月视图参数
  final MonthViewSettings? monthViewSettings;

  /// 是否显示议程视图
  final bool showAgenda;

  /// 议程视图高度
  final double agendaViewHeight;

  /// 事件在月视图中的显示模式
  final MonthAppointmentDisplayMode appointmentDisplayMode;

  /// 是否显示前后月日期
  final bool showTrailingAndLeadingDates;

  /// 是否显示周数
  final bool showWeekNumber;

  /// 月视图中显示的周数
  final int numberOfWeeksInView;

  /// 月导航方向
  final MonthNavigationDirection monthNavigationDirection;

  /// 议程样式
  final AgendaStyle? agendaStyle;

  // ============ 时间槽配置 ============

  /// 时间槽视图设置（完整覆盖）
  /// 如果提供此参数，将忽略下面的便捷时间槽参数
  final TimeSlotViewSettings? timeSlotViewSettings;

  /// 开始时间（小时）
  final double startHour;

  /// 结束时间（小时）
  final double endHour;

  /// 时间间隔
  final Duration timeInterval;

  /// 非工作日列表
  final List<int>? nonWorkingDays;

  /// 时间间隔高度
  final double timeIntervalHeight;

  /// 时间格式
  final String? timeFormat;

  /// 时间文本样式
  final TextStyle? timeTextStyle;

  // ============ 日程视图配置 ============

  /// 日程视图设置
  final ScheduleViewSettings? scheduleViewSettings;

  /// 日程视图月头构建器
  final ScheduleViewMonthHeaderBuilder? scheduleViewMonthHeaderBuilder;

  // ============ 外观配置 ============

  /// 今日高亮颜色
  final Color? todayHighlightColor;

  /// 选中日期装饰
  final BoxDecoration? selectionDecoration;

  /// 单元格边框颜色
  final Color? cellBorderColor;

  /// 头部高度
  final double headerHeight;

  /// 视图头部高度
  final double viewHeaderHeight;

  /// 头部样式
  final CalendarHeaderStyle? headerStyle;

  /// 视图头部样式
  final ViewHeaderStyle? viewHeaderStyle;

  /// 月单元格构建器
  final MonthCellBuilder? monthCellBuilder;

  /// 事件构建器
  final CalendarAppointmentBuilder? appointmentBuilder;

  /// 时间区域构建器
  final TimeRegionBuilder? timeRegionBuilder;

  /// 背景色
  final Color? backgroundColor;

  /// 今日文本样式
  final TextStyle? todayTextStyle;

  /// 日历主题数据（SfCalendarThemeData 可从外部传入）
  final String? calendarTheme;

  // ============ 交互回调 ============

  /// 视图变化回调
  final ViewChangedCallback? onViewChanged;

  /// 点击回调
  final CalendarTapCallback? onTap;

  /// 长按回调
  final CalendarLongPressCallback? onLongPress;

  /// 选中变化回调
  final CalendarSelectionChangedCallback? onSelectionChanged;

  // ============ 高级特性 ============

  /// 特殊时间区域
  final List<TimeRegion>? specialRegions;

  /// 禁用日期（月视图）
  final List<DateTime>? blackoutDates;

  /// 禁用日期文本样式
  final TextStyle? blackoutDatesTextStyle;

  /// 最小日期
  final DateTime? minDate;

  /// 最大日期
  final DateTime? maxDate;

  /// 是否显示导航箭头
  final bool showNavigationArrow;

  /// 是否显示日期选择按钮
  final bool showDatePickerButton;

  /// 是否显示今日按钮
  final bool showTodayButton;

  /// 是否显示当前时间指示器
  final bool showCurrentTimeIndicator;

  /// 是否允许拖放
  final bool allowDragAndDrop;

  /// 拖放回调
  final AppointmentDragEndCallback? onDragEnd;

  /// 是否允许调整事件大小
  final bool allowAppointmentResize;

  /// 调整大小回调
  final AppointmentResizeEndCallback? onAppointmentResizeEnd;

  /// 资源视图设置
  final ResourceViewSettings? resourceViewSettings;

  /// 按需加载回调
  final LoadMoreWidgetBuilder? loadMoreWidgetBuilder;

  const MementoSfCalendar({
    super.key,
    this.view = CalendarView.month,
    this.controller,
    this.allowedViews,
    this.allowViewNavigation = true,
    this.initialDisplayDate,
    this.initialSelectedDate,
    this.firstDayOfWeek = 1,
    // 数据源
    this.dataSource,
    // 月视图
    this.monthViewSettings,
    this.showAgenda = true,
    this.agendaViewHeight = 200,
    this.appointmentDisplayMode =
        MonthAppointmentDisplayMode.appointment,
    this.showTrailingAndLeadingDates = true,
    this.showWeekNumber = false,
    this.numberOfWeeksInView = 6,
    this.monthNavigationDirection = MonthNavigationDirection.horizontal,
    this.agendaStyle,
    // 时间槽
    this.timeSlotViewSettings,
    this.startHour = 6,
    this.endHour = 23,
    this.timeInterval = const Duration(minutes: 30),
    this.nonWorkingDays,
    this.timeIntervalHeight = -1,
    this.timeFormat,
    this.timeTextStyle,
    // 日程视图
    this.scheduleViewSettings,
    this.scheduleViewMonthHeaderBuilder,
    // 外观
    this.todayHighlightColor,
    this.selectionDecoration,
    this.cellBorderColor,
    this.headerHeight = 40,
    this.viewHeaderHeight = -1,
    this.headerStyle,
    this.viewHeaderStyle,
    this.monthCellBuilder,
    this.appointmentBuilder,
    this.timeRegionBuilder,
    this.backgroundColor,
    this.todayTextStyle,
    this.calendarTheme,
    // 回调
    this.onViewChanged,
    this.onTap,
    this.onLongPress,
    this.onSelectionChanged,
    // 高级
    this.specialRegions,
    this.blackoutDates,
    this.blackoutDatesTextStyle,
    this.minDate,
    this.maxDate,
    this.showNavigationArrow = false,
    this.showDatePickerButton = false,
    this.showTodayButton = false,
    this.showCurrentTimeIndicator = true,
    this.allowDragAndDrop = false,
    this.onDragEnd,
    this.allowAppointmentResize = false,
    this.onAppointmentResizeEnd,
    this.resourceViewSettings,
    this.loadMoreWidgetBuilder,
  });

  /// 构建月视图设置
  MonthViewSettings _buildMonthViewSettings() {
    if (monthViewSettings != null) return monthViewSettings!;

    return MonthViewSettings(
      showAgenda: showAgenda,
      agendaViewHeight: agendaViewHeight,
      appointmentDisplayMode: appointmentDisplayMode,
      showTrailingAndLeadingDates: showTrailingAndLeadingDates,
      numberOfWeeksInView: numberOfWeeksInView,
      navigationDirection: monthNavigationDirection,
      agendaStyle: agendaStyle ?? const AgendaStyle(),
    );
  }

  /// 构建时间槽视图设置
  TimeSlotViewSettings _buildTimeSlotViewSettings() {
    if (timeSlotViewSettings != null) return timeSlotViewSettings!;

    return TimeSlotViewSettings(
      startHour: startHour,
      endHour: endHour,
      timeInterval: timeInterval,
      nonWorkingDays: nonWorkingDays ?? const <int>[],
      timeIntervalHeight: timeIntervalHeight,
      timeFormat: timeFormat ?? 'h:mm a',
      timeTextStyle: timeTextStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTodayColor = todayHighlightColor ?? theme.primaryColor;
    final effectiveSelectionDecoration = selectionDecoration ??
        BoxDecoration(
          border: Border.all(color: theme.primaryColor, width: 2),
        );

    return SfCalendar(
      // 视图
      view: view,
      controller: controller,
      allowedViews: allowedViews,
      allowViewNavigation: allowViewNavigation,
      initialDisplayDate: initialDisplayDate,
      initialSelectedDate: initialSelectedDate,
      firstDayOfWeek: firstDayOfWeek,
      // 数据源
      dataSource: dataSource,
      // 月视图
      monthViewSettings: _buildMonthViewSettings(),
      // 时间槽
      timeSlotViewSettings: _buildTimeSlotViewSettings(),
      // 日程视图
      scheduleViewSettings:
          scheduleViewSettings ?? const ScheduleViewSettings(),
      scheduleViewMonthHeaderBuilder: scheduleViewMonthHeaderBuilder,
      // 外观
      todayHighlightColor: effectiveTodayColor,
      selectionDecoration: effectiveSelectionDecoration,
      cellBorderColor: cellBorderColor,
      headerHeight: headerHeight,
      viewHeaderHeight: viewHeaderHeight,
      headerStyle: headerStyle ?? const CalendarHeaderStyle(),
      viewHeaderStyle: viewHeaderStyle ?? const ViewHeaderStyle(),
      monthCellBuilder: monthCellBuilder,
      appointmentBuilder: appointmentBuilder,
      timeRegionBuilder: timeRegionBuilder,
      backgroundColor: backgroundColor,
      todayTextStyle: todayTextStyle,
      // 回调
      onViewChanged: onViewChanged,
      onTap: onTap,
      onLongPress: onLongPress,
      onSelectionChanged: onSelectionChanged,
      // 高级
      specialRegions: specialRegions,
      blackoutDates: blackoutDates,
      blackoutDatesTextStyle: blackoutDatesTextStyle,
      minDate: minDate,
      maxDate: maxDate,
      showNavigationArrow: showNavigationArrow,
      showDatePickerButton: showDatePickerButton,
      showTodayButton: showTodayButton,
      showCurrentTimeIndicator: showCurrentTimeIndicator,
      showWeekNumber: showWeekNumber,
      allowDragAndDrop: allowDragAndDrop,
      onDragEnd: onDragEnd,
      allowAppointmentResize: allowAppointmentResize,
      onAppointmentResizeEnd: onAppointmentResizeEnd,
      resourceViewSettings:
          resourceViewSettings ?? const ResourceViewSettings(),
      loadMoreWidgetBuilder: loadMoreWidgetBuilder,
    );
  }
}
