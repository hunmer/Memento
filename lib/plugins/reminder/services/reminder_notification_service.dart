import 'package:flutter/material.dart';
import 'package:Memento/core/notification_controller.dart';
import 'package:memento_notifications/memento_notifications.dart';
import '../models/reminder.dart';
import 'package:Memento/utils/image_utils.dart';

/// 提醒通知服务
/// 封装通知控制器的提醒专用方法
class ReminderNotificationService {
  static final ReminderNotificationService _instance =
      ReminderNotificationService._internal();
  factory ReminderNotificationService() => _instance;
  ReminderNotificationService._internal();

  /// 调度提醒通知（应用关闭后也能触发）
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!reminder.isEnabled || reminder.nextTriggerAt == null) return;

    final notificationId = reminder.id.hashCode;

    try {
      // 先取消之前的调度
      await MementoNotifications.instance.cancel(notificationId);

      String? bigPicture;
      if (reminder.imageUrl != null && reminder.imageUrl!.isNotEmpty) {
        try {
          bigPicture = await ImageUtils.getAbsolutePath(reminder.imageUrl!);
        } catch (e) {
          debugPrint('[ReminderNotificationService] 获取图片路径失败: $e');
        }
      }

      // 使用 MementoNotifications 调度定时通知
      await MementoNotifications.instance.scheduleNotification(
        id: notificationId,
        title: reminder.title,
        body: reminder.content,
        scheduledDate: reminder.nextTriggerAt!,
        channelKey: 'custom_channel',
        bigPicture: bigPicture,
        payload: {
          'type': 'reminder',
          'reminderId': reminder.id,
        },
        preciseAlarm: true,
        allowWhileIdle: true,
      );

      debugPrint(
        '[ReminderNotificationService] 已调度通知: ${reminder.title}, '
        '时间: ${reminder.nextTriggerAt}',
      );
    } catch (e) {
      debugPrint('[ReminderNotificationService] 调度通知失败: $e');
    }
  }

  /// 取消提醒的调度通知
  Future<void> cancelScheduledNotification(String reminderId) async {
    final notificationId = reminderId.hashCode;
    await MementoNotifications.instance.cancel(notificationId);
    debugPrint('[ReminderNotificationService] 已取消调度通知: $reminderId');
  }

  /// 取消所有调度通知
  Future<void> cancelAllScheduledNotifications() async {
    await MementoNotifications.instance.cancelAll();
    debugPrint('[ReminderNotificationService] 已取消所有调度通知');
  }

  /// 立即显示提醒通知（用于测试或应用内触发）
  Future<void> showReminderNotification(Reminder reminder) async {
    // 根据推送方式选择不同的通知方式
    switch (reminder.pushMethod) {
      case ReminderPushMethod.localNotification:
        await _showLocalNotification(reminder);
        break;
      case ReminderPushMethod.fcm:
        // FCM 占位 - 未来实现
        await _showLocalNotification(reminder);
        debugPrint('[ReminderNotificationService] FCM 推送暂未实现，使用本地通知');
        break;
      case ReminderPushMethod.both:
        await _showLocalNotification(reminder);
        // FCM 占位
        break;
    }
  }

  /// 显示本地通知
  Future<void> _showLocalNotification(Reminder reminder) async {
    // 使用哈希生成通知ID
    final notificationId = reminder.id.hashCode;

    try {
      if (reminder.imageUrl != null && reminder.imageUrl!.isNotEmpty) {
        // 带图片的大图通知
        String? absolutePath;
        try {
          absolutePath = await ImageUtils.getAbsolutePath(reminder.imageUrl!);
        } catch (e) {
          debugPrint('[ReminderNotificationService] 获取图片路径失败: $e');
        }

        await NotificationController.createCustomNotification(
          id: notificationId,
          title: reminder.title,
          body: reminder.content,
          bigPicture: absolutePath,
          layout: MementoNotificationLayout.bigPicture,
          actionButtons: const [
            MementoNotificationButton(
              key: 'dismiss',
              label: '关闭',
              actionType: MementoButtonActionType.dismissAction,
            ),
          ],
        );
      } else {
        // 基础通知
        await NotificationController.createCustomNotification(
          id: notificationId,
          title: reminder.title,
          body: reminder.content,
          actionButtons: const [
            MementoNotificationButton(
              key: 'dismiss',
              label: '关闭',
              actionType: MementoButtonActionType.dismissAction,
            ),
          ],
        );
      }
    } catch (e) {
      debugPrint('[ReminderNotificationService] 发送通知失败: $e');
    }
  }

  /// 取消提醒通知
  Future<void> cancelReminderNotification(String reminderId) async {
    final notificationId = reminderId.hashCode;
    await NotificationController.cancelNotification(notificationId);
  }
}
