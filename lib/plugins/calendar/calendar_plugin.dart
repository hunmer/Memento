import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:home_widget/home_widget.dart';
import 'package:Memento/utils/platform_utils.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as syncfusion;
import 'package:Memento/widgets/memento_sf_calendar/memento_sf_calendar.dart';
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
import 'package:Memento/core/services/plugin_widget_sync_helper.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/core/services/plugin_data_selector/index.dart';
import 'package:Memento/core/route/route_history_manager.dart';

// UseCase 架构导入
import 'package:shared_models/usecases/calendar/calendar_usecase.dart';
import './repositories/client_calendar_repository.dart';

// 代码分离：JS API 和数据选择器
part 'calendar_js_api.dart';
part 'calendar_data_selectors.dart';

class CalendarPlugin extends BasePlugin with JSBridgePlugin {
  static CalendarPlugin? _instance;
  static CalendarPlugin get instance {
    if (_instance == null) {
      _instance =
          PluginManager.instance.getPlugin('calendar') as CalendarPlugin?;
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
  // UseCase 实例，用于业务逻辑
  late final CalendarUseCase calendarUseCase;

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

    // 初始化 UseCase
    final repository = ClientCalendarRepository(
      controller: controller,
      pluginColor: color,
    );
    calendarUseCase = CalendarUseCase(repository);

    // 从存储中读取上次使用的视图
    final viewData = await storageManager.read('calendar/calendar_last_view');
    final String? lastView = viewData?['view'] as String?;
    if (lastView != null) {
      sfController.view = _getCalendarViewFromString(lastView);
    } else {
      sfController.view = syncfusion.CalendarView.month;
    }

    // 注册数据选择器
    _registerDataSelectors();
  }

  @override
  Map<String, Function> defineJSAPI() {
    return {
      // 事件查询
      'getEvents': _jsGetEvents,
      'getTodayEvents': _jsGetTodayEvents,
      'getEventsByDateRange': _jsGetEventsByDateRange,
      'getUpcoming': _jsGetUpcoming,

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

  void onViewChanged(
    syncfusion.ViewChangedDetails details,
    VoidCallback? updateRouteContext,
  ) async {
    // 保存最后使用的视图
    await storageManager.write('calendar/calendar_last_view', {
      'view': _getStringFromCalendarView(sfController.view!),
    });

    // 更新路由上下文
    if (updateRouteContext != null) {
      updateRouteContext();
    }
  }

  @override
  Future<void> registerToApp(
    PluginManager pluginManager,
    ConfigManager configManager,
  ) async {
    // 加载系统日历事件
    await controller.loadSystemEvents();

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
    if (!PlatformUtils.isAndroid) return;

    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      // 获取本月第一天是星期几 (1=周一, 7=周日)
      int firstWeekday = firstDayOfMonth.weekday;

      // 获取本月所有事件
      final allEvents = controller.getAllEvents();
      final monthEvents =
          allEvents.where((event) {
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
    // 更新路由上下文
    final dateStr =
        '${event.startTime.year}-${event.startTime.month.toString().padLeft(2, '0')}-${event.startTime.day.toString().padLeft(2, '0')}';
    RouteHistoryManager.updateCurrentContext(
      pageId: '/calendar_event_detail',
      title: '事件详情 - ${event.title}',
      params: {
        'eventId': event.id,
        'eventTitle': event.title,
        'startDate': dateStr,
        'source': event.source,
      },
    );

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
    NavigationHelper.push(
      context,
      EventEditPage(
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
        },
      ),
    );
  }

  void showAllEvents(BuildContext context) {
    NavigationHelper.push(
      context,
      EventListPage(
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
    );
  }

  void showCompletedEvents(BuildContext context) {
    NavigationHelper.push(
      context,
      CompletedEventsPage(completedEvents: controller.completedEvents),
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

      // 查找事件（包括系统日历事件）
      final allEvents = controller.getAllEvents();
      try {
        final event = allEvents.firstWhere(
          (event) => event.id == eventId,
          orElse: () => throw Exception('Event not found'),
        );
        showEventDetails(context, event);
      } catch (e) {
        debugPrint('CalendarPlugin: 事件未找到: $eventId');
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
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    plugin = PluginManager.instance.getPlugin('calendar') as CalendarPlugin;

    // ✅ 每次进入日历界面时自动刷新系统事件
    _refreshSystemEvents();

    // 初始化时设置路由上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateRouteContext();
    });
  }

  /// 更新路由上下文,使"询问当前上下文"功能能获取到当前日历视图状态
  void _updateRouteContext() {
    final displayDate = plugin.sfController.displayDate ?? DateTime.now();
    final view = plugin.sfController.view ?? syncfusion.CalendarView.month;

    String viewMode;
    String timeRange;

    switch (view) {
      case syncfusion.CalendarView.day:
        viewMode = '日视图';
        timeRange =
            '${displayDate.year}-${displayDate.month.toString().padLeft(2, '0')}-${displayDate.day.toString().padLeft(2, '0')}';
        break;
      case syncfusion.CalendarView.week:
      case syncfusion.CalendarView.workWeek:
        viewMode = view == syncfusion.CalendarView.week ? '周视图' : '工作周视图';
        final weekStart = displayDate.subtract(
          Duration(days: displayDate.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));
        timeRange =
            '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')} 至 ${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}';
        break;
      case syncfusion.CalendarView.month:
        viewMode = '月视图';
        timeRange =
            '${displayDate.year}-${displayDate.month.toString().padLeft(2, '0')}';
        break;
      case syncfusion.CalendarView.schedule:
        viewMode = '日程视图';
        timeRange =
            '${displayDate.year}-${displayDate.month.toString().padLeft(2, '0')}';
        break;
      case syncfusion.CalendarView.timelineDay:
        viewMode = '时间轴日视图';
        timeRange =
            '${displayDate.year}-${displayDate.month.toString().padLeft(2, '0')}-${displayDate.day.toString().padLeft(2, '0')}';
        break;
      case syncfusion.CalendarView.timelineWeek:
      case syncfusion.CalendarView.timelineWorkWeek:
        viewMode =
            view == syncfusion.CalendarView.timelineWeek
                ? '时间轴周视图'
                : '时间轴工作周视图';
        final weekStart = displayDate.subtract(
          Duration(days: displayDate.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));
        timeRange =
            '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')} 至 ${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}';
        break;
      default:
        viewMode = '未知视图';
        timeRange =
            '${displayDate.year}-${displayDate.month.toString().padLeft(2, '0')}';
    }

    RouteHistoryManager.updateCurrentContext(
      pageId: '/calendar_main',
      title: '日历 - $viewMode',
      params: {'viewMode': viewMode, 'timeRange': timeRange},
    );
  }

  /// 刷新系统日历事件
  Future<void> _refreshSystemEvents() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await plugin.controller.loadSystemEvents();
    } catch (e) {
      debugPrint('CalendarMainView: 刷新系统事件失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
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
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的事件',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(event.startTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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

    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:'
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
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: MementoSfCalendar(
                      view:
                          plugin.sfController.view ??
                          syncfusion.CalendarView.month,
                      controller: plugin.sfController,
                      allowedViews: plugin.allowedViews,
                      allowViewNavigation: true,
                      dataSource: _AppointmentDataSource(
                        plugin.getUserAppointments(),
                      ),
                      initialDisplayDate: plugin.controller.focusedMonth,
                      onViewChanged:
                          (details) => plugin.onViewChanged(
                            details,
                            _updateRouteContext,
                          ),
                      onTap:
                          (details) =>
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
                child: FloatingActionButton(
                  onPressed: () {
                    NavigationHelper.openContainer<bool>(
                      context,
                      (context) => EventEditPage(
                        initialDate: plugin.controller.selectedDate,
                        onSave: (event) {
                          plugin.controller.addEvent(event);
                        },
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          enableLargeTitle: true,
          enableSearchBar: true,
          searchPlaceholder: 'calendar_searchPlaceholder'.tr,
          searchBody: _buildSearchResults(searchResults),
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
          actions: [
            // 刷新系统事件按钮
            IconButton(
              icon:
                  _isRefreshing
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.iconTheme.color ?? Colors.grey,
                          ),
                        ),
                      )
                      : Icon(Icons.refresh, color: theme.iconTheme.color),
              tooltip: _isRefreshing ? '正在刷新...' : '刷新日历事件',
              onPressed: _isRefreshing ? null : _refreshSystemEvents,
            ),
            // 跳转到今天按钮
            IconButton(
              icon: Icon(Icons.today, color: theme.iconTheme.color),
              tooltip: 'calendar_backToToday'.tr,
              onPressed: () {
                plugin.sfController.displayDate = DateTime.now();
                // 更新路由上下文
                _updateRouteContext();
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
