/// 待办插件 - 公共小组件数据提供者
library;

import 'dart:ui' show Color;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:Memento/plugins/todo/todo_plugin.dart';

/// 提供公共小组件的数据
class TodoCommandWidgetsProvider {
  /// 获取公共小组件数据
  static Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
    Map<String, dynamic> data,
  ) async {
    final plugin = PluginManager.instance.getPlugin('todo') as TodoPlugin?;
    if (plugin == null) return {};

    final taskController = plugin.taskController;
    final tasks = taskController.tasks;

    return {
      // 圆角任务进度小组件
      'roundedTaskProgress': _buildRoundedTaskProgressData(tasks),

      // 任务列表卡片
      'taskListCard': _buildTaskListCardData(tasks),

      // 彩色标签任务卡片
      'colorTagTaskCard': _buildColorTagTaskCardData(tasks),

      // 即将到来的任务小组件
      'upcomingTasksWidget': _buildUpcomingTasksData(tasks),

      // 每日待办列表小组件
      'dailyTodoListCard': _buildDailyTodoListData(tasks),

      // 圆角提醒事项列表
      'roundedRemindersList': _buildRoundedRemindersData(tasks),
    };
  }

  /// 构建圆角任务进度小组件数据
  static Map<String, dynamic> _buildRoundedTaskProgressData(List<Task> tasks) {
    final completedTasks = tasks.where((t) => t.status == TaskStatus.done).length;
    final pendingTasks = tasks
        .where((t) => t.status != TaskStatus.done)
        .take(5)
        .map((t) => t.title)
        .toList();

    return {
      'title': '今日任务',
      'subtitle': '完成进度',
      'completedTasks': completedTasks,
      'totalTasks': tasks.length,
      'pendingTasks': pendingTasks,
      'commentCount': 0,
      'attachmentCount': 0,
      'teamAvatars': <String>[],
    };
  }

  /// 构建任务列表卡片数据
  static Map<String, dynamic> _buildTaskListCardData(List<Task> tasks) {
    final pendingTasks = tasks
        .where((t) => t.status != TaskStatus.done)
        .take(5)
        .map((t) => t.title)
        .toList();
    final moreCount = tasks.where((t) => t.status != TaskStatus.done).length - 5;

    return {
      'icon': Icons.format_list_bulleted.codePoint.toString(),
      'iconBackgroundColor': 0xFF5A72EA,
      'count': pendingTasks.length,
      'countLabel': '待办',
      'items': pendingTasks,
      'moreCount': moreCount > 0 ? moreCount : 0,
    };
  }

  /// 构建彩色标签任务卡片数据
  static Map<String, dynamic> _buildColorTagTaskCardData(List<Task> tasks) {
    final pendingTasks = tasks
        .where((t) => t.status != TaskStatus.done)
        .take(4)
        .map((t) {
          final color = getPriorityColor(t.priority);
          return {
            'title': t.title,
            'color': color.value,
            'tag': t.tags.isNotEmpty ? t.tags.first : '',
          };
        }).toList();
    final moreCount = tasks.where((t) => t.status != TaskStatus.done).length - 4;

    return {
      'taskCount': pendingTasks.length,
      'label': '待办事项',
      'tasks': pendingTasks,
      'moreCount': moreCount > 0 ? moreCount : 0,
    };
  }

  /// 构建即将到来的任务小组件数据
  static Map<String, dynamic> _buildUpcomingTasksData(List<Task> tasks) {
    final now = DateTime.now();
    final upcomingTasks = tasks
        .where((t) =>
            t.status != TaskStatus.done &&
            t.dueDate != null &&
            t.dueDate!.isAfter(now))
        .take(5)
        .map((t) {
          final color = getPriorityColor(t.priority);
          return {
            'title': t.title,
            'color': color.value,
            'tag': t.tags.isNotEmpty ? t.tags.first : '',
          };
        }).toList();
    final moreCount = tasks
            .where((t) =>
                t.status != TaskStatus.done &&
                t.dueDate != null &&
                t.dueDate!.isAfter(now))
            .length -
        5;

    return {
      'taskCount': upcomingTasks.length,
      'title': '即将到来',
      'tasks': upcomingTasks,
      'moreCount': moreCount > 0 ? moreCount : 0,
    };
  }

  /// 构建每日待办列表小组件数据
  static Map<String, dynamic> _buildDailyTodoListData(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final time = DateFormat('HH:mm').format(now);

    final todoTasks = tasks
        .where((t) =>
            t.status != TaskStatus.done &&
            (t.startDate == null || t.startDate!.isBefore(today.add(const Duration(days: 1)))))
        .take(5)
        .map((t) => {
              'title': t.title,
              'isCompleted': t.status == TaskStatus.done,
            }).toList();

    return {
      'date': DateFormat('EEEE, MMM d').format(now),
      'time': time,
      'tasks': todoTasks,
      'reminder': {
        'text': '记得完成任务',
        'hashtag': '#待办',
        'hashtagEmoji': '📋',
      },
    };
  }

  /// 构建圆角提醒事项列表数据
  static Map<String, dynamic> _buildRoundedRemindersData(List<Task> tasks) {
    final pendingTasks = tasks
        .where((t) =>
            t.status != TaskStatus.done &&
            t.reminders.isNotEmpty)
        .take(5)
        .map((t) => {
              'text': t.title,
              'isCompleted': false,
            }).toList();

    final totalReminders = tasks.where((t) =>
        t.status != TaskStatus.done &&
        t.reminders.isNotEmpty).length;

    return {
      'itemCount': totalReminders,
      'title': '提醒事项',
      'items': pendingTasks,
    };
  }

  /// 获取优先级颜色
  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.q1:
        return const Color(0xFFEF4444); // red
      case TaskPriority.q2:
        return const Color(0xFF10B981); // green
      case TaskPriority.q3:
        return const Color(0xFFF59E0B); // orange
      case TaskPriority.q4:
        return const Color(0xFF3B82F6); // blue
    }
  }
}
