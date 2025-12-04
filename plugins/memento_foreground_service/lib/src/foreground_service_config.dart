import 'package:flutter/material.dart';

/// 前台服务配置
class ForegroundServiceConfig {
  /// 通知通道 ID
  final String channelId;

  /// 通知通道名称
  final String channelName;

  /// 通知通道描述
  final String channelDescription;

  /// 事件间隔（毫秒）
  final int eventIntervalMs;

  /// 是否在启动时自动运行
  final bool autoRunOnBoot;

  /// 是否在应用更新后自动运行
  final bool autoRunOnMyPackageReplaced;

  /// 是否允许 WakeLock
  final bool allowWakeLock;

  /// 是否允许 WiFi Lock
  final bool allowWifiLock;

  /// iOS 是否显示通知
  final bool iosShowNotification;

  /// iOS 是否播放声音
  final bool iosPlaySound;

  const ForegroundServiceConfig({
    this.channelId = 'foreground_service',
    this.channelName = 'Foreground Service Notification',
    this.channelDescription = 'This notification appears when the foreground service is running.',
    this.eventIntervalMs = 5000,
    this.autoRunOnBoot = true,
    this.autoRunOnMyPackageReplaced = true,
    this.allowWakeLock = true,
    this.allowWifiLock = true,
    this.iosShowNotification = false,
    this.iosPlaySound = false,
  });
}

/// 通知按钮配置
class ServiceNotificationButton {
  /// 按钮唯一标识
  final String key;

  /// 按钮标签
  final String label;

  /// 按钮颜色
  final Color? color;

  const ServiceNotificationButton({
    required this.key,
    required this.label,
    this.color,
  });
}

/// 计时器子任务
class TimerSubTask {
  /// 子任务名称
  final String name;

  /// 持续时间（秒）
  final int duration;

  /// 当前进度（秒）
  final int current;

  /// 是否已完成
  final bool completed;

  const TimerSubTask({
    required this.name,
    required this.duration,
    this.current = 0,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'duration': duration,
      'current': current,
      'completed': completed,
    };
  }
}
