import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

import 'notification_channel.dart';
import 'notification_content.dart';
import 'notification_action.dart';
import 'notification_listener.dart';

/// Memento 通知管理器
///
/// 封装 awesome_notifications，提供简洁的通知 API。
class MementoNotifications {
  static final MementoNotifications _instance = MementoNotifications._internal();

  /// 单例实例
  static MementoNotifications get instance => _instance;

  MementoNotifications._internal();

  bool _isInitialized = false;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 事件监听器
  MementoNotificationListeners? _listeners;

  /// 初始化通知服务
  ///
  /// [channels] 通知通道列表
  /// [channelGroups] 通知通道组列表
  /// [debug] 是否启用调试日志
  Future<void> initialize({
    List<MementoNotificationChannel>? channels,
    List<MementoNotificationChannelGroup>? channelGroups,
    bool debug = false,
  }) async {
    if (_isInitialized) return;

    // 转换通道配置
    final awesomeChannels = channels?.map(_convertChannel).toList() ?? [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic notifications',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ];

    // 转换通道组配置
    final awesomeGroups = channelGroups?.map(_convertChannelGroup).toList() ?? [
      NotificationChannelGroup(
        channelGroupKey: 'basic_channel_group',
        channelGroupName: 'Basic Group',
      ),
    ];

    await AwesomeNotifications().initialize(
      null, // 默认图标
      awesomeChannels,
      channelGroups: awesomeGroups,
      debug: debug,
    );

    // 设置监听器
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );

    _isInitialized = true;
    debugPrint('[MementoNotifications] 初始化完成');
  }

  /// 设置事件监听器
  void setListeners(MementoNotificationListeners listeners) {
    _listeners = listeners;
  }

