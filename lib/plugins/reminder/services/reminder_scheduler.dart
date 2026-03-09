import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Memento/core/event/event.dart';
import '../models/reminder.dart';
import 'reminder_service.dart';
import 'reminder_notification_service.dart';

/// 定时调度服务
///
/// 主要职责：
/// 1. 在应用运行时检查并处理错过的提醒
/// 2. 标记已触发的提醒
/// 3. 广播提醒事件
///
/// 注意：实际的定时通知由系统的 AwesomeNotifications 调度，
/// 即使应用关闭也能触发。
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

    // 检查是否有错过的提醒
    _checkMissedReminders();

    // 启动定时器作为后备
    _checkTimer = Timer.periodic(_checkInterval, (_) {
      _checkMissedReminders();
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

  /// 检查是否有错过的提醒（应用关闭期间）
  Future<void> _checkMissedReminders() async {
    final now = DateTime.now();
    final reminders = _reminderService.getEnabledReminders();

    for (final reminder in reminders) {
      if (reminder.nextTriggerAt == null) continue;

      // 检查是否有错过的提醒（触发时间已过但还没触发）
      // 如果 nextTriggerAt 已经过去超过1分钟，说明可能错过了
      final difference = now.difference(reminder.nextTriggerAt!);
      if (difference.inMinutes > 1) {
        debugPrint(
          '[ReminderScheduler] 检测到错过的提醒: ${reminder.title}, '
          '原定时间: ${reminder.nextTriggerAt}',
        );
        // 标记已触发并调度下一次
        await _reminderService.markTriggered(reminder.id);
      }
    }
  }

  /// 手动触发提醒（用于测试）
  Future<void> triggerNow(Reminder reminder) async {
    debugPrint('[ReminderScheduler] 手动触发提醒: ${reminder.title}');

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

  /// 重新调度所有提醒
  Future<void> rescheduleAll() async {
    for (final reminder in _reminderService.reminders) {
      if (reminder.isEnabled) {
        reminder.nextTriggerAt = reminder.calculateNextTriggerTime();
        await _notificationService.scheduleReminderNotification(reminder);
      }
    }
    await _reminderService.refresh();
  }
}

/// 提醒事件参数
class ReminderEventArgs extends EventArgs {
  final Reminder reminder;
  ReminderEventArgs(this.reminder) : super('reminder_triggered');
}
