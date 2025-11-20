import 'package:Memento/core/notification_controller.dart';
import 'package:logging/logging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class TrackerNotificationUtils {
  static final _logger = Logger('TrackerNotificationUtils');
  static const String _channelKey = 'tracker_channel';
  static const String _channelName = '目标跟踪提醒';
  static const String _channelDescription = '用于目标跟踪的提醒通知';

  static Future<void> initialize({
    Function(String?)? onSelectNotification,
  }) async {
    // 创建目标跟踪插件专用的通知通道
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: -1, // 用于测试通道是否存在
        channelKey: _channelKey,
        title: '初始化',
        body: '目标跟踪通知通道已创建',
      ),
    ).catchError((error) async {
      // 如果通道不存在，先创建通道
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: _channelKey,
            channelName: _channelName,
            channelDescription: _channelDescription,
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            enableVibration: true,
            playSound: true,
          ),
        ],
      );
    });
  }

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // 如果时间已过，安排到明天
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: _channelKey,
          title: title,
          body: body,
          payload: {'payload': payload ?? ''},
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          hour: hour,
          minute: minute,
          second: 0,
          repeats: true, // 每日重复
        ),
      );
    } catch (e) {
      _logger.warning('Failed to schedule daily notification', e);
    }
  }

  static Future<void> cancelNotification(int id) async {
    await NotificationController.cancelNotification(id);
  }

  static Future<void> updateNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    try {
      // 先取消旧的通知
      await cancelNotification(id);

      // 重新安排新的通知
      await scheduleDailyNotification(
        id: id,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        payload: payload,
      );
    } catch (e) {
      _logger.warning('Failed to update notification', e);
    }
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await NotificationController.createCustomNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      layout: NotificationLayout.Default,
    );
  }
}
