import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'foreground_service_config.dart';

/// 计时器前台服务
///
/// 提供计时器任务的前台服务管理，包括启动、更新和停止计时器。
/// 支持子任务进度显示。
class MementoTimerService {
  static final MementoTimerService _instance = MementoTimerService._internal();

  /// 单例实例
  static MementoTimerService get instance => _instance;

  MementoTimerService._internal();

  /// MethodChannel 名称
  static const String _channelName = 'com.memento.foreground_service/timer';

  /// MethodChannel 实例
  static const MethodChannel _channel = MethodChannel(_channelName);

  /// 启动计时器服务
  ///
  /// [taskId] 任务唯一标识
  /// [taskName] 任务名称（显示在通知标题）
  /// [subTimers] 子计时器列表
  /// [currentSubTimerIndex] 当前活跃的子计时器索引
  Future<void> startTimerService({
    required String taskId,
    required String taskName,
    List<TimerSubTask>? subTimers,
    int currentSubTimerIndex = 0,
  }) async {
    if (!Platform.isAndroid) {
      debugPrint('[MementoTimerService] 仅支持 Android 平台');
      return;
    }

    try {
      await _channel.invokeMethod('startTimerService', {
        'taskId': taskId,
        'taskName': taskName,
        'subTimers': subTimers?.map((t) => t.toMap()).toList(),
        'currentSubTimerIndex': currentSubTimerIndex,
      });
      debugPrint('[MementoTimerService] 计时器服务已启动: $taskName');
    } catch (e) {
      debugPrint('[MementoTimerService] 启动计时器服务失败: $e');
      rethrow;
    }
  }

  /// 更新计时器服务
  ///
  /// [taskId] 任务唯一标识
  /// [taskName] 任务名称
  /// [subTimers] 更新后的子计时器列表
  /// [currentSubTimerIndex] 当前活跃的子计时器索引
  Future<void> updateTimerService({
    required String taskId,
    required String taskName,
    List<TimerSubTask>? subTimers,
    int currentSubTimerIndex = 0,
  }) async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('updateTimerService', {
        'taskId': taskId,
        'taskName': taskName,
        'subTimers': subTimers?.map((t) => t.toMap()).toList(),
        'currentSubTimerIndex': currentSubTimerIndex,
      });
    } catch (e) {
      debugPrint('[MementoTimerService] 更新计时器服务失败: $e');
      rethrow;
    }
  }

  /// 停止计时器服务
  ///
  /// [taskId] 任务唯一标识
  Future<void> stopTimerService({String? taskId}) async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('stopTimerService', {
        'taskId': taskId,
      });
      debugPrint('[MementoTimerService] 计时器服务已停止');
    } catch (e) {
      debugPrint('[MementoTimerService] 停止计时器服务失败: $e');
      rethrow;
    }
  }
}
