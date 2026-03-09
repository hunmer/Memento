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

  /// 显示提醒通知
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
