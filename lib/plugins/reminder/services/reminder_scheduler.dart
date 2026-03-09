import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Memento/core/event/event.dart';
import '../models/reminder.dart';
import 'reminder_service.dart';
import 'reminder_notification_service.dart';

/// 定时调度服务
/// 使用 Timer.periodic 定期检查并触发提醒
class ReminderScheduler {
  static final ReminderScheduler _instance = ReminderScheduler._internal();
  factory ReminderScheduler() => _instance;
  ReminderScheduler._internal();

  final ReminderService _reminderService = ReminderService();
  final ReminderNotificationService _notificationService =
      ReminderNotificationService();

  Timer? _checkTimer;
  static const Duration _checkInterval = Duration(minutes: 1);

  bool _isRunning = false;

  /// 是否正在运行
  bool get isRunning => _isRunning;

  /// 启动调度器
  void start() {
    if (_isRunning) return;

    _isRunning = true;

    // 立即检查一次
    _checkAndTriggerReminders();

    // 启动定时器
    _checkTimer = Timer.periodic(_checkInterval, (_) {
      _checkAndTriggerReminders();
    });

    debugPrint('[ReminderScheduler] 调度器已启动');
  }

  /// 停止调度器
  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isRunning = false;
    debugPrint('[ReminderScheduler] 调度器已停止');
  }

  /// 检查并触发到期的提醒
  Future<void> _checkAndTriggerReminders() async {
    final now = DateTime.now();
    final reminders = _reminderService.getEnabledReminders();

    for (final reminder in reminders) {
      if (reminder.nextTriggerAt == null) continue;

      // 检查是否到达触发时间（允许1分钟误差）
      final difference = now.difference(reminder.nextTriggerAt!);
      if (difference.inMinutes >= 0 && difference.inMinutes < 1) {
        await _triggerReminder(reminder);
      }
    }
  }

  /// 触发提醒
  Future<void> _triggerReminder(Reminder reminder) async {
    debugPrint('[ReminderScheduler] 触发提醒: ${reminder.title}');

    // 发送通知
    await _notificationService.showReminderNotification(reminder);

    // 标记已触发
    await _reminderService.markTriggered(reminder.id);

    // 广播事件
    EventManager.instance.broadcast(
      'reminder_triggered',
      ReminderEventArgs(reminder),
    );
  }

  /// 手动触发提醒（用于测试）
  Future<void> triggerNow(Reminder reminder) async {
    await _triggerReminder(reminder);
  }

  /// 重新调度所有提醒（在设置变更后调用）
  Future<void> rescheduleAll() async {
    // 计算所有提醒的下次触发时间
    for (final reminder in _reminderService.reminders) {
      await _reminderService.updateReminder(reminder);
    }
  }
}

/// 提醒事件参数
class ReminderEventArgs extends EventArgs {
  final Reminder reminder;
  ReminderEventArgs(this.reminder) : super('reminder_triggered');
}
