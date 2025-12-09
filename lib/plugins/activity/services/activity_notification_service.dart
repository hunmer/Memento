import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Memento/core/notification_controller.dart';
import 'activity_service.dart';

/// 活动通知服务 - 管理Android常驻通知栏
class ActivityNotificationService {
  final ActivityService _activityService;

  ActivityNotificationService(this._activityService);

  bool _isInitialized = false;
  bool _isEnabled = false;
  Timer? _updateTimer;
  static const MethodChannel _activityChannel = MethodChannel(
    'com.memento.foreground_service/activity_notification',
  );

  static const int _notificationId = 2001; // Android前台服务通知ID

  // 通知配置
  int _minimumReminderInterval = 30; // 最小提醒间隔（分钟）
  int _updateInterval = 1; // 通知更新频率（分钟）

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 仅在Android平台启用
      if (!Platform.isAndroid) {
        debugPrint('[ActivityNotificationService] 非Android平台，跳过初始化');
        return;
      }

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

    // 注释掉立即更新通知，避免与定时器的第一次更新重复
    // _updateNotification();
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

  /// 更新通知设置
  void updateSettings({
    int? minimumReminderInterval,
    int? updateInterval,
  }) {
    bool needsRestart = false;

    if (minimumReminderInterval != null &&
        minimumReminderInterval != _minimumReminderInterval) {
      _minimumReminderInterval = minimumReminderInterval;
      debugPrint(
        '[ActivityNotificationService] 最小提醒间隔已更新为 $_minimumReminderInterval 分钟',
      );
    }

    if (updateInterval != null && updateInterval != _updateInterval) {
      _updateInterval = updateInterval;
      needsRestart = true;
      debugPrint(
        '[ActivityNotificationService] 通知更新频率已更新为 $_updateInterval 分钟',
      );
    }

    // 如果更新频率改变，需要重启定时器
    if (needsRestart && _isEnabled) {
      _startPeriodicUpdate();
    }
  }

  /// 启动定期更新定时器
  void _startPeriodicUpdate() {
    // 根据配置的更新频率更新通知
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(
      Duration(minutes: _updateInterval),
      (timer) {
        _updateNotification();
      },
    );

    // 延迟30秒后第一次更新，避免与启用时的通知重复
    Future.delayed(const Duration(seconds: 30), () {
      if (_isEnabled) {
        _updateNotification();
      }
    });

    debugPrint(
      '[ActivityNotificationService] 定时器已启动，更新频率: $_updateInterval 分钟',
    );
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
      final minutesSinceLastTotal = timeSinceLast.inMinutes;

      // 检查是否满足最小提醒间隔
      if (minutesSinceLastTotal < _minimumReminderInterval) {
        debugPrint(
          '[ActivityNotificationService] 距离上次活动仅 $minutesSinceLastTotal 分钟，'
          '小于最小提醒间隔 $_minimumReminderInterval 分钟，不显示提醒',
        );
        // 显示默认消息
        await _activityChannel.invokeMethod('updateActivityNotification', {
          'title': '活动记录提醒',
          'content': '距离上次活动还不到 $_minimumReminderInterval 分钟，继续保持！',
        });
        return;
      }

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

      // 只使用Android前台服务通知，避免重复通知
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
      // 当没有活动记录时，更新通知显示默认消息而不是完全关闭
      await _activityChannel.invokeMethod('updateActivityNotification', {
        'title': '活动记录提醒',
        'content': '还没有活动记录，快来记录第一条活动吧！',
      });
      debugPrint('[ActivityNotificationService] 通知已更新为默认消息');
    } catch (e) {
      debugPrint('[ActivityNotificationService] 更新通知失败: $e');
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
