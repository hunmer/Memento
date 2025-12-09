import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/plugins/todo/controllers/task_controller.dart';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:Memento/plugins/calendar/models/event.dart';

/// TodoEventService 负责从 TodoPlugin 获取任务数据并转换为日历事件
class TodoEventService {
  final TaskController _taskController;

  TodoEventService(this._taskController);

  /// 获取所有带有日期的任务并转换为日历事件
  List<CalendarEvent> getTaskEvents() {
    final tasks = _taskController.tasks;
    final List<CalendarEvent> events = [];

    for (final task in tasks) {
      // 只处理同时设置了开始日期和截止日期的任务
      if (task.startDate != null && task.dueDate != null) {
        // 创建新的日历事件
        final event = CalendarEvent(
          id: 'todo_${task.id}', // 添加前缀以区分来源
          title: task.title,
          description: task.description ?? '',
          startTime: task.startDate!,
          endTime: task.dueDate,
          icon: task.statusIcon, // 使用任务状态图标
          color: _getPriorityColor(task.priority), // 根据任务优先级设置颜色
          source: 'todo', // 标记来源为todo插件
        );
        events.add(event);
      }
    }

    return events;
  }

  /// 根据任务优先级返回对应的颜色
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red.shade300;
      case TaskPriority.medium:
        return Colors.orange.shade300;
      case TaskPriority.low:
        return Colors.blue.shade300;
      // 添加默认颜色
    }
  }
}
