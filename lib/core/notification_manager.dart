import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:logging/logging.dart';

class NotificationManager {
  static final _logger = Logger('NotificationManager');
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 通知点击回调
  static Function(String?)? onNotificationClicked;

  static Future<void> initialize({
    Function(String?)? onSelectNotification,
    String appName = 'Memento',
    String appId = 'com.example.memento',
    String channelId = 'memento_channel',
    String channelName = '提醒通知',
    String channelDescription = '用于应用的提醒通知',
  }) async {
    // 设置点击回调
    onNotificationClicked = onSelectNotification;

    // Android初始化设置
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    // iOS初始化设置
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // macOS初始化设置
    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Windows初始化设置
    final WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
          appName: appName,
          appUserModelId: appId,
          guid: 'd3a8f7c2-1b23-4e5a-9d8f-6e7c5a4b3d21', // 标准GUID格式
        );

    // 统一初始化设置
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: initializationSettingsMacOS,
          windows: initializationSettingsWindows,
        );

    // 初始化插件
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        try {
          if (details.payload != null && onNotificationClicked != null) {
            onNotificationClicked!(details.payload);
          }
        } catch (e) {
          _logger.warning('Error handling notification response', e);
        }
      },
    );

    // 创建通知渠道(Android 8.0+需要)
    await _createNotificationChannel(
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
    );
  }

  static Future<void> _createNotificationChannel({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? channelId = 'memento_channel',
    String? channelName = '提醒通知',
    String? channelDescription = '用于应用的提醒通知',
    bool isDaily = false,
    String? payload,
  }) async {
    try {
      // 初始化时区
      tz.initializeTimeZones();

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId ?? 'memento_channel',
            channelName ?? '提醒通知',
            channelDescription: channelDescription ?? '用于应用的提醒通知',
            importance: Importance.max,
            priority: Priority.high,
          );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const DarwinNotificationDetails macOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const WindowsNotificationDetails windowsDetails =
          WindowsNotificationDetails();

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
        macOS: macOSDetails,
        windows: windowsDetails,
      );

      final now = tz.TZDateTime.now(tz.local);
      var tzScheduledDate = tz.TZDateTime(
        tz.local,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
      );

      if (tzScheduledDate.isBefore(now)) {
        if (isDaily) {
          tzScheduledDate = tzScheduledDate.add(const Duration(days: 1));
        } else {
          _logger.warning('Scheduled date is in the past');
          return;
        }
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        platformDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: isDaily ? DateTimeComponents.time : null,
      );
    } catch (e) {
      _logger.warning('Failed to schedule notification', e);
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      _logger.warning('Failed to cancel notification', e);
    }
  }

  static Future<void> updateNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool isDaily = false,
    String? payload,
  }) async {
    try {
      await cancelNotification(id);
      await scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        isDaily: isDaily,
        payload: payload,
      );
    } catch (e) {
      _logger.warning('Failed to update notification', e);
    }
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? channelId = 'memento_channel',
    String? channelName = '提醒通知',
    String? channelDescription = '用于应用的提醒通知',
    String? payload,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            channelId ?? 'memento_channel',
            channelName ?? '提醒通知',
            channelDescription: channelDescription ?? '用于应用的提醒通知',
            importance: Importance.max,
            priority: Priority.high,
          );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const DarwinNotificationDetails macOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const WindowsNotificationDetails windowsDetails =
          WindowsNotificationDetails();

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
        macOS: macOSDetails,
        windows: windowsDetails,
      );

      await _notificationsPlugin.show(
        0,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      _logger.warning('Failed to show instant notification', e);
    }
  }
}