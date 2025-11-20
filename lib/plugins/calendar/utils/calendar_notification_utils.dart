import 'package:Memento/core/notification_controller.dart';
import 'package:logging/logging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class CalendarNotificationUtils {
  static final _logger = Logger('CalendarNotificationUtils');
  static const String _channelKey = 'calendar_channel';
  static const String _channelName = '日历事件提醒';
  static const String _channelDescription = '用于日历事件的提醒通知';

  static Future<void> initialize({
    Function(String?)? onSelectNotification,
  }) async {
    // 创建日历插件专用的通知通道
    await AwesomeNotifications()
        .createNotification(
          content: NotificationContent(
            id: -1, // 用于测试通道是否存在
            channelKey: _channelKey,
            title: '初始化',
            body: '日历通知通道已创建',
          ),
          // ignore: body_might_complete_normally_catch_error
        )
        .catchError((error) async {
          // 如果通道不存在，先创建通道
          await AwesomeNotifications().initialize(null, [
            NotificationChannel(
              channelKey: _channelKey,
              channelName: _channelName,
              channelDescription: _channelDescription,
              defaultColor: const Color(0xFF2196F3),
              ledColor: Colors.blue,
              importance: NotificationImportance.Max,
              enableVibration: true,
              playSound: true,
            ),
          ]);
        });
  }

  static Future<void> scheduleEventNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    try {
      // 仅当提醒时间在未来时才设置通知
      if (scheduledDateTime.isBefore(DateTime.now())) {
        _logger.info('Scheduled time is in the past, skipping notification');
        return;
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
        schedule: NotificationCalendar.fromDate(date: scheduledDateTime),
      );
    } catch (e) {
      _logger.warning('Failed to schedule event notification', e);
    }
  }

  static Future<void> cancelEventNotification(int id) async {
    await NotificationController.cancelNotification(id);
  }

  static Future<void> updateEventNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    try {
      // 先取消旧的通知
      await cancelEventNotification(id);

      // 重新安排新的通知
      await scheduleEventNotification(
        id: id,
        title: title,
        body: body,
        scheduledDateTime: scheduledDateTime,
        payload: payload,
      );
    } catch (e) {
      _logger.warning('Failed to update event notification', e);
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
