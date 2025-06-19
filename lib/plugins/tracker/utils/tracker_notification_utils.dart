import '../../../core/notification_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

class TrackerNotificationUtils {
  static final _logger = Logger('TrackerNotificationUtils');
  static const String _channelId = 'tracker_channel';
  static const String _channelName = '目标跟踪提醒';
  static const String _channelDescription = '用于目标跟踪的提醒通知';

  static Future<void> initialize({
    Function(String?)? onSelectNotification,
  }) async {
    await NotificationManager.initialize(
      onSelectNotification: onSelectNotification,
      appName: '目标跟踪提醒',
      appId: 'com.example.memento.tracker',
    );

    // 创建目标跟踪插件专用的通知通道
    await NotificationManager.createNotificationChannel(
      channelId: _channelId,
      channelName: _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      enableVibration: true,
      enableSound: true,
    );
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
      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      await NotificationManager.scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        channelId: _channelId,
        isDaily: true,
        payload: payload,
      );
    } catch (e) {
      _logger.warning('Failed to schedule daily notification', e);
    }
  }

  static Future<void> cancelNotification(int id) async {
    await NotificationManager.cancelNotification(id);
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
      final now = DateTime.now();
      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      await NotificationManager.updateNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        isDaily: true,
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
    await NotificationManager.showInstantNotification(
      title: title,
      body: body,
      channelId: _channelId,
      payload: payload,
    );
  }
}
