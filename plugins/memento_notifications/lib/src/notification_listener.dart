import 'notification_content.dart';
import 'notification_action.dart';

/// 通知创建回调
typedef OnNotificationCreated = Future<void> Function(
  MementoReceivedNotification notification,
);

/// 通知显示回调
typedef OnNotificationDisplayed = Future<void> Function(
  MementoReceivedNotification notification,
);

/// 通知关闭回调
typedef OnNotificationDismissed = Future<void> Function(
  MementoReceivedAction action,
);

/// 通知动作回调
typedef OnNotificationAction = Future<void> Function(
  MementoReceivedAction action,
);

/// 通知事件监听器配置
class MementoNotificationListeners {
  /// 通知创建回调
  final OnNotificationCreated? onCreated;

  /// 通知显示回调
  final OnNotificationDisplayed? onDisplayed;

  /// 通知关闭回调
  final OnNotificationDismissed? onDismissed;

  /// 通知动作回调
  final OnNotificationAction? onAction;

  const MementoNotificationListeners({
    this.onCreated,
    this.onDisplayed,
    this.onDismissed,
    this.onAction,
  });
}
