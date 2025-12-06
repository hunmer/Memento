import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 通用前台计时器服务（增强版）
/// 提供后台计时通知功能,可被任何插件使用
/// 支持多通知栏实例：每个计时器可独立显示通知栏
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
      await _channel.invokeMethod('startMultipleTimerService', {
        'timerId': id,
        'taskName': title,
        'content': content,
        'progress': progress,
        'maxProgress': maxProgress,
        'color': color?.value,
      });
    } catch (e) {
      print('Error starting foreground timer service: $e');
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
      await _channel.invokeMethod('updateMultipleTimerService', {
        'timerId': id,
        'content': content,
        'progress': progress,
        'maxProgress': maxProgress,
      });
    } catch (e) {
      print('Error updating foreground timer service: $e');
    }
  }

  /// 停止前台通知服务
  ///
  /// [id] 计时器唯一标识
  static Future<void> stopService(String id) async {
    // 仅在支持的平台上调用
    if (!_isPlatformSupported) return;

    try {
      await _channel.invokeMethod('stopMultipleTimerService', {
        'timerId': id,
      });
    } catch (e) {
      print('Error stopping foreground timer service: $e');
    }
  }


  // ========== 兼容旧版本API（已废弃，建议使用新API） ==========

  /// 启动前台通知服务（兼容性方法，已废弃）
  ///
  /// [id] 计时器唯一标识
  /// [name] 计时器名称
  /// [elapsedSeconds] 已经过秒数
  /// [totalSeconds] 总秒数 (倒计时模式需要)
  /// [isCountdown] 是否为倒计时模式
  @Deprecated('Use startService with title and content instead')
  static Future<void> startTimerService({
    required String id,
    required String name,
    required int elapsedSeconds,
    int? totalSeconds,
    bool isCountdown = false,
  }) async {
    if (!_isPlatformSupported) return;

    final progress = totalSeconds != null && totalSeconds > 0
        ? (elapsedSeconds / totalSeconds * 100).toInt()
        : 0;

    await startService(
      id: id,
      title: name,
      content: _formatTime(elapsedSeconds),
      progress: progress.clamp(0, 100),
      maxProgress: 100,
    );
  }

  /// 更新前台通知（兼容性方法，已废弃）
  ///
  /// [id] 计时器唯一标识
  /// [name] 计时器名称
  /// [elapsedSeconds] 已经过秒数
  /// [totalSeconds] 总秒数 (倒计时模式需要)
  /// [isCompleted] 是否已完成
  @Deprecated('Use updateService with content and progress instead')
  static Future<void> updateTimerService({
    required String id,
    required String name,
    required int elapsedSeconds,
    int? totalSeconds,
    bool isCompleted = false,
  }) async {
    if (!_isPlatformSupported) return;

    final progress = totalSeconds != null && totalSeconds > 0
        ? (elapsedSeconds / totalSeconds * 100).toInt()
        : 0;

    await updateService(
      id: id,
      content: _formatTime(elapsedSeconds),
      progress: progress.clamp(0, 100),
      maxProgress: 100,
    );
  }

  /// 停止前台通知服务（兼容性方法，已废弃）
  ///
  /// [id] 计时器唯一标识
  @Deprecated('Use stopService instead')
  static Future<void> stopTimerService({String? id}) async {
    if (id != null) {
      await stopService(id);
    }
  }

  /// 格式化时间显示
  static String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}
