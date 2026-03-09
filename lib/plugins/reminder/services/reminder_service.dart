import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/core/app_initializer.dart';
import '../models/reminder.dart';
import 'reminder_notification_service.dart';

/// 提醒管理服务
/// 负责提醒的 CRUD 操作和数据持久化
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  static const String _storageKey = 'reminders.json';

  List<Reminder> _reminders = [];
  final ReminderNotificationService _notificationService =
      ReminderNotificationService();

  List<Reminder> get reminders => List.unmodifiable(_reminders);

  /// 初始化服务，从存储加载数据
  Future<void> initialize() async {
    await _loadReminders();
    // 恢复所有启用的提醒的调度
    await _rescheduleAllEnabledReminders();
  }

  /// 加载提醒数据
  Future<void> _loadReminders() async {
    try {
      final pluginPath = 'reminder/$_storageKey';
      final data = await globalStorage.readJson(pluginPath);
      if (data != null && data.containsKey('reminders')) {
        _reminders =
            (data['reminders'] as List)
                .map((json) => Reminder.fromJson(json as Map<String, dynamic>))
                .toList();
      }
    } catch (e) {
      debugPrint('[ReminderService] 加载提醒失败: $e');
      _reminders = [];
    }
  }

  /// 保存提醒数据
  Future<void> _saveReminders() async {
    try {
      final pluginPath = 'reminder/$_storageKey';
      final data = {'reminders': _reminders.map((r) => r.toJson()).toList()};
      await globalStorage.writeJson(pluginPath, data);
    } catch (e) {
      debugPrint('[ReminderService] 保存提醒失败: $e');
      rethrow;
    }
  }

  /// 恢复所有启用的提醒的调度
  Future<void> _rescheduleAllEnabledReminders() async {
    for (final reminder in _reminders.where((r) => r.isEnabled)) {
      // 重新计算下次触发时间
      reminder.nextTriggerAt = reminder.calculateNextTriggerTime();
      // 调度通知
      await _notificationService.scheduleReminderNotification(reminder);
    }
    debugPrint('[ReminderService] 已恢复 ${_reminders.where((r) => r.isEnabled).length} 个提醒的调度');
  }

  /// 添加提醒
  Future<Reminder> addReminder({
    required String title,
    required String content,
    String? imageUrl,
    required ReminderFrequency frequency,
    List<int> selectedDays = const [],
    required TimeOfDay time,
    ReminderPushMethod pushMethod = ReminderPushMethod.localNotification,
    String? groupId,
    int priority = 0,
  }) async {
    final reminder = Reminder(
      id: const Uuid().v4(),
      title: title,
      content: content,
      imageUrl: imageUrl,
      frequency: frequency,
      selectedDays: selectedDays,
      time: time,
      pushMethod: pushMethod,
      createdAt: DateTime.now(),
      nextTriggerAt: null, // 将在下面计算
      groupId: groupId,
      priority: priority,
    );

    // 计算下次触发时间
    reminder.nextTriggerAt = reminder.calculateNextTriggerTime();

    _reminders.add(reminder);
    await _saveReminders();

    // 调度通知
    if (reminder.isEnabled) {
      await _notificationService.scheduleReminderNotification(reminder);
    }

    return reminder;
  }

  /// 更新提醒
  Future<void> updateReminder(Reminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      // 重新计算下次触发时间
      reminder.nextTriggerAt = reminder.calculateNextTriggerTime();
      _reminders[index] = reminder;
      await _saveReminders();

      // 重新调度通知
      if (reminder.isEnabled) {
        await _notificationService.scheduleReminderNotification(reminder);
      } else {
        await _notificationService.cancelScheduledNotification(reminder.id);
      }
    }
  }

  /// 删除提醒
  Future<void> deleteReminder(String id) async {
    // 取消调度通知
    await _notificationService.cancelScheduledNotification(id);
    _reminders.removeWhere((r) => r.id == id);
    await _saveReminders();
  }

  /// 切换启用状态
  Future<void> toggleReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final newEnabled = !_reminders[index].isEnabled;
      _reminders[index] = _reminders[index].copyWith(isEnabled: newEnabled);
      await _saveReminders();

      // 更新调度
      if (newEnabled) {
        _reminders[index].nextTriggerAt = _reminders[index].calculateNextTriggerTime();
        await _notificationService.scheduleReminderNotification(_reminders[index]);
      } else {
        await _notificationService.cancelScheduledNotification(id);
      }
    }
  }

  /// 获取启用的提醒列表
  List<Reminder> getEnabledReminders() {
    return _reminders.where((r) => r.isEnabled).toList();
  }

  /// 标记提醒已触发（并调度下一次）
  Future<void> markTriggered(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final reminder = _reminders[index];
      final nextTrigger = reminder.calculateNextTriggerTime();
      _reminders[index] = reminder.copyWith(
        lastTriggeredAt: DateTime.now(),
        nextTriggerAt: nextTrigger,
      );
      await _saveReminders();

      // 调度下一次通知
      if (_reminders[index].isEnabled) {
        await _notificationService.scheduleReminderNotification(_reminders[index]);
      }
    }
  }

  /// 根据 ID 获取提醒
  Reminder? getReminderById(String id) {
    try {
      return _reminders.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 刷新数据（重新加载）
  Future<void> refresh() async {
    await _loadReminders();
  }
}
