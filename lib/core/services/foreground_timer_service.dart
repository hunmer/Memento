import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 通用前台计时器服务
/// 提供后台计时通知功能,可被任何插件使用
/// 注意: 仅在 Android/iOS 平台有效,桌面端和 Web 端会静默忽略
class ForegroundTimerService {
  static const MethodChannel _channel = MethodChannel(
    'github.hunmer.memento/timer_service',
  );

  /// 检查当前平台是否支持前台服务
  static bool get _isPlatformSupported {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// 启动前台通知服务
  ///
  /// [id] 计时器唯一标识
  /// [name] 计时器名称
  /// [elapsedSeconds] 已经过秒数
  /// [totalSeconds] 总秒数 (倒计时模式需要)
  /// [isCountdown] 是否为倒计时模式
  static Future<void> startService({
    required String id,
    required String name,
    required int elapsedSeconds,
    int? totalSeconds,
    bool isCountdown = false,
  }) async {
    // 仅在支持的平台上调用
    if (!_isPlatformSupported) return;

    try {
      await _channel.invokeMethod('startTimerService', {
        'taskId': id,
        'taskName': name,
        'subTimers': [
          {
            'name': name,
            'current': elapsedSeconds,
            'duration': totalSeconds ?? 0,
            'completed': false,
          },
        ],
        'currentSubTimerIndex': 0,
      });
    } catch (e) {
      print('Error starting foreground timer service: $e');
    }
  }

  /// 更新前台通知
  ///
  /// [id] 计时器唯一标识
  /// [name] 计时器名称
  /// [elapsedSeconds] 已经过秒数
  /// [totalSeconds] 总秒数 (倒计时模式需要)
  /// [isCompleted] 是否已完成
  static Future<void> updateService({
    required String id,
    required String name,
    required int elapsedSeconds,
    int? totalSeconds,
    bool isCompleted = false,
  }) async {
    // 仅在支持的平台上调用
    if (!_isPlatformSupported) return;

    try {
      await _channel.invokeMethod('updateTimerService', {
        'taskId': id,
        'taskName': name,
        'subTimers': [
          {
            'name': name,
            'current': elapsedSeconds,
            'duration': totalSeconds ?? 0,
            'completed': isCompleted,
          },
        ],
        'currentSubTimerIndex': 0,
      });
    } catch (e) {
      print('Error updating foreground timer service: $e');
    }
  }

  /// 停止前台通知服务
  ///
  /// [id] 计时器唯一标识
  static Future<void> stopService({String? id}) async {
    // 仅在支持的平台上调用
    if (!_isPlatformSupported) return;

    try {
      await _channel.invokeMethod('stopTimerService', {'taskId': id ?? ''});
    } catch (e) {
      print('Error stopping foreground timer service: $e');
    }
  }
}
