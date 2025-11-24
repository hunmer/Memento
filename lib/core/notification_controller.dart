import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'event/event.dart';

/// 通知控制器 - 处理 awesome_notifications 的初始化和事件
class NotificationController {
  /// 初始化通知服务
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // 默认图标(Android 会使用 app_icon)
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelGroupKey: 'custom_channel_group',
          channelKey: 'custom_channel',
          channelName: 'Custom Notifications',
          channelDescription: 'Notification channel for custom notifications',
          defaultColor: const Color(0xFF2196F3),
          ledColor: Colors.blue,
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'basic_channel_group',
          channelGroupName: 'Basic Group',
        ),
        NotificationChannelGroup(
          channelGroupKey: 'custom_channel_group',
          channelGroupName: 'Custom Group',
        ),
      ],
      debug: true, // 启用调试日志
    );

    // 设置监听器
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  /// 请求通知权限
  static Future<bool> requestPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return true;
  }

  /// 检查通知权限
  static Future<bool> checkPermission() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// 当通知被创建时调用
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint(
      '通知已创建: ID=${receivedNotification.id}, Title=${receivedNotification.title}',
    );
  }

  /// 当通知被显示时调用
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint(
      '通知已显示: ID=${receivedNotification.id}, Title=${receivedNotification.title}',
    );
  }

  /// 当通知被关闭时调用
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint(
      '通知已关闭: ID=${receivedAction.id}',
    );
  }

  /// 当用户点击通知或通知按钮时调用
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint(
      '通知动作接收: ID=${receivedAction.id}, ButtonKey=${receivedAction.buttonKeyPressed}',
    );

    // 检查是否是活动通知
    if (receivedAction.payload?['type'] == 'activity_reminder') {
      await _handleActivityNotificationAction(receivedAction);
      return;
    }

    // 根据按钮 key 处理不同的逻辑
    if (receivedAction.buttonKeyPressed == 'YES') {
      debugPrint('用户点击了 YES 按钮');
    } else if (receivedAction.buttonKeyPressed == 'NO') {
      debugPrint('用户点击了 NO 按钮');
    } else if (receivedAction.buttonKeyPressed == 'MORE') {
      debugPrint('用户点击了 MORE 按钮');
    } else {
      // 点击通知本身(没有按钮)
      debugPrint('用户点击了通知本体');
    }
  }

  /// 创建基础通知
  static Future<void> createBasicNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  /// 创建带按钮的自定义通知
  static Future<void> createCustomNotification({
    required int id,
    required String title,
    required String body,
    String? bigPicture,
    String? largeIcon,
    NotificationLayout layout = NotificationLayout.Default,
    List<NotificationActionButton>? actionButtons,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'custom_channel',
        title: title,
        body: body,
        notificationLayout: layout,
        bigPicture: bigPicture,
        largeIcon: largeIcon,
      ),
      actionButtons: actionButtons,
    );
  }

  /// 创建带大图的通知
  static Future<void> createBigPictureNotification({
    required int id,
    required String title,
    required String body,
    required String bigPicture,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'custom_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: bigPicture,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'YES',
          label: 'Yes',
          actionType: ActionType.Default,
          color: Colors.green,
        ),
        NotificationActionButton(
          key: 'NO',
          label: 'No',
          actionType: ActionType.Default,
          color: Colors.red,
        ),
        NotificationActionButton(
          key: 'MORE',
          label: 'More Options',
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  /// 取消指定 ID 的通知
  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  /// 取消所有通知
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  /// 获取活动通知列表
  static Future<List<NotificationModel>> getActiveNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }

  /// 处理活动通知的动作
  static Future<void> _handleActivityNotificationAction(
    ReceivedAction receivedAction,
  ) async {
    debugPrint(
      '活动通知动作接收: ID=${receivedAction.id}, ButtonKey=${receivedAction.buttonKeyPressed}',
    );

    if (receivedAction.buttonKeyPressed == 'open_form') {
      // 打开活动表单
      debugPrint('用户点击了"记录活动"按钮');
      _broadcastOpenActivityForm();
    } else if (receivedAction.buttonKeyPressed == 'dismiss') {
      // 忽略通知
      debugPrint('用户点击了"忽略"按钮');
    } else {
      // 点击通知本体
      debugPrint('用户点击了活动通知本体');
      _broadcastOpenActivityForm();
    }
  }

  /// 广播打开活动表单事件
  static void _broadcastOpenActivityForm() {
    try {
      debugPrint('[NotificationController] 广播打开活动表单事件');

      // 使用全局事件管理器广播事件
      eventManager.broadcast('activity_notification_tapped', EventArgs('activity_notification_tapped'));

      debugPrint('[NotificationController] 事件广播成功: activity_notification_tapped');
    } catch (e) {
      debugPrint('[NotificationController] 广播事件失败: $e');
    }
  }
}
