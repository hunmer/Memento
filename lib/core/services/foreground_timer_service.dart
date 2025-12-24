import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../screens/settings_screen/controllers/live_activities_controller.dart';

/// 通用前台计时器服务（增强版）
/// 提供后台计时通知功能,可被任何插件使用
/// 支持多通知栏实例：每个计时器可独立显示通知栏
///
/// 平台实现：
/// - Android: 使用 MethodChannel 调用原生前台服务
/// - iOS: 使用 Live Activities (动态岛/灵动岛)
/// - 桌面端/Web: 静默忽略
class ForegroundTimerService {
  static const MethodChannel _channel = MethodChannel(
    'github.hunmer.memento/timer_service',
  );

  // iOS Live Activities 活动ID映射
  static final Map<String, String> _iosActivityIds = {};

  /// 检查当前平台是否支持前台服务
  static bool get _isPlatformSupported {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// 判断是否为 iOS 平台
  static bool get _isIOS {
    return !kIsWeb && Platform.isIOS;
  }

  /// 判断是否为 Android 平台
  static bool get _isAndroid {
    return !kIsWeb && Platform.isAndroid;
  }

  /// 启动前台通知服务
  ///
  /// [id] 计时器唯一标识
  /// [title] 通知标题
  /// [content] 通知内容
  /// [progress] 当前进度（0-100）
  /// [maxProgress] 最大进度（100）
  /// [color] 主题色（可选）
  static Future<void> startService({
    required String id,
    required String title,
    required String content,
    required int progress,
    required int maxProgress,
    Color? color,
  }) async {
    // 仅在支持的平台上调用
    if (!_isPlatformSupported) return;

    try {
      if (_isIOS) {
        // iOS: 使用 Live Activities
        await _startIOSActivity(
          id: id,
          title: title,
          content: content,
          progress: progress,
          maxProgress: maxProgress,
        );
      } else if (_isAndroid) {
        // Android: 使用原生前台服务
        await _channel.invokeMethod('startMultipleTimerService', {
          'timerId': id,
          'taskName': title,
          'content': content,
          'progress': progress,
          'maxProgress': maxProgress,
          'color': color?.value,
        });
      }
    } catch (e) {
      debugPrint('Error starting foreground timer service: $e');
    }
  }

  /// iOS: 启动/更新 Live Activity
  static Future<void> _startIOSActivity({
    required String id,
    required String title,
    required String content,
    required int progress,
    required int maxProgress,
  }) async {
    final controller = LiveActivitiesController.instance;

    // 确保控制器已初始化
    if (!controller.isInitialized) {
      await controller.init(
        appGroupId: 'group.github.hunmer.memento',
        urlScheme: 'memento',
        requireNotificationPermission: true,
      );
    }

    if (!controller.isSupported) {
      debugPrint('iOS Live Activities 不支持');
      return;
    }

    // 计算进度百分比 (0.0-1.0)
    final progressValue = maxProgress > 0 ? progress / maxProgress : 0.0;

    // 检查是否已存在活动
    final existingActivityId = _iosActivityIds[id];

    if (existingActivityId != null) {
      // 已存在，更新活动
      final activityData = {
        'subtitle': content,
        'progress': progressValue.clamp(0.0, 1.0),
        'status': content,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await controller.updateActivity(existingActivityId, activityData);
    } else {
      // 不存在，创建新活动
      final activityData = {
        'title': title,
        'subtitle': content,
        'progress': progressValue.clamp(0.0, 1.0),
        'status': content,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final activityId = await controller.createActivity(
        'timer_$id',
        activityData,
      );

      if (activityId != null) {
        _iosActivityIds[id] = activityId;
        debugPrint('iOS Live Activity 创建成功: $activityId');
      }
    }
  }

  /// 更新前台通知
  ///
  /// [id] 计时器唯一标识
  /// [content] 通知内容
  /// [progress] 当前进度（0-100）
  /// [maxProgress] 最大进度（100）
  static Future<void> updateService({
    required String id,
    required String content,
    required int progress,
    required int maxProgress,
  }) async {
    // 仅在支持的平台上调用
    if (!_isPlatformSupported) return;

    try {
      if (_isIOS) {
        // iOS: 更新 Live Activity
        await _updateIOSActivity(
          id: id,
          content: content,
          progress: progress,
          maxProgress: maxProgress,
        );
      } else if (_isAndroid) {
        // Android: 更新原生前台服务
        await _channel.invokeMethod('updateMultipleTimerService', {
          'timerId': id,
          'content': content,
          'progress': progress,
          'maxProgress': maxProgress,
        });
      }
    } catch (e) {
      debugPrint('Error updating foreground timer service: $e');
    }
  }

  /// iOS: 更新 Live Activity
  static Future<void> _updateIOSActivity({
    required String id,
    required String content,
    required int progress,
    required int maxProgress,
  }) async {
    final activityId = _iosActivityIds[id];
    if (activityId == null) {
      debugPrint('iOS Live Activity 未找到: $id');
      return;
    }

    final controller = LiveActivitiesController.instance;
    if (!controller.isInitialized) {
      debugPrint('LiveActivitiesController 未初始化');
      return;
    }

    // 计算进度百分比 (0.0-1.0)
    final progressValue = maxProgress > 0 ? progress / maxProgress : 0.0;

    // 更新活动数据
    final activityData = {
      'subtitle': content,
      'progress': progressValue.clamp(0.0, 1.0),
      'status': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await controller.updateActivity(activityId, activityData);
  }

  /// 停止前台通知服务
  ///
  /// [id] 计时器唯一标识
  /// [showCompleted] 是否显示完成状态（100%）
  static Future<void> stopService(
    String id, {
    bool showCompleted = false,
  }) async {
    // 仅在支持的平台上调用
    if (!_isPlatformSupported) return;

    try {
      if (_isIOS) {
        // iOS: 结束 Live Activity（可选显示完成状态）
        await _stopIOSActivity(id, showCompleted: showCompleted);
      } else if (_isAndroid) {
        // Android: 停止原生前台服务
        await _channel.invokeMethod('stopMultipleTimerService', {'timerId': id});
      }
    } catch (e) {
      debugPrint('Error stopping foreground timer service: $e');
    }
  }

  /// iOS: 结束 Live Activity
  static Future<void> _stopIOSActivity(
    String id, {
    bool showCompleted = false,
  }) async {
    final activityId = _iosActivityIds[id];
    if (activityId == null) {
      debugPrint('iOS Live Activity 未找到: $id');
      return;
    }

    final controller = LiveActivitiesController.instance;
    if (!controller.isInitialized) {
      debugPrint('LiveActivitiesController 未初始化');
      return;
    }

    // 如果需要显示完成状态，先更新到100%
    if (showCompleted) {
      final completedData = {
        'subtitle': '已完成',
        'progress': 1.0,
        'status': '已完成',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await controller.updateActivity(activityId, completedData);

      // 延迟2秒让用户看到完成状态
      await Future.delayed(const Duration(seconds: 2));
    }

    await controller.endActivity(activityId);
    _iosActivityIds.remove(id);
    debugPrint('iOS Live Activity 已结束: $activityId');
  }
}
