import 'package:flutter/material.dart';

/// 通知重要性级别
enum MementoNotificationImportance {
  /// 无声音或视觉提示
  none,

  /// 最低级别
  min,

  /// 低级别
  low,

  /// 默认级别
  defaultImportance,

  /// 高级别
  high,

  /// 最高级别
  max,
}

/// 通知通道配置
///
/// 定义通知通道的属性，如名称、描述、重要性等。
class MementoNotificationChannel {
  /// 通道唯一标识
  final String key;

  /// 通道名称
  final String name;

  /// 通道描述
  final String description;

  /// 通道组标识
  final String? groupKey;

  /// 默认颜色
  final Color defaultColor;

  /// LED 灯颜色
  final Color? ledColor;

  /// 重要性级别
  final MementoNotificationImportance importance;

  /// 是否播放声音
  final bool playSound;

  /// 是否启用振动
  final bool enableVibration;

  /// 是否启用 LED 灯
  final bool enableLights;

  const MementoNotificationChannel({
    required this.key,
    required this.name,
    this.description = '',
    this.groupKey,
    this.defaultColor = const Color(0xFF9D50DD),
    this.ledColor,
    this.importance = MementoNotificationImportance.high,
    this.playSound = true,
    this.enableVibration = true,
    this.enableLights = true,
  });
}

/// 通知通道组
class MementoNotificationChannelGroup {
  /// 组唯一标识
  final String key;

  /// 组名称
  final String name;

  const MementoNotificationChannelGroup({
    required this.key,
    required this.name,
  });
}
