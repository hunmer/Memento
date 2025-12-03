/// Memento 前台服务管理插件
///
/// 封装 flutter_foreground_task，提供简洁统一的前台服务 API。
/// 支持计时器服务、活动提醒服务等前台常驻服务。
library;

export 'src/foreground_service.dart';
export 'src/foreground_service_config.dart';
export 'src/service_result.dart';
export 'src/timer_service.dart';
export 'src/activity_notification_service.dart';

// 重新导出 flutter_foreground_task 的高级类型，供高级用例使用
// 这允许用户在需要时访问底层 API（如自定义 TaskHandler、发送数据等）
export 'package:flutter_foreground_task/flutter_foreground_task.dart'
    show
        FlutterForegroundTask,
        TaskHandler,
        TaskStarter,
        NotificationButton,
        AndroidNotificationOptions,
        IOSNotificationOptions,
        ForegroundTaskOptions;
