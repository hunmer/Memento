import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:Memento/plugins/activity/models/activity_record.dart';
import 'package:Memento/plugins/activity/services/activity_service.dart';
import 'package:Memento/plugins/activity/screens/activity_timeline_screen/controllers/activity_controller.dart';
import 'package:Memento/widgets/memento_sf_calendar/memento_sf_calendar.dart';

/// 活动日历视图页面
/// 显示活动在日历上的分布，点击活动可编辑
class ActivityCalendarScreen extends StatefulWidget {
  final ActivityService activityService;

  const ActivityCalendarScreen({super.key, required this.activityService});

  @override
  State<ActivityCalendarScreen> createState() => _ActivityCalendarScreenState();
}

class _ActivityCalendarScreenState extends State<ActivityCalendarScreen> {
  late CalendarController _calendarController;
  List<ActivityRecord> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    // 初始化当前日期
    _calendarController.displayDate = DateTime.now();
    _calendarController.selectedDate = DateTime.now();
    _loadActivities();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);

    // 默认加载当前月的活动
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final activities = await widget.activityService.getActivitiesForRange(
      startOfMonth,
      endOfMonth,
    );

    setState(() {
      _activities = activities;
      _isLoading = false;
    });
  }

  /// 格式化时间范围，如 "10:00-12:00"
  String _formatTimeRange(DateTime start, DateTime end) {
    final startHour = start.hour.toString().padLeft(2, '0');
    final startMinute = start.minute.toString().padLeft(2, '0');
    final endHour = end.hour.toString().padLeft(2, '0');
    final endMinute = end.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute-$endHour:$endMinute';
  }

  /// 获取活动颜色：优先使用活动本身的颜色，否则基于标签生成颜色
  Color _getActivityColor(BuildContext context, ActivityRecord activity) {
    // 优先使用活动本身的颜色
    if (activity.color != null) {
      return activity.color!;
    }

    // 如果没有标签，使用主题色
    if (activity.tags.isEmpty) {
      return Theme.of(context).primaryColor;
    }

    // 基于第一个标签生成颜色
    final colors = [
      Colors.blue.shade400,
      Colors.indigo.shade400,
      Colors.orange.shade400,
      Colors.green.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.red.shade400,
      Colors.amber.shade400,
      Colors.cyan.shade400,
    ];

    // 使用标签的 hashCode 来选择颜色
    final colorIndex = activity.tags.first.hashCode.abs() % colors.length;
    return colors[colorIndex];
  }

  Future<void> _loadActivitiesForRange(DateTime start, DateTime end) async {
    final activities = await widget.activityService.getActivitiesForRange(
      start,
      end,
    );

    setState(() {
      _activities = activities;
    });
  }

  void _onViewChanged(ViewChangedDetails details) {
    // 当视图改变时，加载对应日期范围的活动
    final visibleDates = details.visibleDates;
    if (visibleDates.isNotEmpty) {
      final start = visibleDates.first;
      final end = visibleDates.last;
      _loadActivitiesForRange(start, end);
    }
  }

  void _onCalendarTap(CalendarTapDetails details) {
    if (details.appointments != null && details.appointments!.isNotEmpty) {
      final appointment = details.appointments!.first;
      if (appointment is ActivityAppointment) {
        // 创建临时 controller 来调用 editActivity
        final controller = ActivityController(
          activityService: widget.activityService,
          onActivitiesChanged: () {},
        );
        controller.editActivity(context, appointment.activity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('活动日历'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              _calendarController.displayDate = DateTime.now();
              _loadActivities();
            },
            tooltip: '今天',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : MementoSfCalendar(
                controller: _calendarController,
                view: CalendarView.month,
                allowedViews: const [
                  CalendarView.day,
                  CalendarView.week,
                  CalendarView.workWeek,
                  CalendarView.timelineDay,
                  CalendarView.timelineWeek,
                  CalendarView.timelineWorkWeek,
                  CalendarView.month,
                  CalendarView.schedule,
                ],
                showAgenda: true,
                agendaViewHeight: 200,
                appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                firstDayOfWeek: 1,
                nonWorkingDays: const [6, 7], // 周六、周日不显示
                viewHeaderHeight: 50, // 时间线视图需要更高的头部
                viewHeaderStyle: ViewHeaderStyle(
                  dayTextStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  dateTextStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  monthTextStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  height: 50, // 垂直显示时需要更高
                ),
                scheduleViewSettings: const ScheduleViewSettings(
                  appointmentTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  hideEmptyScheduleWeek: false,
                  scheduleViewHeight: 200,
                ),
                dataSource: ActivityCalendarDataSource(_activities),
                onViewChanged: _onViewChanged,
                onTap: _onCalendarTap,
                todayHighlightColor: theme.primaryColor,
                appointmentBuilder: (context, calendarAppointmentDetails) {
                  final appointment =
                      calendarAppointmentDetails.appointments.first;
                  if (appointment is ActivityAppointment) {
                    final activity = appointment.activity;
                    // 颜色分配逻辑：优先使用活动颜色，否则基于标签生成颜色
                    final itemColor = _getActivityColor(context, activity);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: itemColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        [
                          activity.title,
                          if (activity.tags.isNotEmpty) activity.tags.join(' '),
                          if (activity.description != null &&
                              activity.description!.isNotEmpty)
                            activity.description,
                          _formatTimeRange(activity.startTime, activity.endTime),
                        ].join(' '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ActivityController.showAddActivityScreen(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 活动日程数据源适配器
class ActivityCalendarDataSource extends CalendarDataSource {
  ActivityCalendarDataSource(List<ActivityRecord> activities) {
    final appointments = <Appointment>[];

    for (final activity in activities) {
      appointments.add(
        ActivityAppointment(
          startTime: activity.startTime,
          endTime: activity.endTime,
          subject: activity.title,
          color: activity.color ?? Colors.blue,
          activity: activity,
        ),
      );
    }

    this.appointments = appointments;
  }
}

/// 活动日程（包含活动记录的引用）
class ActivityAppointment extends Appointment {
  final ActivityRecord activity;

  ActivityAppointment({
    required DateTime startTime,
    required DateTime endTime,
    required String subject,
    required Color color,
    required this.activity,
  }) : super(
         startTime: startTime,
         endTime: endTime,
         subject: subject,
         color: color,
       );
}
