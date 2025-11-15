import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as syncfusion;
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../../core/js_bridge/js_bridge_plugin.dart';
import '../base_plugin.dart';
import './controllers/calendar_controller.dart' as app;
import './models/event.dart';
import './pages/event_edit_page.dart';
import './pages/completed_events_page.dart';
import './pages/event_list_page.dart';
import './widgets/event_detail_card.dart';
import './services/todo_event_service.dart';
import '../todo/todo_plugin.dart';
import './l10n/calendar_localizations.dart';
import './controls/prompt_controller.dart';

class CalendarPlugin extends BasePlugin with JSBridgePlugin {
  // 总控制器，管理所有日历相关服务
  late final app.CalendarController controller;
  // SyncFusion日历控制器
  late final syncfusion.CalendarController sfController;

  final List<syncfusion.CalendarView> allowedViews = <syncfusion.CalendarView>[
    syncfusion.CalendarView.day,
    syncfusion.CalendarView.week,
    syncfusion.CalendarView.workWeek,
    syncfusion.CalendarView.timelineDay,
    syncfusion.CalendarView.timelineWeek,
    syncfusion.CalendarView.timelineWorkWeek,
    syncfusion.CalendarView.month,
    syncfusion.CalendarView.schedule,
  ];

  @override
  String get id => 'calendar';

  @override
  Color get color => const Color.fromARGB(255, 211, 91, 91);

  @override
  IconData get icon => Icons.calendar_month;

  @override
  Future<void> initialize() async {
    // 初始化总控制器
    controller = app.CalendarController(storageManager);
    sfController = syncfusion.CalendarController();

    // 从存储中读取上次使用的视图
    final viewData = await storageManager.read('calendar/calendar_last_view');
    final String? lastView = viewData?['view'] as String?;
    if (lastView != null) {
      sfController.view = _getCalendarViewFromString(lastView);
    } else {
      sfController.view = syncfusion.CalendarView.month;
    }

    // 注册 JS API（最后一步）
    await registerJSAPI();

    // 初始化 Prompt Controller
    final promptController = CalendarPromptController(this);
    promptController.initialize();
  }

  syncfusion.CalendarView _getCalendarViewFromString(String viewString) {
    switch (viewString) {
      case 'day':
        return syncfusion.CalendarView.day;
      case 'week':
        return syncfusion.CalendarView.week;
      case 'workWeek':
        return syncfusion.CalendarView.workWeek;
      case 'month':
        return syncfusion.CalendarView.month;
      case 'timelineDay':
        return syncfusion.CalendarView.timelineDay;
      case 'timelineWeek':
        return syncfusion.CalendarView.timelineWeek;
      case 'timelineWorkWeek':
        return syncfusion.CalendarView.timelineWorkWeek;
      case 'schedule':
        return syncfusion.CalendarView.schedule;
      default:
        return syncfusion.CalendarView.month;
    }
  }

  String _getStringFromCalendarView(syncfusion.CalendarView view) {
    switch (view) {
      case syncfusion.CalendarView.day:
        return 'day';
      case syncfusion.CalendarView.week:
        return 'week';
      case syncfusion.CalendarView.workWeek:
        return 'workWeek';
      case syncfusion.CalendarView.month:
        return 'month';
      case syncfusion.CalendarView.timelineDay:
        return 'timelineDay';
      case syncfusion.CalendarView.timelineWeek:
        return 'timelineWeek';
      case syncfusion.CalendarView.timelineWorkWeek:
        return 'timelineWorkWeek';
      case syncfusion.CalendarView.schedule:
        return 'schedule';
      default:
        return 'month';
    }
  }

  void onViewChanged(syncfusion.ViewChangedDetails details) async {
    // 保存最后使用的视图
    await storageManager.write('calendar/calendar_last_view', {
      'view': _getStringFromCalendarView(sfController.view!),
    });
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    await initialize();

    // 获取Todo插件的TaskController实例
    final todoPlugin = pluginManager.getPlugin('todo') as TodoPlugin?;
    if (todoPlugin != null) {
      final taskController = todoPlugin.taskController;
      if (taskController != null) {
        // 创建TodoEventService并设置到总控制器
        final todoEventService = TodoEventService(taskController);
        controller.setTodoEventService(todoEventService);

        // 监听任务变化
        taskController.addListener(() {
          controller.notifyListeners();
        });
      }
    }
  }

