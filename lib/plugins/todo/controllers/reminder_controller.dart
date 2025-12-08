import 'package:flutter/material.dart';
import 'package:Memento/plugins/todo/models/task.dart';

class ReminderController extends ChangeNotifier {
  // 存储待处理的提醒
  final Map<String, List<DateTime>> _pendingReminders = {};

  // 添加提醒
  void addReminder(Task task, DateTime reminderTime) {
    if (!_pendingReminders.containsKey(task.id)) {
      _pendingReminders[task.id] = [];
    }
    _pendingReminders[task.id]!.add(reminderTime);
    _scheduleReminder(task, reminderTime);
    notifyListeners();
  }

  // 移除提醒
  void removeReminder(String taskId, DateTime reminderTime) {
    _pendingReminders[taskId]?.remove(reminderTime);
    if (_pendingReminders[taskId]?.isEmpty ?? false) {
      _pendingReminders.remove(taskId);
    }
    notifyListeners();
  }

  // 清除任务的所有提醒
  void clearReminders(String taskId) {
    _pendingReminders.remove(taskId);
    notifyListeners();
  }

  // 获取任务的所有提醒
  List<DateTime> getReminders(String taskId) {
    return _pendingReminders[taskId] ?? [];
  }

  // 检查任务是否有提醒
  bool hasReminders(String taskId) {
    return _pendingReminders.containsKey(taskId) && 
           _pendingReminders[taskId]!.isNotEmpty;
  }

  // 调度提醒
  void _scheduleReminder(Task task, DateTime reminderTime) {
    // TODO: 实现本地通知功能
    // 这里需要集成本地通知插件，如 flutter_local_notifications
    // 示例代码：
    /*
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.schedule(
      task.id.hashCode,
      'Task Reminder',
      task.title,
      reminderTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_channel',
          'Todo Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
    */
  }

  // 处理错过的提醒
  void handleMissedReminder(Task task, DateTime reminderTime) {
    if (task.status != TaskStatus.done) {
      // 一小时后重新提醒
      final newReminderTime = DateTime.now().add(const Duration(hours: 1));
      addReminder(task, newReminderTime);
    }
  }
}