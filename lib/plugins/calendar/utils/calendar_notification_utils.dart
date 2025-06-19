import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/notification_manager.dart';
import 'package:logging/logging.dart';

class CalendarNotificationUtils {
  static final _logger = Logger('CalendarNotificationUtils');
  static const String _channelId = 'calendar_channel';
  static const String _channelName = '日历事件提醒';
  static const String _channelDescription = '用于日历事件的提醒通知';

  static Future<void> initialize({
    Function(String?)? onSelectNotification,
  }) async {
    await NotificationManager.initialize(
      onSelectNotification: onSelectNotification,
      appName: '日历事件提醒',
      appId: 'com.example.memento.calendar',
    );

    // 创建日历插件专用的通知通道
    await NotificationManager.createNotificationChannel(
      channelId: _channelId,
      channelName: _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      enableVibration: true,
      enableSound: true,
    );
  }

  static Future<void> scheduleEventNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    try {
      await NotificationManager.scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDateTime,
        channelId: _channelId,
        isDaily: false,
        payload: payload,
      );
    } catch (e) {
      _logger.warning('Failed to schedule event notification', e);
    }
  }

  static Future<void> cancelEventNotification(int id) async {
    await NotificationManager.cancelNotification(id);
  }

  static Future<void> updateEventNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    try {
      await NotificationManager.updateNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDateTime,
        isDaily: false,
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
    await NotificationManager.showInstantNotification(
      title: title,
      body: body,
      channelId: _channelId,
      payload: payload,
    );
  }
}
