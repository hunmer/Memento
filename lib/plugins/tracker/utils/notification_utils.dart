
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:logging/logging.dart';

class NotificationUtils {
  static final _logger = Logger('NotificationUtils');
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 通知点击回调
  static Function(String?)? onNotificationClicked;

  static Future<void> initialize({Function(String?)? onSelectNotification}) async {
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

    // Windows初始化设置
    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: '目标跟踪提醒',
      appUserModelId: 'com.example.memento.tracker',
      guid: 'd3a8f7c2-1b23-4e5a-9d8f-6e7c5a4b3d21', // 标准GUID格式
    );

    // 统一初始化设置
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      windows: initializationSettingsWindows,
    );
    
    // 初始化插件
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          onNotificationClicked?.call(details.payload);
        }
      },
    );

    // 创建通知渠道(Android 8.0+需要)
    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'tracker_channel',
      '目标跟踪提醒',
      description: '用于目标跟踪的提醒通知',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
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
      // 初始化时区
      tz.initializeTimeZones();
      
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'tracker_channel',
        '目标跟踪提醒',
        channelDescription: '用于目标跟踪的提醒通知',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const WindowsNotificationDetails windowsDetails = WindowsNotificationDetails();

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
        windows: windowsDetails,
      );
      
      // 设置明天的通知时间
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
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
    required int hour,
    required int minute,
    String? payload,
  }) async {
    try {
      await cancelNotification(id);
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
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'tracker_channel',
        '目标跟踪提醒',
        channelDescription: '用于目标跟踪的提醒通知',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const WindowsNotificationDetails windowsDetails = WindowsNotificationDetails();

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
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
