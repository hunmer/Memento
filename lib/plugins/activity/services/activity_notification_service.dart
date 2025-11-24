import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../../core/notification_controller.dart';
import 'activity_service.dart';

/// 活动通知服务 - 管理Android常驻通知栏
class ActivityNotificationService {
  final ActivityService _activityService;

  ActivityNotificationService(this._activityService);

  bool _isInitialized = false;
  bool _isEnabled = false;
  Timer? _updateTimer;
  static const MethodChannel _activityChannel = MethodChannel('github.hunmer.memento/activity_notification');

  static const String _notificationChannelKey = 'activity_reminder';
  static const String _notificationChannelGroupKey = 'activity_reminder_group';
  static const int _notificationId = 1001; // 固定ID，用于更新同一通知

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 仅在Android平台启用
      if (!Platform.isAndroid) {
        debugPrint('[ActivityNotificationService] 非Android平台，跳过初始化');
        return;
      }

      // 注册通知渠道
      await _registerNotificationChannel();

      // 启动定期更新
      _startPeriodicUpdate();

      _isInitialized = true;
      debugPrint('[ActivityNotificationService] 初始化完成');
    } catch (e) {
      debugPrint('[ActivityNotificationService] 初始化失败: $e');
    }
  }

  /// 启用通知服务
  Future<void> enable() async {
    if (!Platform.isAndroid) return;

    // 请求通知权限
    final hasPermission = await NotificationController.requestPermission();
    if (!hasPermission) {
      debugPrint('[ActivityNotificationService] 用户拒绝了通知权限');
      return;
    }

    _isEnabled = true;

    try {
      // 启动Android前台服务
      await _activityChannel.invokeMethod('startActivityNotificationService');
      debugPrint('[ActivityNotificationService] Android前台服务已启动');
    } catch (e) {
      debugPrint('[ActivityNotificationService] 启动Android前台服务失败: $e');
    }

    // 立即更新一次通知
    _updateNotification();
    debugPrint('[ActivityNotificationService] 通知服务已启用');
  }

  /// 禁用通知服务
  Future<void> disable() async {
    _isEnabled = false;

    try {
      // 停止Android前台服务
      await _activityChannel.invokeMethod('stopActivityNotificationService');
      debugPrint('[ActivityNotificationService] Android前台服务已停止');
    } catch (e) {
      debugPrint('[ActivityNotificationService] 停止Android前台服务失败: $e');
    }

    await _dismissNotification();
    debugPrint('[ActivityNotificationService] 通知服务已禁用');
  }

  /// 获取是否已启用
  bool get isEnabled => _isEnabled;

  /// 注册活动提醒专用通知渠道
  Future<void> _registerNotificationChannel() async {
    await AwesomeNotifications().initialize(
      null, // 使用默认图标
      [
        NotificationChannel(
          channelGroupKey: _notificationChannelGroupKey,
          channelKey: _notificationChannelKey,
          channelName: '活动提醒',
          channelDescription: '显示距离上次活动的时间和内容',
          importance: NotificationImportance.Max,
          playSound: false,
          enableVibration: false,
          enableLights: false,
          criticalAlerts: false,
          onlyAlertOnce: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: _notificationChannelGroupKey,
          channelGroupName: '活动提醒',
        ),
      ],
    );
  }

  /// 启动定期更新定时器
  void _startPeriodicUpdate() {
    // 每分钟更新一次通知
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateNotification();
    });

    // 立即更新一次
    _updateNotification();
  }

  /// 更新通知内容
  Future<void> _updateNotification() async {
    if (!_isEnabled || !Platform.isAndroid) return;

    try {
      debugPrint('[ActivityNotificationService] 开始更新活动通知...');

      final lastActivityTime = await _getLastActivityTime();
      final lastActivityContent = await _getLastActivityContent();

      if (lastActivityTime == null) {
        // 没有活动记录，隐藏通知
        await _dismissNotification();
        debugPrint('[ActivityNotificationService] 没有活动记录，隐藏通知');
        return;
      }

      final timeSinceLast = DateTime.now().difference(lastActivityTime);
      final hoursSinceLast = timeSinceLast.inHours;
      final minutesSinceLast = timeSinceLast.inMinutes % 60;

      String timeText;
      if (hoursSinceLast == 0) {
        timeText = '$minutesSinceLast 分钟前';
      } else {
        timeText = '$hoursSinceLast 小时 $minutesSinceLast 分钟前';
      }

      final title = '活动记录提醒';
      final body = '距离上次活动「$lastActivityContent」已过去 $timeText';

      debugPrint('[ActivityNotificationService] 更新通知: $body');

      // 创建Flutter通知
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _notificationId,
          channelKey: _notificationChannelKey,
          title: title,
          body: body,
          notificationLayout: NotificationLayout.Default,
          largeIcon: 'asset://assets/icon/icon.png',
          showWhen: false,
          payload: {
            'action': 'open_activity_form',
            'timestamp': DateTime.now().toIso8601String(),
            'type': 'activity_reminder',
          },
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'open_form',
            label: '记录活动',
            actionType: ActionType.Default,
            color: Colors.pink,
          ),
          NotificationActionButton(
            key: 'dismiss',
            label: '忽略',
            actionType: ActionType.Default,
            color: Colors.grey,
          ),
        ],
      );

      // 同时更新Android前台服务通知
      try {
        await _activityChannel.invokeMethod('updateActivityNotification', {
          'title': title,
          'content': body,
        });
      } catch (e) {
        debugPrint('[ActivityNotificationService] 更新Android前台服务失败: $e');
      }
    } catch (e) {
      debugPrint('[ActivityNotificationService] 更新通知失败: $e');
    }
  }

  /// 获取最近活动时间
  Future<DateTime?> _getLastActivityTime() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 先检查今天的活动
      var activities = await _activityService.getActivitiesForDate(today);
      if (activities.isNotEmpty) {
        activities.sort((a, b) => b.endTime.compareTo(a.endTime));
        return activities.first.endTime;
      }

      // 如果今天没有活动，检查昨天
      final yesterday = today.subtract(const Duration(days: 1));
      activities = await _activityService.getActivitiesForDate(yesterday);
      if (activities.isNotEmpty) {
        activities.sort((a, b) => b.endTime.compareTo(a.endTime));
        return activities.first.endTime;
      }

      // 如果都没有，返回null
      return null;
    } catch (e) {
      debugPrint('[ActivityNotificationService] 获取最近活动时间失败: $e');
      return null;
    }
  }

  /// 获取最近活动内容
  Future<String?> _getLastActivityContent() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 先检查今天的活动
      var activities = await _activityService.getActivitiesForDate(today);
      if (activities.isNotEmpty) {
        activities.sort((a, b) => b.endTime.compareTo(a.endTime));
        final lastActivity = activities.first;
        return '${lastActivity.title} (${lastActivity.formattedDuration})';
      }

      // 如果今天没有活动，检查昨天
      final yesterday = today.subtract(const Duration(days: 1));
      activities = await _activityService.getActivitiesForDate(yesterday);
      if (activities.isNotEmpty) {
        activities.sort((a, b) => b.endTime.compareTo(a.endTime));
        final lastActivity = activities.first;
        return '${lastActivity.title} (${lastActivity.formattedDuration})';
      }

      return null;
    } catch (e) {
      debugPrint('[ActivityNotificationService] 获取最近活动内容失败: $e');
      return null;
    }
  }

  /// 关闭通知
  Future<void> _dismissNotification() async {
    try {
      await AwesomeNotifications().cancel(_notificationId);
      debugPrint('[ActivityNotificationService] 通知已关闭');
    } catch (e) {
      debugPrint('[ActivityNotificationService] 关闭通知失败: $e');
    }
  }

  /// 处理通知点击事件
  static void handleNotificationAction(ReceivedAction receivedAction) {
    debugPrint(
      '[ActivityNotificationService] 通知动作接收: ID=${receivedAction.id}, ButtonKey=${receivedAction.buttonKeyPressed}',
    );

    if (receivedAction.buttonKeyPressed == 'open_form') {
      // 点击"记录活动"按钮
      _broadcastOpenActivityForm();
    } else if (receivedAction.buttonKeyPressed == 'dismiss') {
      // 点击"忽略"按钮
      debugPrint('[ActivityNotificationService] 用户点击了忽略按钮');
    } else if (receivedAction.buttonKeyPressed == null) {
      // 点击通知本体
      _broadcastOpenActivityForm();
    }
  }

  /// 广播打开活动表单事件
  static void _broadcastOpenActivityForm() {
    try {
      // 发送全局事件通知UI层打开活动表单
      // 注意：这里需要使用全局事件管理器，但由于循环依赖问题，
      // 我们在ActivityPlugin中处理这个事件
      debugPrint('[ActivityNotificationService] 广播打开活动表单事件');
    } catch (e) {
      debugPrint('[ActivityNotificationService] 广播事件失败: $e');
    }
  }

  /// 智能检测建议的活动时间
  Future<DateTime?> detectOptimalActivityTime() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activities = await _activityService.getActivitiesForDate(today);

      if (activities.isEmpty) {
        // 如果今天没有活动，建议记录当前时间
        return now;
      }

      // 按开始时间排序
      activities.sort((a, b) => a.startTime.compareTo(b.startTime));

      // 检查活动之间的间隙
      for (int i = 0; i < activities.length - 1; i++) {
        final currentEnd = activities[i].endTime;
        final nextStart = activities[i + 1].startTime;

        if (nextStart.difference(currentEnd) > const Duration(hours: 2)) {
          // 发现超过2小时的间隙，建议记录
          return currentEnd.add(const Duration(minutes: 30));
        }
      }

      // 检查最后一个活动结束后的时间
      final lastActivity = activities.last;
      if (now.difference(lastActivity.endTime) > const Duration(hours: 1)) {
        return lastActivity.endTime.add(const Duration(minutes: 30));
      }

      // 如果没有合适的间隙，建议记录当前时间
      return now;
    } catch (e) {
      debugPrint('[ActivityNotificationService] 智能检测时间失败: $e');
      return null;
    }
  }

  /// 清理资源
  void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _dismissNotification();
    _isInitialized = false;
    _isEnabled = false;
    debugPrint('[ActivityNotificationService] 资源已清理');
  }

  /// 获取通知统计信息（用于调试）
  Map<String, dynamic> getStats() {
    return {
      'isInitialized': _isInitialized,
      'isEnabled': _isEnabled,
      'platform': Platform.operatingSystem,
      'notificationId': _notificationId,
      'updateInterval': '1分钟',
      'isTimerActive': _updateTimer?.isActive ?? false,
    };
  }
}