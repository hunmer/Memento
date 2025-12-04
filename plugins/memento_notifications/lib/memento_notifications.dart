/// Memento 通知管理插件
///
/// 封装 awesome_notifications，提供简洁统一的通知 API。
/// 支持基础通知、大图通知、按钮通知等多种类型。
library;

export 'src/notification_service.dart';
export 'src/notification_channel.dart';
export 'src/notification_content.dart';
export 'src/notification_action.dart';
export 'src/notification_listener.dart';

// 重新导出 awesome_notifications 的高级类型，供高级用例使用
// 这允许用户在需要时访问底层 API（如定时通知、日历通知等）
export 'package:awesome_notifications/awesome_notifications.dart'
    show
        AwesomeNotifications,
        NotificationContent,
        NotificationChannel,
        NotificationChannelGroup,
        NotificationSchedule,
        NotificationCalendar,
        NotificationInterval,
        NotificationImportance,
        NotificationLayout,
        NotificationActionButton,
        ActionType;
