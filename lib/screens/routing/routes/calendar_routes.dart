import 'package:flutter/material.dart';
import 'package:Memento/core/app_initializer.dart';
import 'package:Memento/screens/routing/route_definition.dart';
import 'package:Memento/screens/routing/route_helpers.dart';
import 'package:Memento/plugins/calendar/calendar_plugin.dart';
import 'package:Memento/plugins/calendar/screens/calendar_month_selector_screen.dart';
import 'package:Memento/plugins/calendar/widgets/event_detail_card.dart';
import 'package:Memento/plugins/calendar/models/event.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';
import 'package:Memento/plugins/todo/models/models.dart';
import 'package:Memento/core/services/toast_service.dart';

/// Calendar 插件路由注册表
class CalendarRoutes implements RouteRegistry {
  @override
  String get name => 'CalendarRoutes';

  @override
  List<RouteDefinition> get routes => [
        // Calendar 主页面
        RouteDefinition(
          path: '/calendar',
          handler: (settings) => RouteHelpers.createRoute(const CalendarMainView()),
          description: '日历主页面',
        ),
        RouteDefinition(
          path: 'calendar',
          handler: (settings) => RouteHelpers.createRoute(const CalendarMainView()),
          description: '日历主页面（别名）',
        ),

        // 日历月视图小组件配置界面
        RouteDefinition(
          path: '/calendar_month_selector',
          handler: (settings) {
            int? widgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                widgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                widgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              widgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(CalendarMonthSelectorScreen(widgetId: widgetId));
          },
          description: '日历月视图小组件配置界面',
        ),
        RouteDefinition(
          path: 'calendar_month_selector',
          handler: (settings) {
            int? widgetId;

            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final widgetIdValue = args['widgetId'];
              if (widgetIdValue is int) {
                widgetId = widgetIdValue;
              } else if (widgetIdValue is String) {
                widgetId = int.tryParse(widgetIdValue);
              }
            } else if (settings.arguments is int) {
              widgetId = settings.arguments as int;
            }

            return RouteHelpers.createRoute(CalendarMonthSelectorScreen(widgetId: widgetId));
          },
          description: '日历月视图小组件配置界面（别名）',
        ),

        // 日历事件详情路由（从桌面小组件打开）
        RouteDefinition(
          path: '/calendar_month/event',
          handler: (settings) => _handleCalendarEventRoute(settings),
          description: '日历事件详情页面',
        ),
        RouteDefinition(
          path: 'calendar_month/event',
          handler: (settings) => _handleCalendarEventRoute(settings),
          description: '日历事件详情页面（别名）',
        ),
      ];

  static Route<dynamic> _handleCalendarEventRoute(RouteSettings settings) {
    String? eventId;

    if (settings.arguments is Map<String, String>) {
      eventId = (settings.arguments as Map<String, String>)['eventId'];
    } else if (settings.arguments is Map<String, dynamic>) {
      eventId = (settings.arguments as Map<String, dynamic>)['eventId'] as String?;
    }

    if (eventId == null) {
      final uri = Uri.parse(settings.name ?? '');
      eventId = uri.queryParameters['eventId'];
    }

    debugPrint('打开日历事件详情: eventId=$eventId');

    if (eventId == null) {
      return RouteHelpers.createRoute(const CalendarMainView());
    }

    final calendarPlugin = CalendarPlugin.instance;
    if (calendarPlugin == null) {
      debugPrint('CalendarPlugin 未初始化，回退到主视图');
      return RouteHelpers.createRoute(const CalendarMainView());
    }

    final calendarController = calendarPlugin.controller;
    List<CalendarEvent> allEvents = calendarController.getAllEvents();

    CalendarEvent? event = allEvents.where((e) => e.id == eventId).isNotEmpty
        ? allEvents.firstWhere((e) => e.id == eventId)
        : null;

    if (event == null && eventId.startsWith('todo_')) {
      final todoPlugin = TodoPlugin.instance;
      final taskId = eventId.substring(5);
      final task = todoPlugin.taskController.tasks
              .where((t) => t.id == taskId)
              .isNotEmpty
          ? todoPlugin.taskController.tasks.firstWhere((t) => t.id == taskId)
          : null;

      if (task != null) {
        event = _convertTaskToEvent(task);
      }
    }

    if (event != null) {
      final isTodoEvent = event.source == 'todo';
      final taskId = isTodoEvent ? event.id.substring(5) : null;
      final CalendarEvent eventData = event;

      return RouteHelpers.createRoute(
        Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: EventDetailCard(
              event: eventData,
              onEdit: () {
                Navigator.of(navigatorKey.currentContext!).pop();
                if (isTodoEvent && taskId != null) {
                  Toast.warning('任务事件不支持编辑，请前往待办事项中修改');
                } else {
                  calendarPlugin.showEventEditPage(
                    navigatorKey.currentContext!,
                    eventData,
                  );
                }
              },
              onComplete: () {
                Navigator.of(navigatorKey.currentContext!).pop();
                if (isTodoEvent && taskId != null) {
                  final todoPlugin = TodoPlugin.instance;
                  todoPlugin.taskController.updateTaskStatus(
                    taskId,
                    TaskStatus.done,
                  );
                } else {
                  calendarController.completeEvent(eventData);
                }
              },
              onDelete: () {
                Navigator.of(navigatorKey.currentContext!).pop();
                if (isTodoEvent && taskId != null) {
                  final todoPlugin = TodoPlugin.instance;
                  todoPlugin.taskController.updateTaskStatus(
                    taskId,
                    TaskStatus.done,
                  );
                  Toast.success('任务已完成并移入历史记录');
                } else {
                  calendarController.deleteEvent(eventData);
                }
              },
            ),
          ),
        ),
      );
    }

    debugPrint('未找到事件: $eventId');
    return RouteHelpers.createRoute(const CalendarMainView());
  }

  static CalendarEvent _convertTaskToEvent(Task task) {
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = Colors.red.shade300;
        break;
      case TaskPriority.medium:
        priorityColor = Colors.orange.shade300;
        break;
      case TaskPriority.low:
        priorityColor = Colors.blue.shade300;
        break;
    }

    IconData iconData;
    switch (task.status) {
      case TaskStatus.todo:
        iconData = Icons.radio_button_unchecked;
        break;
      case TaskStatus.inProgress:
        iconData = Icons.play_circle_outline;
        break;
      case TaskStatus.done:
        iconData = Icons.check_circle_outline;
        break;
    }

    return CalendarEvent(
      id: 'todo_${task.id}',
      title: task.title,
      description: task.description ?? '',
      startTime: task.startDate ?? task.dueDate ?? DateTime.now(),
      endTime: task.dueDate,
      icon: iconData,
      color: priorityColor,
      source: 'todo',
    );
  }
}
