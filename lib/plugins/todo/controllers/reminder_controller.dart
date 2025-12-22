import 'package:flutter/material.dart';
import 'package:Memento/plugins/todo/models/task.dart';
import 'package:Memento/plugins/calendar/services/system_calendar_manager.dart';

/// 提醒控制器
/// 使用系统日历管理器来实现提醒功能
class ReminderController extends ChangeNotifier {
  // 存储待处理的提醒
  final Map<String, List<DateTime>> _pendingReminders = {};

  // 存储任务ID到提醒事件ID的映射
  final Map<String, List<String>> _reminderEventIds = {};

  // 系统日历管理器实例
  final SystemCalendarManager _calendarManager = SystemCalendarManager.instance;

  /// 初始化系统日历管理器
  Future<bool> initialize() async {
    return await _calendarManager.initialize();
  }

  /// 添加提醒
  Future<void> addReminder(Task task, DateTime reminderTime) async {
    if (!_pendingReminders.containsKey(task.id)) {
      _pendingReminders[task.id] = [];
    }
    _pendingReminders[task.id]!.add(reminderTime);

    // 创建提醒事件并添加到系统日历
    final eventId = await _scheduleReminder(task, reminderTime);
    if (eventId != null) {
      _reminderEventIds.putIfAbsent(task.id, () => []).add(eventId);
    }

    notifyListeners();
  }

  /// 移除提醒
  Future<void> removeReminder(String taskId, DateTime reminderTime) async {
    _pendingReminders[taskId]?.remove(reminderTime);

    // 找到对应的提醒事件ID并删除
    final eventId = 'reminder_${taskId}_${reminderTime.millisecondsSinceEpoch}';
    await _calendarManager.deleteEventFromSystem(eventId);

    // 从映射中移除
    _reminderEventIds[taskId]?.remove(eventId);

    if (_pendingReminders[taskId]?.isEmpty ?? false) {
      _pendingReminders.remove(taskId);
      _reminderEventIds.remove(taskId);
    }
    notifyListeners();
  }

  /// 清除任务的所有提醒
  Future<void> clearReminders(String taskId) async {
    final eventIds = _reminderEventIds[taskId];
    if (eventIds != null) {
      for (final eventId in eventIds) {
        await _calendarManager.deleteEventFromSystem(eventId);
      }
      _reminderEventIds.remove(taskId);
    }

    _pendingReminders.remove(taskId);
    notifyListeners();
  }

  /// 获取任务的所有提醒
  List<DateTime> getReminders(String taskId) {
    return _pendingReminders[taskId] ?? [];
  }

  /// 检查任务是否有提醒
  bool hasReminders(String taskId) {
    return _pendingReminders.containsKey(taskId) &&
        _pendingReminders[taskId]!.isNotEmpty;
  }

  /// 使用系统日历调度提醒
  Future<String?> _scheduleReminder(Task task, DateTime reminderTime) async {
    // todo 使用主动消息推送
    return '';
  }

  /// 处理错过的提醒
  Future<void> handleMissedReminder(Task task, DateTime reminderTime) async {
    if (task.status != TaskStatus.done) {
      // 一小时后重新提醒
      final newReminderTime = DateTime.now().add(const Duration(hours: 1));
      await addReminder(task, newReminderTime);
    }
  }

  /// 检查系统日历权限
  Future<bool> checkCalendarPermissions() async {
    return await _calendarManager.checkPermissions();
  }
}
