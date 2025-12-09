import 'dart:convert';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:home_widget/home_widget.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as syncfusion;
import 'package:uuid/uuid.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/core/config_manager.dart';
import 'package:Memento/core/js_bridge/js_bridge_plugin.dart';
import 'package:Memento/plugins/base_plugin.dart';
import './controllers/calendar_controller.dart' as app;
import './models/event.dart';
import './pages/event_edit_page.dart';
import './pages/completed_events_page.dart';
import './pages/event_list_page.dart';
import './widgets/event_detail_card.dart';
import './services/todo_event_service.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';

class CalendarPlugin extends BasePlugin with JSBridgePlugin {
  static CalendarPlugin? _instance;
  static CalendarPlugin get instance {
    if (_instance == null) {
      _instance = PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
      if (_instance == null) {
        throw StateError('CalendarPlugin has not been initialized');
      }
    }
    return _instance!;
  }

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
          controller.refresh();
          // 同步小组件数据
          syncWidgetData();
        });
      }
    }

    // 监听日历事件变化，同步小组件数据
    controller.addListener(() {
      syncWidgetData();
    });

    // 初始同步
    syncWidgetData();

    // 处理小组件中待完成的事件（首次启动时）
    PluginWidgetSyncHelper.instance.syncPendingCalendarEventsOnStartup();
  }

  // ========== 小组件数据同步 ==========

  /// 同步日历月视图小组件数据
  Future<void> syncWidgetData() async {
    // 只在 Android 平台同步
    if (!Platform.isAndroid) return;

    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      // 获取本月第一天是星期几 (1=周一, 7=周日)
      int firstWeekday = firstDayOfMonth.weekday;

      // 获取本月所有事件
      final allEvents = controller.getAllEvents();
      final monthEvents = allEvents.where((event) {
        return event.startTime.isAfter(
              firstDayOfMonth.subtract(const Duration(seconds: 1)),
            ) &&
            event.startTime.isBefore(
              lastDayOfMonth.add(const Duration(days: 1)),
            );
      }).toList();

      // 构建每日事件数据
      final Map<String, List<Map<String, dynamic>>> dayEventsMap = {};

      for (var event in monthEvents) {
        final day = event.startTime.day.toString();
        if (!dayEventsMap.containsKey(day)) {
          dayEventsMap[day] = [];
        }
        dayEventsMap[day]!.add({
          'id': event.id,
          'title': event.title,
          'description': event.description,
          'startTime': event.startTime.toIso8601String(),
          'endTime': event.endTime?.toIso8601String(),
          'completed': false,
        });
      }

      // 按开始时间排序每日事件
      for (var day in dayEventsMap.keys) {
        dayEventsMap[day]!.sort((a, b) {
          final aTime = DateTime.parse(a['startTime'] as String);
          final bTime = DateTime.parse(b['startTime'] as String);
          return aTime.compareTo(bTime);
        });
      }

      // 构建完整的小组件数据
      final widgetData = {
        'year': now.year,
        'month': now.month,
        'daysInMonth': lastDayOfMonth.day,
        'firstWeekday': firstWeekday,
        'today': now.day,
        'dayEvents': dayEventsMap,
      };

      // 保存到 HomeWidget
      final jsonString = jsonEncode(widgetData);
      await HomeWidget.saveWidgetData<String>(
        'calendar_month_widget_data',
        jsonString,
      );

      // 更新小组件
      await HomeWidget.updateWidget(
        name: 'CalendarMonthWidgetProvider',
        qualifiedAndroidName:
            'github.hunmer.memento.widgets.providers.CalendarMonthWidgetProvider',
      );

      debugPrint('日历小组件数据同步成功: ${monthEvents.length} 个事件');
    } catch (e) {
      debugPrint('日历小组件数据同步失败: $e');
    }
  }

  @override
  String? getPluginName(context) {
    return 'calendar_name'.tr;
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
    NavigationHelper.push(context, EventEditPage(
              event: event,
              initialDate: event?.startTime ?? controller.selectedDate,
              onSave: (updatedEvent) {
                if (event != null) {
                  controller.updateEvent(updatedEvent);
                } else {
                  controller.addEvent(updatedEvent);
                }
                // 强制重建界面
                controller.refresh();
              },),
    );
  }

  void showAllEvents(BuildContext context) {
    NavigationHelper.push(context, EventListPage(
              events: controller.events,
              onEventUpdated: (event) {
                showEventEditPage(context, event);
              },
              onEventCompleted: (event) {
                controller.completeEvent(event);
              },
              onEventDeleted: (event) {
                controller.deleteEvent(event);
              },),
    );
  }

  void showCompletedEvents(BuildContext context) {
    NavigationHelper.push(context, CompletedEventsPage(
              completedEvents: controller.completedEvents,),
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

  // ========== 小组件统计方法 ==========

  /// 获取今日事件数量
  int getTodayEventCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return controller.getAllEvents().where((event) {
      return event.startTime.isAfter(
            today.subtract(const Duration(seconds: 1)),
          ) &&
          event.startTime.isBefore(tomorrow);
    }).length;
  }

  /// 获取本周事件数量
  int getWeekEventCount() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return controller.getAllEvents().where((event) {
      return event.startTime.isAfter(
            weekStart.subtract(const Duration(seconds: 1)),
          ) &&
          event.startTime.isBefore(weekEnd);
    }).length;
  }

  /// 获取未完成事件数量（开始时间在未来的事件）
  int getPendingEventCount() {
    final now = DateTime.now();
    return controller.getAllEvents().where((event) {
      return event.startTime.isAfter(now);
    }).length;
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
                    'calendar_name'.tr,
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
                            'calendar_eventCount'.tr,
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
                            'calendar_weekEvents'.tr,
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
                            'calendar_expiredEvents'.tr,
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

      // 事件查找方法
      'findEventBy': _jsFindEventBy,
      'findEventById': _jsFindEventById,
      'findEventByTitle': _jsFindEventByTitle,
    };
  }

  // ==================== 分页控制器 ====================

  /// 分页控制器 - 对列表进行分页处理
  /// @param list 原始数据列表
  /// @param offset 起始位置（默认 0）
  /// @param count 返回数量（默认 100）
  /// @return 分页后的数据，包含 data、total、offset、count、hasMore
  Map<String, dynamic> _paginate<T>(
    List<T> list, {
    int offset = 0,
    int count = 100,
  }) {
    final total = list.length;
    final start = offset.clamp(0, total);
    final end = (start + count).clamp(start, total);
    final data = list.sublist(start, end);

    return {
      'data': data,
      'total': total,
      'offset': start,
      'count': data.length,
      'hasMore': end < total,
    };
  }

  // ==================== JS API 实现 ====================

  /// 获取所有事件（包括 Todo 任务事件）
  /// 支持分页参数: offset, count
  Future<String> _jsGetEvents(Map<String, dynamic> params) async {
    final events = controller.getAllEvents();
    final eventsJson = events.map((e) => e.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        eventsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(eventsJson);
  }

  /// 获取今日事件
  /// 支持分页参数: offset, count
  Future<String> _jsGetTodayEvents(Map<String, dynamic> params) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final events =
        controller.getAllEvents().where((event) {
          return event.startTime.isAfter(
                today.subtract(const Duration(seconds: 1)),
              ) &&
              event.startTime.isBefore(tomorrow);
        }).toList();

    final eventsJson = events.map((e) => e.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        eventsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(eventsJson);
  }

  /// 根据日期范围获取事件
  /// 支持分页参数: offset, count
  Future<String> _jsGetEventsByDateRange(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? startDateStr = params['startDate'];
    if (startDateStr == null || startDateStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: startDate'});
    }

    final String? endDateStr = params['endDate'];
    if (endDateStr == null || endDateStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: endDate'});
    }

    final startDate = DateTime.parse(startDateStr);
    final endDate = DateTime.parse(endDateStr);

    final events =
        controller.getAllEvents().where((event) {
          return event.startTime.isAfter(
                startDate.subtract(const Duration(seconds: 1)),
              ) &&
              event.startTime.isBefore(endDate.add(const Duration(seconds: 1)));
        }).toList();

    final eventsJson = events.map((e) => e.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        eventsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(eventsJson);
  }

  /// 创建事件
  Future<String> _jsCreateEvent(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final String? description = params['description'];
    if (description == null) {
      return jsonEncode({'error': '缺少必需参数: description'});
    }

    final String? startTimeStr = params['startTime'];
    if (startTimeStr == null || startTimeStr.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: startTime'});
    }

    // 提取可选参数
    final String? endTimeStr = params['endTime'];
    final int? iconCodePoint = params['iconCodePoint'];
    final int? colorValue = params['colorValue'];
    final int? reminderMinutes = params['reminderMinutes'];

    final startTime = DateTime.parse(startTimeStr);
    final endTime = endTimeStr != null ? DateTime.parse(endTimeStr) : null;

    final event = CalendarEvent(
      id: const Uuid().v4(),
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      icon:
          iconCodePoint != null
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
  Future<String> _jsUpdateEvent(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? eventId = params['eventId'];
    if (eventId == null || eventId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: eventId'});
    }

    // 提取可选参数
    final String? title = params['title'];
    final String? description = params['description'];
    final String? startTimeStr = params['startTime'];
    final String? endTimeStr = params['endTime'];
    final int? iconCodePoint = params['iconCodePoint'];
    final int? colorValue = params['colorValue'];
    final int? reminderMinutes = params['reminderMinutes'];

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
      icon:
          iconCodePoint != null
              ? IconData(iconCodePoint, fontFamily: 'MaterialIcons')
              : null,
      color: colorValue != null ? Color(colorValue) : null,
      reminderMinutes: reminderMinutes,
    );

    controller.updateEvent(updatedEvent);
    return jsonEncode(updatedEvent.toJson());
  }

  /// 删除事件
  Future<String> _jsDeleteEvent(Map<String, dynamic> params) async {
    try {
      // 提取必需参数并验证
      final String? eventId = params['eventId'];
      if (eventId == null || eventId.isEmpty) {
        return jsonEncode({'success': false, 'error': '缺少必需参数: eventId'});
      }

      final event = controller.events.firstWhere(
        (e) => e.id == eventId,
        orElse: () => throw Exception('Event not found: $eventId'),
      );

      controller.deleteEvent(event);
      return jsonEncode({'success': true, 'eventId': eventId});
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// 完成事件
  Future<String> _jsCompleteEvent(Map<String, dynamic> params) async {
    // 提取必需参数并验证
    final String? eventId = params['eventId'];
    if (eventId == null || eventId.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: eventId'});
    }

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
  /// 支持分页参数: offset, count
  Future<String> _jsGetCompletedEvents(Map<String, dynamic> params) async {
    final events = controller.completedEvents;
    final eventsJson = events.map((e) => e.toJson()).toList();

    // 检查是否需要分页
    final int? offset = params['offset'];
    final int? count = params['count'];

    if (offset != null || count != null) {
      final paginated = _paginate(
        eventsJson,
        offset: offset ?? 0,
        count: count ?? 100,
      );
      return jsonEncode(paginated);
    }

    // 兼容旧版本：无分页参数时返回全部数据
    return jsonEncode(eventsJson);
  }

  // ==================== 事件查找方法 ====================

  /// 通用事件查找
  /// @param params.field 要匹配的字段名 (必需)
  /// @param params.value 要匹配的值 (必需)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindEventBy(Map<String, dynamic> params) async {
    final String? field = params['field'];
    if (field == null || field.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: field'});
    }

    final dynamic value = params['value'];
    if (value == null) {
      return jsonEncode({'error': '缺少必需参数: value'});
    }

    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final events = controller.getAllEvents();
    final List<CalendarEvent> matchedEvents = [];

    for (final event in events) {
      final eventJson = event.toJson();

      // 检查字段是否匹配
      if (eventJson.containsKey(field) && eventJson[field] == value) {
        matchedEvents.add(event);
        if (!findAll) break; // 只找第一个
      }
    }

    if (findAll) {
      final eventsJson = matchedEvents.map((e) => e.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          eventsJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(eventsJson);
    } else {
      if (matchedEvents.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedEvents.first.toJson());
    }
  }

  /// 根据ID查找事件
  /// @param params.id 事件ID (必需)
  Future<String> _jsFindEventById(Map<String, dynamic> params) async {
    final String? id = params['id'];
    if (id == null || id.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: id'});
    }

    final events = controller.getAllEvents();

    try {
      final event = events.firstWhere((e) => e.id == id);
      return jsonEncode(event.toJson());
    } catch (e) {
      return jsonEncode(null);
    }
  }

  /// 根据标题查找事件
  /// @param params.title 事件标题 (必需)
  /// @param params.fuzzy 是否模糊匹配 (可选，默认 false)
  /// @param params.findAll 是否返回所有匹配项 (可选，默认 false)
  /// @param params.offset 分页起始位置 (可选，仅 findAll=true 时有效)
  /// @param params.count 分页返回数量 (可选，仅 findAll=true 时有效，默认 100)
  Future<String> _jsFindEventByTitle(Map<String, dynamic> params) async {
    final String? title = params['title'];
    if (title == null || title.isEmpty) {
      return jsonEncode({'error': '缺少必需参数: title'});
    }

    final bool fuzzy = params['fuzzy'] ?? false;
    final bool findAll = params['findAll'] ?? false;
    final int? offset = params['offset'];
    final int? count = params['count'];

    final events = controller.getAllEvents();
    final List<CalendarEvent> matchedEvents = [];

    for (final event in events) {
      bool matches = false;
      if (fuzzy) {
        matches = event.title.contains(title);
      } else {
        matches = event.title == title;
      }

      if (matches) {
        matchedEvents.add(event);
        if (!findAll) break;
      }
    }

    if (findAll) {
      final eventsJson = matchedEvents.map((e) => e.toJson()).toList();

      // 检查是否需要分页
      if (offset != null || count != null) {
        final paginated = _paginate(
          eventsJson,
          offset: offset ?? 0,
          count: count ?? 100,
        );
        return jsonEncode(paginated);
      }

      return jsonEncode(eventsJson);
    } else {
      if (matchedEvents.isEmpty) {
        return jsonEncode(null);
      }
      return jsonEncode(matchedEvents.first.toJson());
    }
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    plugin = PluginManager.instance.getPlugin('calendar') as CalendarPlugin;
  }

  /// 搜索事件：基于标题和描述进行模糊搜索
  List<CalendarEvent> _searchEvents(String query) {
    if (query.isEmpty) return [];

    final allEvents = plugin.controller.getAllEvents();
    final lowerQuery = query.toLowerCase();

    return allEvents.where((event) {
      return event.title.toLowerCase().contains(lowerQuery) ||
             event.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// 构建搜索结果列表
  Widget _buildSearchResults(List<CalendarEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的事件',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: event.color.withOpacity(0.2),
              child: Icon(event.icon, color: event.color),
            ),
            title: Text(
              event.title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(event.startTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
            onTap: () {
              // 清除搜索并显示事件详情
              setState(() {
                _searchQuery = '';
              });
              plugin.showEventDetails(context, event);
            },
          ),
        );
      },
    );
  }

  /// 格式化日期时间显示
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    String dateStr;
    if (dateTime.isAtSameMomentAs(today)) {
      dateStr = '今天';
    } else if (dateTime.isAtSameMomentAs(tomorrow)) {
      dateStr = '明天';
    } else if (dateTime.isAtSameMomentAs(yesterday)) {
      dateStr = '昨天';
    } else {
      dateStr = '${dateTime.month}-${dateTime.day}';
    }

    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:'
                   '${dateTime.minute.toString().padLeft(2, '0')}';

    return '$dateStr $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: plugin.controller,
      builder: (context, child) {
        // 获取搜索结果
        final searchResults = _searchEvents(_searchQuery);

        return SuperCupertinoNavigationWrapper(
          title: Text(
            'calendar_calendar'.tr,
            style: TextStyle(color: theme.textTheme.titleLarge?.color),
          ),
          largeTitle: 'calendar_calendar'.tr,
          automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: syncfusion.SfCalendar(
                      view: plugin.sfController.view ??
                          syncfusion.CalendarView.month,
                      controller: plugin.sfController,
                      allowedViews: plugin.allowedViews,
                      allowViewNavigation: true,
                      dataSource: _AppointmentDataSource(
                        plugin.getUserAppointments(),
                      ),
                      initialDisplayDate: plugin.controller.focusedMonth,
                      onViewChanged: plugin.onViewChanged,
                      onTap: (details) =>
                          plugin.handleCalendarTap(context, details),
                      monthViewSettings: const syncfusion.MonthViewSettings(
                        showAgenda: true,
                        agendaViewHeight: 200,
                        appointmentDisplayMode:
                            syncfusion.MonthAppointmentDisplayMode.appointment,
                      ),
                      timeSlotViewSettings:
                          const syncfusion.TimeSlotViewSettings(
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
              // FAB
              Positioned(
                right: 16,
                bottom: 16,
                child: OpenContainer<bool>(
                  transitionType: ContainerTransitionType.fade,
                  tappable: false,
                  closedElevation: 0.0,
                  closedShape: const RoundedRectangleBorder(),
                  closedColor: Colors.transparent,
                  openBuilder: (BuildContext context, VoidCallback _) {
                    return EventEditPage(
                      initialDate: plugin.controller.selectedDate,
                      onSave: (event) {
                        plugin.controller.addEvent(event);
                      },
                    );
                  },
                  closedBuilder: (BuildContext context, VoidCallback openContainer) {
                    return FloatingActionButton(
                      onPressed: openContainer,
                      child: const Icon(Icons.add),
                    );
                  },
                ),
              ),
            ],
          ),
          enableLargeTitle: true,
          enableSearchBar: true,
          searchPlaceholder: '搜索事件标题或描述...',
          searchBody: _buildSearchResults(searchResults),
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
          actions: [
            // 跳转到今天按钮
            IconButton(
              icon: Icon(Icons.today, color: theme.iconTheme.color),
              tooltip: 'calendar_backToToday'.tr,
              onPressed: () {
                plugin.sfController.displayDate = DateTime.now();
              },
            ),
            // 查看所有事件按钮
            IconButton(
              icon: Icon(Icons.list_alt, color: theme.iconTheme.color),
              tooltip: 'calendar_allEvents'.tr,
              onPressed: () => plugin.showAllEvents(context),
            ),
            // 查看已完成事件按钮
            IconButton(
              icon: Icon(Icons.done_all, color: theme.iconTheme.color),
              tooltip: 'calendar_completedEvents'.tr,
              onPressed: () => plugin.showCompletedEvents(context),
            ),
          ],
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
