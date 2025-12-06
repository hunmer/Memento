/// 统一计时器事件系统
///
/// 定义计时器相关的所有事件类型和参数类

import 'dart:convert';
import 'package:Memento/core/event/event_manager.dart';
import 'package:flutter/material.dart';
import '../../../../core/event/event_args.dart';

/// 计时器事件类型
enum TimerEventType {
  /// 计时器启动
  started,

  /// 计时器暂停
  paused,

  /// 计时器恢复
  resumed,

  /// 计时器停止
  stopped,

  /// 计时器更新（每秒触发）
  updated,

  /// 计时器完成
  completed,

  /// 阶段完成（多阶段计时器）
  stageCompleted,
}

/// 统一计时器事件参数
class UnifiedTimerEventArgs extends EventArgs {
  /// 事件类型
  final TimerEventType eventType;

  /// 计时器状态
  final dynamic timerState;

  /// 时间戳
  final DateTime timestamp;

  /// 额外数据（可选）
  final Map<String, dynamic>? data;

  /// 构造函数
  UnifiedTimerEventArgs(
    this.timerState,
    this.eventType, {
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now(),
      super('');

  /// 从 JSON 构造
  factory UnifiedTimerEventArgs.fromJson(Map<String, dynamic> json) {
    return UnifiedTimerEventArgs(
      json['timerState'],
      TimerEventType.values[json['eventType'] as int],
      data: json['data'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType.index,
      'timerState': timerState,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }

  @override
  String toString() {
    return 'UnifiedTimerEventArgs(eventType: $eventType, timerState: $timerState, timestamp: $timestamp)';
  }
}

/// 统一事件名称常量
class TimerEventNames {
  // 统一事件（由UnifiedTimerController广播）
  static const String timerStarted = 'unified_timer_started';
  static const String timerPaused = 'unified_timer_paused';
  static const String timerResumed = 'unified_timer_resumed';
  static const String timerStopped = 'unified_timer_stopped';
  static const String timerUpdated = 'unified_timer_updated';
  static const String timerCompleted = 'unified_timer_completed';
  static const String timerStageCompleted = 'unified_timer_stage_completed';

  // 插件专用事件（由适配器转发）
  static const String habitTimerStarted = 'habit_timer_started';
  static const String habitTimerStopped = 'habit_timer_stopped';
  static const String timerTaskChanged = 'timer_task_changed';
  static const String timerItemChanged = 'timer_item_changed';
  static const String timerItemProgress = 'timer_item_progress';
}

/// 事件助手类
class TimerEventHelper {
  /// 获取事件对应的统一事件名称
  static String getEventName(TimerEventType type) {
    switch (type) {
      case TimerEventType.started:
        return TimerEventNames.timerStarted;
      case TimerEventType.paused:
        return TimerEventNames.timerPaused;
      case TimerEventType.resumed:
        return TimerEventNames.timerResumed;
      case TimerEventType.stopped:
        return TimerEventNames.timerStopped;
      case TimerEventType.updated:
        return TimerEventNames.timerUpdated;
      case TimerEventType.completed:
        return TimerEventNames.timerCompleted;
      case TimerEventType.stageCompleted:
        return TimerEventNames.timerStageCompleted;
    }
  }

  /// 获取统一事件名称对应的事件类型
  static TimerEventType? getEventType(String eventName) {
    switch (eventName) {
      case TimerEventNames.timerStarted:
        return TimerEventType.started;
      case TimerEventNames.timerPaused:
        return TimerEventType.paused;
      case TimerEventNames.timerResumed:
        return TimerEventType.resumed;
      case TimerEventNames.timerStopped:
        return TimerEventType.stopped;
      case TimerEventNames.timerUpdated:
        return TimerEventType.updated;
      case TimerEventNames.timerCompleted:
        return TimerEventType.completed;
      case TimerEventNames.timerStageCompleted:
        return TimerEventType.stageCompleted;
    }
    return null;
  }

  /// 检查是否为统一计时器事件
  static bool isUnifiedTimerEvent(String eventName) {
    return eventName.startsWith('unified_timer_');
  }

  /// 检查是否为插件专用事件
  static bool isPluginEvent(String eventName) {
    return !isUnifiedTimerEvent(eventName);
  }

  /// 格式化事件显示文本
  static String formatEventDisplay(TimerEventType type) {
    switch (type) {
      case TimerEventType.started:
        return '计时器启动';
      case TimerEventType.paused:
        return '计时器暂停';
      case TimerEventType.resumed:
        return '计时器恢复';
      case TimerEventType.stopped:
        return '计时器停止';
      case TimerEventType.updated:
        return '计时器更新';
      case TimerEventType.completed:
        return '计时器完成';
      case TimerEventType.stageCompleted:
        return '阶段完成';
    }
  }
}

/// 计时器统计事件参数（用于统计和分析）
class TimerStatsEventArgs {
  /// 计时器ID
  final String timerId;

  /// 计时器名称
  final String timerName;

  /// 插件ID
  final String pluginId;

  /// 总运行时长
  final Duration totalDuration;

  /// 启动次数
  final int startCount;

  /// 完成次数
  final int completeCount;

  /// 平均单次运行时长
  final Duration averageDuration;

  /// 时间戳
  final DateTime timestamp;

  /// 构造函数
  TimerStatsEventArgs({
    required this.timerId,
    required this.timerName,
    required this.pluginId,
    required this.totalDuration,
    required this.startCount,
    required this.completeCount,
    required this.averageDuration,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 从 JSON 构造
  factory TimerStatsEventArgs.fromJson(Map<String, dynamic> json) {
    return TimerStatsEventArgs(
      timerId: json['timerId'] as String,
      timerName: json['timerName'] as String,
      pluginId: json['pluginId'] as String,
      totalDuration: Duration(milliseconds: json['totalDuration'] as int),
      startCount: json['startCount'] as int,
      completeCount: json['completeCount'] as int,
      averageDuration: Duration(milliseconds: json['averageDuration'] as int),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'timerId': timerId,
      'timerName': timerName,
      'pluginId': pluginId,
      'totalDuration': totalDuration.inMilliseconds,
      'startCount': startCount,
      'completeCount': completeCount,
      'averageDuration': averageDuration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TimerStatsEventArgs(timerId: $timerId, totalDuration: $totalDuration, startCount: $startCount)';
  }
}

/// 计时器错误事件参数
class TimerErrorEventArgs {
  /// 计时器ID
  final String timerId;

  /// 错误消息
  final String error;

  /// 错误堆栈（可选）
  final String? stackTrace;

  /// 时间戳
  final DateTime timestamp;

  /// 构造函数
  TimerErrorEventArgs({
    required this.timerId,
    required this.error,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 从 JSON 构造
  factory TimerErrorEventArgs.fromJson(Map<String, dynamic> json) {
    return TimerErrorEventArgs(
      timerId: json['timerId'] as String,
      error: json['error'] as String,
      stackTrace: json['stackTrace'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'timerId': timerId,
      'error': error,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TimerErrorEventArgs(timerId: $timerId, error: $error)';
  }
}