  @override
  String? getPluginName(context) {
    return CalendarLocalizations.of(context).name;
  }

  void showEventDetails(BuildContext context, CalendarEvent event) {
    showDialog(
      context: context,
      builder:
          (context) => EventDetailCard(
            event: event,
            onEdit: () {
              Navigator.pop(context);
              showEventEditPage(context, event);
            },
            onComplete: () {
              Navigator.pop(context);
              controller.completeEvent(event);
            },
            onDelete: () {
              Navigator.pop(context);
              controller.deleteEvent(event);
            },
          ),
    );
  }

  void showEventEditPage(BuildContext context, [CalendarEvent? event]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => EventEditPage(
              event: event,
              initialDate: event?.startTime ?? controller.selectedDate,
              onSave: (updatedEvent) {
                if (event != null) {
                  controller.updateEvent(updatedEvent);
                } else {
                  controller.addEvent(updatedEvent);
                }
                // 强制重建界面
                controller.notifyListeners();
              },
            ),
      ),
    );
  }

  void showAllEvents(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => EventListPage(
              events: controller.events,
              onEventUpdated: (event) {
                showEventEditPage(context, event);
              },
              onEventCompleted: (event) {
                controller.completeEvent(event);
              },
              onEventDeleted: (event) {
                controller.deleteEvent(event);
              },
            ),
      ),
    );
  }

  void showCompletedEvents(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => CompletedEventsPage(
              completedEvents: controller.completedEvents,
            ),
      ),
    );
  }

  // 将 CalendarEvent 转换为 Appointment
  List<syncfusion.Appointment> getUserAppointments() {
    // 使用总控制器获取所有事件（包括普通事件和Todo任务事件）
    final List<CalendarEvent> allEvents = controller.getAllEvents();

    return allEvents
        .map(
          (event) => syncfusion.Appointment(
            startTime: event.startTime,
            endTime:
                event.endTime ?? event.startTime.add(const Duration(hours: 1)),
            subject: event.title,
            notes: event.description,
            color: event.color,
            isAllDay: false, // 设置为false，确保显示为横条而不是圆点
            id: event.id,
          ),
        )
        .toList();
  }

  // 处理日历点击事件
  void handleCalendarTap(
    BuildContext context,
    syncfusion.CalendarTapDetails details,
  ) {
    if (details.targetElement == syncfusion.CalendarElement.calendarCell) {
      controller.selectDate(details.date!);
    } else if (details.targetElement ==
        syncfusion.CalendarElement.appointment) {
      final String eventId = details.appointments?.first.id as String;

      // 检查是否为Todo任务事件
      if (eventId.startsWith('todo_')) {
        // Todo任务事件只显示，不允许编辑
        final todoEventService = controller.todoEventService;
        if (todoEventService != null) {
          final events = todoEventService.getTaskEvents();
          final event = events.firstWhere(
            (event) => event.id == eventId,
            orElse: () => throw Exception('Event not found'),
          );
          showEventDetails(context, event);
        }
      } else {
        // 普通日历事件
        final event = controller.events.firstWhere(
          (event) => event.id == eventId,
          orElse: () => throw Exception('Event not found'),
        );
        showEventDetails(context, event);
      }
    }
  }

  @override
  Widget buildMainView(BuildContext context) {
    return CalendarMainView();
  }

  // 获取所有活动数量
  int _getEventCount() {
    return controller.getAllEvents().length;
  }

  // 获取7天内的活动数量
  int _getUpcomingEventCount() {
    final now = DateTime.now();
    final sevenDaysLater = now.add(const Duration(days: 7));
    return controller.getAllEvents().where((event) {
      return event.startTime.isAfter(now) &&
          event.startTime.isBefore(sevenDaysLater);
    }).length;
  }

  // 获取过期活动数量
  int _getExpiredEventCount() {
    final now = DateTime.now();
    return controller.getAllEvents().where((event) {
      return event.startTime.isBefore(now);
    }).length;
  }

  @override
  Widget? buildCardView(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部图标和标题
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    CalendarLocalizations.of(context).name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 统计信息卡片
              Column(
                children: [
                  // 第一行 - 活动数量和7天活动
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 活动数量
                      Column(
                        children: [
                          Text(
                            CalendarLocalizations.of(context).eventCount,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            _getEventCount().toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // 7天活动
                      Column(
                        children: [
                          Text(
                            CalendarLocalizations.of(context).weekEvents,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            _getUpcomingEventCount().toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 第二行 - 过期活动
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            CalendarLocalizations.of(context).expiredEvents,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            _getExpiredEventCount().toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Future<void> uninstall() async {
    await storageManager.delete('calendar/calendar_events');
    await storageManager.delete('calendar/calendar_last_view');
  }

  // ==================== JS API 定义 ====================

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 事件查询
      'getEvents': _jsGetEvents,
      'getTodayEvents': _jsGetTodayEvents,
      'getEventsByDateRange': _jsGetEventsByDateRange,

      // 事件操作
      'createEvent': _jsCreateEvent,
      'updateEvent': _jsUpdateEvent,
      'deleteEvent': _jsDeleteEvent,
      'completeEvent': _jsCompleteEvent,

      // 已完成事件
      'getCompletedEvents': _jsGetCompletedEvents,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有事件（包括 Todo 任务事件）
  Future<String> _jsGetEvents() async {
    final events = controller.getAllEvents();
    final eventsJson = events.map((e) => e.toJson()).toList();
    return jsonEncode(eventsJson);
  }

  /// 获取今日事件
  Future<String> _jsGetTodayEvents() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final events = controller.getAllEvents().where((event) {
      return event.startTime.isAfter(today.subtract(const Duration(seconds: 1))) &&
          event.startTime.isBefore(tomorrow);
    }).toList();

    final eventsJson = events.map((e) => e.toJson()).toList();
    return jsonEncode(eventsJson);
  }

  /// 根据日期范围获取事件
  /// 参数：startDate (ISO8601), endDate (ISO8601)
  Future<String> _jsGetEventsByDateRange(String startDateStr, String endDateStr) async {
    final startDate = DateTime.parse(startDateStr);
    final endDate = DateTime.parse(endDateStr);

    final events = controller.getAllEvents().where((event) {
      return event.startTime.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          event.startTime.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();

    final eventsJson = events.map((e) => e.toJson()).toList();
    return jsonEncode(eventsJson);
  }

  /// 创建事件
  /// 参数：title, description, startTime (ISO8601), endTime (ISO8601, optional),
  ///       iconCodePoint (int, optional), colorValue (int, optional), reminderMinutes (int, optional)
  Future<String> _jsCreateEvent(
    String title,
    String description,
    String startTimeStr, [
    String? endTimeStr,
    int? iconCodePoint,
    int? colorValue,
    int? reminderMinutes,
  ]) async {
    final startTime = DateTime.parse(startTimeStr);
    final endTime = endTimeStr != null ? DateTime.parse(endTimeStr) : null;

    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      icon: iconCodePoint != null
          ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
          : Icons.event,
      color: colorValue != null ? Color(colorValue) : color,
      source: 'default',
      reminderMinutes: reminderMinutes,
    );

    controller.addEvent(event);
    return jsonEncode(event.toJson());
  }

  /// 更新事件
  /// 参数：eventId, title (optional), description (optional), startTime (ISO8601, optional),
  ///       endTime (ISO8601, optional), iconCodePoint (int, optional),
  ///       colorValue (int, optional), reminderMinutes (int, optional)
  Future<String> _jsUpdateEvent(
    String eventId, [
    String? title,
    String? description,
    String? startTimeStr,
    String? endTimeStr,
    int? iconCodePoint,
    int? colorValue,
    int? reminderMinutes,
  ]) async {
    // 查找事件
    final existingEvent = controller.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Event not found: $eventId'),
    );

    // 构建更新后的事件
    final updatedEvent = existingEvent.copyWith(
      title: title,
      description: description,
      startTime: startTimeStr != null ? DateTime.parse(startTimeStr) : null,
      endTime: endTimeStr != null ? DateTime.parse(endTimeStr) : null,
      icon: iconCodePoint != null
          ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
          : null,
      color: colorValue != null ? Color(colorValue) : null,
      reminderMinutes: reminderMinutes,
    );

    controller.updateEvent(updatedEvent);
    return jsonEncode(updatedEvent.toJson());
  }

  /// 删除事件
  /// 参数：eventId
  Future<bool> _jsDeleteEvent(String eventId) async {
    final event = controller.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Event not found: $eventId'),
    );

    controller.deleteEvent(event);
    return true;
  }

  /// 完成事件
  /// 参数：eventId
  Future<String> _jsCompleteEvent(String eventId) async {
    final event = controller.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw Exception('Event not found: $eventId'),
    );

    controller.completeEvent(event);

    // 返回完成后的事件（包含 completedTime）
    final completedEvent = controller.completedEvents.firstWhere(
      (e) => e.id == eventId,
    );
    return jsonEncode(completedEvent.toJson());
  }

  /// 获取已完成事件
  Future<String> _jsGetCompletedEvents() async {
    final events = controller.completedEvents;
    final eventsJson = events.map((e) => e.toJson()).toList();
    return jsonEncode(eventsJson);
  }
}

/// 日历插件主视图
class CalendarMainView extends StatefulWidget {
  const CalendarMainView({super.key});

  @override
  State<CalendarMainView> createState() => _CalendarMainViewState();
}

class _CalendarMainViewState extends State<CalendarMainView> {
  late CalendarPlugin plugin;

  @override
  void initState() {
    super.initState();
    plugin = PluginManager.instance.getPlugin('calendar') as CalendarPlugin;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: plugin.controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => PluginManager.toHomeScreen(context),
            ),
            title: Text(CalendarLocalizations.of(context).calendar),
            actions: [
              // 跳转到今天按钮
              IconButton(
                icon: const Icon(Icons.today),
                tooltip: CalendarLocalizations.of(context).backToToday,
                onPressed: () {
                  plugin.sfController.displayDate = DateTime.now();
                },
              ),
              // 查看所有事件按钮
              IconButton(
                icon: const Icon(Icons.list_alt),
                tooltip: CalendarLocalizations.of(context).allEvents,
                onPressed: () => plugin.showAllEvents(context),
              ),
              // 查看已完成事件按钮
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: CalendarLocalizations.of(context).completedEvents,

                onPressed: () => plugin.showCompletedEvents(context),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: syncfusion.SfCalendar(
                  view:
                      plugin.sfController.view ?? syncfusion.CalendarView.month,
                  controller: plugin.sfController,
                  allowedViews: plugin.allowedViews,
                  allowViewNavigation: true,
                  dataSource: _AppointmentDataSource(
                    plugin.getUserAppointments(),
                  ),
                  initialDisplayDate: plugin.controller.focusedMonth,
                  onViewChanged: plugin.onViewChanged,
                  onTap:
                      (details) => plugin.handleCalendarTap(context, details),
                  monthViewSettings: const syncfusion.MonthViewSettings(
                    showAgenda: true,
                    agendaViewHeight: 200,
                    appointmentDisplayMode:
                        syncfusion.MonthAppointmentDisplayMode.appointment,
                  ),
                  timeSlotViewSettings: const syncfusion.TimeSlotViewSettings(
                    startHour: 6,
                    endHour: 23,
                    timeInterval: Duration(minutes: 30),
                  ),
                  todayHighlightColor: Theme.of(context).primaryColor,
                  selectionDecoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => plugin.showEventEditPage(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _AppointmentDataSource extends syncfusion.CalendarDataSource {
  _AppointmentDataSource(List<syncfusion.Appointment> appointments) {
    this.appointments = appointments;
  }
}
