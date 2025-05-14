import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as syncfusion;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../core/plugin_manager.dart';
import '../../core/config_manager.dart';
import '../base_plugin.dart';
import './controllers/calendar_controller.dart' as app;
import './models/event.dart';
import './pages/event_edit_page.dart';
import './pages/completed_events_page.dart';
import './pages/event_list_page.dart';
import './widgets/event_detail_card.dart';
import './services/todo_event_service.dart';
import '../todo/controllers/task_controller.dart';
import '../todo/todo_plugin.dart';

class CalendarPlugin extends BasePlugin with ChangeNotifier {
  late final app.CalendarController _controller;
  late final syncfusion.CalendarController _sfController;
  late CalendarDataSource _events;
  TodoEventService? _todoEventService;

  final List<syncfusion.CalendarView> _allowedViews = <syncfusion.CalendarView>[
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
  String get name => '日历';

  @override
  String get version => '1.0.0';

  @override
  String get description => '日历和事件管理插件';

  @override
  String get author => 'Memento';

  @override
  Future<void> initialize() async {
    _controller = app.CalendarController(storageManager);
    _sfController = syncfusion.CalendarController();
    
    // 从存储中读取上次使用的视图
    final viewData = await storageManager.read('calendar_last_view');
    final String? lastView = viewData?['view'] as String?;
    if (lastView != null) {
      _sfController.view = _getCalendarViewFromString(lastView);
    } else {
      _sfController.view = syncfusion.CalendarView.month;
    }
    await _controller.events; // 触发事件加载
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

  void _onViewChanged(syncfusion.ViewChangedDetails details) async {
    // 保存最后使用的视图
    await storageManager.write(
      'calendar_last_view',
      {'view': _getStringFromCalendarView(_sfController.view!)},
    );
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
        _todoEventService = TodoEventService(taskController);
        // 监听任务变化
        taskController.addListener(() {
          _controller.notifyListeners();
        });
      }
    }
  }

  void _showEventDetails(BuildContext context, CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => EventDetailCard(
        event: event,
        onEdit: () {
          Navigator.pop(context);
          _showEventEditPage(context, event);
        },
        onComplete: () {
          Navigator.pop(context);
          _controller.completeEvent(event);
        },
        onDelete: () {
          Navigator.pop(context);
          _controller.deleteEvent(event);
        },
      ),
    );
  }

  void _showEventEditPage(BuildContext context, [CalendarEvent? event]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventEditPage(
          event: event,
          initialDate: event?.startTime ?? _controller.selectedDate,
          onSave: (updatedEvent) {
            if (event != null) {
              _controller.updateEvent(updatedEvent);
            } else {
              _controller.addEvent(updatedEvent);
            }
            // 强制重建界面
            _controller.notifyListeners();
          },
        ),
      ),
    );
  }

  void _showAllEvents(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventListPage(
          events: _controller.events,
          onEventUpdated: (event) {
            _showEventEditPage(context, event);
          },
          onEventCompleted: (event) {
            _controller.completeEvent(event);
          },
          onEventDeleted: (event) {
            _controller.deleteEvent(event);
          },
        ),
      ),
    );
  }

  void _showCompletedEvents(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompletedEventsPage(
          completedEvents: _controller.completedEvents,
        ),
      ),
    );
  }

  // 将 CalendarEvent 转换为 Appointment
  List<syncfusion.Appointment> _getUserAppointments() {
    final List<CalendarEvent> allEvents = [
      ..._controller.events,
      if (_todoEventService != null) ..._todoEventService!.getTaskEvents(),
    ];
    
    return allEvents.map((event) => syncfusion.Appointment(
      startTime: event.startTime,
      endTime: event.endTime ?? event.startTime.add(const Duration(hours: 1)),
      subject: event.title,
      notes: event.description,
      color: event.color,
      isAllDay: false, // 设置为false，确保显示为横条而不是圆点
      id: event.id,
    )).toList();
  }

  // 处理日历点击事件
  void _handleCalendarTap(BuildContext context, syncfusion.CalendarTapDetails details) {
    if (details.targetElement == syncfusion.CalendarElement.calendarCell) {
      _controller.selectDate(details.date!);
    } else if (details.targetElement == syncfusion.CalendarElement.appointment) {
      final String eventId = details.appointments?.first.id as String;
      
      // 检查是否为Todo任务事件
      if (eventId.startsWith('todo_')) {
        // Todo任务事件只显示，不允许编辑
        final events = _todoEventService?.getTaskEvents();
        if (events != null) {
          final event = events.firstWhere(
            (event) => event.id == eventId,
            orElse: () => throw Exception('Event not found'),
          );
          _showEventDetails(context, event);
        }
      } else {
        // 普通日历事件
        final event = _controller.events.firstWhere(
          (event) => event.id == eventId,
          orElse: () => throw Exception('Event not found'),
        );
        _showEventDetails(context, event);
      }
    }
  }

  @override
  Widget buildMainView(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => PluginManager.toHomeScreen(context),
            ),
            title: const Text('日历'),
            actions: [
              // 跳转到今天按钮
              IconButton(
                icon: const Icon(Icons.today),
                tooltip: '回到今天',
                onPressed: () {
                  _sfController.displayDate = DateTime.now();
                },
              ),
              // 查看所有事件按钮
              IconButton(
                icon: const Icon(Icons.list_alt),
                tooltip: '所有事件',
                onPressed: () => _showAllEvents(context),
              ),
              // 查看已完成事件按钮
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: '已完成事件',
                onPressed: () => _showCompletedEvents(context),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: syncfusion.SfCalendar(
                  view: _sfController.view ?? syncfusion.CalendarView.month,
                  controller: _sfController,
                  allowedViews: _allowedViews,
                  allowViewNavigation: true,
                  dataSource: _AppointmentDataSource(_getUserAppointments()),
                  initialDisplayDate: _controller.focusedMonth,
                  onViewChanged: _onViewChanged,
                  onTap: (details) => _handleCalendarTap(context, details),
                  monthViewSettings: const syncfusion.MonthViewSettings(
                    showAgenda: true,
                    agendaViewHeight: 200,
                    appointmentDisplayMode: syncfusion.MonthAppointmentDisplayMode.appointment,
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
            onPressed: () => _showEventEditPage(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  @override
  Future<void> uninstall() async {
    await storageManager.delete('calendar_events');
    await storageManager.delete('calendar_last_view');
  }
}

class _AppointmentDataSource extends syncfusion.CalendarDataSource {
  _AppointmentDataSource(List<syncfusion.Appointment> appointments) {
    this.appointments = appointments;
  }
}