  /// 请求通知权限
  Future<bool> requestPermission() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      return await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return true;
  }

  /// 检查通知权限
  Future<bool> checkPermission() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// 显示通知
  ///
  /// [id] 通知唯一标识
  /// [title] 通知标题
  /// [body] 通知正文
  /// [channelKey] 通知通道标识
  /// [layout] 通知布局类型
  /// [bigPicture] 大图 URL
  /// [largeIcon] 大图标 URL
  /// [buttons] 通知按钮列表
  /// [payload] 自定义数据
  /// [autoDismissible] 是否自动取消
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelKey = 'basic_channel',
    MementoNotificationLayout layout = MementoNotificationLayout.basic,
    String? bigPicture,
    String? largeIcon,
    List<MementoNotificationButton>? buttons,
    Map<String, String>? payload,
    bool autoDismissible = true,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: title,
        body: body,
        notificationLayout: _convertLayout(layout),
        bigPicture: bigPicture,
        largeIcon: largeIcon,
        payload: payload,
        autoDismissible: autoDismissible,
      ),
      actionButtons: buttons?.map(_convertButton).toList(),
    );
  }

  /// 取消指定通知
  Future<void> cancel(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }

  /// 获取已调度的通知列表
  Future<List<MementoScheduledNotification>> getScheduledNotifications() async {
    final notifications = await AwesomeNotifications().listScheduledNotifications();
    return notifications.map((n) => MementoScheduledNotification(
      id: n.content?.id ?? 0,
      title: n.content?.title,
      body: n.content?.body,
      scheduledDate: null, // NotificationSchedule 不直接暴露 createdDate
    )).toList();
  }

  // ==================== 内部转换方法 ====================

  NotificationChannel _convertChannel(MementoNotificationChannel channel) {
    return NotificationChannel(
      channelGroupKey: channel.groupKey,
      channelKey: channel.key,
      channelName: channel.name,
      channelDescription: channel.description,
      defaultColor: channel.defaultColor,
      ledColor: channel.ledColor,
      importance: _convertImportance(channel.importance),
      playSound: channel.playSound,
      enableVibration: channel.enableVibration,
      enableLights: channel.enableLights,
    );
  }

  NotificationChannelGroup _convertChannelGroup(MementoNotificationChannelGroup group) {
    return NotificationChannelGroup(
      channelGroupKey: group.key,
      channelGroupName: group.name,
    );
  }

  NotificationImportance _convertImportance(MementoNotificationImportance importance) {
    switch (importance) {
      case MementoNotificationImportance.none:
        return NotificationImportance.None;
      case MementoNotificationImportance.min:
        return NotificationImportance.Min;
      case MementoNotificationImportance.low:
        return NotificationImportance.Low;
      case MementoNotificationImportance.defaultImportance:
        return NotificationImportance.Default;
      case MementoNotificationImportance.high:
        return NotificationImportance.High;
      case MementoNotificationImportance.max:
        return NotificationImportance.Max;
    }
  }

  NotificationLayout _convertLayout(MementoNotificationLayout layout) {
    switch (layout) {
      case MementoNotificationLayout.basic:
        return NotificationLayout.Default;
      case MementoNotificationLayout.bigPicture:
        return NotificationLayout.BigPicture;
      case MementoNotificationLayout.bigText:
        return NotificationLayout.BigText;
      case MementoNotificationLayout.inbox:
        return NotificationLayout.Inbox;
      case MementoNotificationLayout.progressBar:
        return NotificationLayout.ProgressBar;
      case MementoNotificationLayout.mediaPlayer:
        return NotificationLayout.MediaPlayer;
      case MementoNotificationLayout.messaging:
        return NotificationLayout.Messaging;
    }
  }

  NotificationActionButton _convertButton(MementoNotificationButton button) {
    return NotificationActionButton(
      key: button.key,
      label: button.label,
      actionType: _convertButtonActionType(button.actionType),
      color: button.color,
      enabled: button.enabled,
      autoDismissible: button.autoDismissible,
      requireInputText: button.requireInputText,
    );
  }

  ActionType _convertButtonActionType(MementoButtonActionType type) {
    switch (type) {
      case MementoButtonActionType.defaultAction:
        return ActionType.Default;
      case MementoButtonActionType.silentAction:
        return ActionType.SilentAction;
      case MementoButtonActionType.silentBackgroundAction:
        return ActionType.SilentBackgroundAction;
      case MementoButtonActionType.keepOnTop:
        return ActionType.KeepOnTop;
      case MementoButtonActionType.disabledAction:
        return ActionType.DisabledAction;
      case MementoButtonActionType.dismissAction:
        return ActionType.DismissAction;
      case MementoButtonActionType.inputField:
        // InputField 已弃用，使用 Default + requireInputText
        return ActionType.Default;
    }
  }

  // ==================== 静态回调方法 ====================

  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('[MementoNotifications] 通知已创建: ID=${receivedNotification.id}');

    final listener = _instance._listeners?.onCreated;
    if (listener != null) {
      await listener(MementoReceivedNotification(
        id: receivedNotification.id,
        title: receivedNotification.title,
        body: receivedNotification.body,
        payload: receivedNotification.payload,
        channelKey: receivedNotification.channelKey,
      ));
    }
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('[MementoNotifications] 通知已显示: ID=${receivedNotification.id}');

    final listener = _instance._listeners?.onDisplayed;
    if (listener != null) {
      await listener(MementoReceivedNotification(
        id: receivedNotification.id,
        title: receivedNotification.title,
        body: receivedNotification.body,
        payload: receivedNotification.payload,
        channelKey: receivedNotification.channelKey,
      ));
    }
  }

  @pragma("vm:entry-point")
  static Future<void> _onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('[MementoNotifications] 通知已关闭: ID=${receivedAction.id}');

    final listener = _instance._listeners?.onDismissed;
    if (listener != null) {
      await listener(MementoReceivedAction(
        id: receivedAction.id,
        buttonKeyPressed: receivedAction.buttonKeyPressed,
        buttonKeyInput: receivedAction.buttonKeyInput,
        payload: receivedAction.payload,
        channelKey: receivedAction.channelKey,
        title: receivedAction.title,
        body: receivedAction.body,
      ));
    }
  }

  @pragma("vm:entry-point")
  static Future<void> _onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint(
      '[MementoNotifications] 通知动作: ID=${receivedAction.id}, '
      'ButtonKey=${receivedAction.buttonKeyPressed}',
    );

    final listener = _instance._listeners?.onAction;
    if (listener != null) {
      await listener(MementoReceivedAction(
        id: receivedAction.id,
        buttonKeyPressed: receivedAction.buttonKeyPressed,
        buttonKeyInput: receivedAction.buttonKeyInput,
        payload: receivedAction.payload,
        channelKey: receivedAction.channelKey,
        title: receivedAction.title,
        body: receivedAction.body,
      ));
    }
  }
}
