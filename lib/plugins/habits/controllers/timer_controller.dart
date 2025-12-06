import 'dart:async';
import 'package:Memento/core/services/timer/events/timer_events.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/event/event_manager.dart';
import 'package:Memento/core/services/timer/unified_timer_controller.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';
import 'package:Memento/plugins/habits/models/habit.dart';

class HabitTimerEventArgs extends EventArgs {
  final String habitId;
  final int elapsedSeconds;
  final bool isCountdown;
  final bool isRunning;

  HabitTimerEventArgs({
    required this.habitId,
    required this.elapsedSeconds,
    required this.isCountdown,
    required this.isRunning,
  });
}

typedef TimerUpdateCallback = void Function(int elapsedSeconds);

/// TimerController - 习惯计时器控制器
///
/// 现在使用委托模式，委托给统一计时器控制器进行实际的计时管理
class TimerController {
  static TimerController? _instance;

  factory TimerController() {
    return _instance ??= TimerController._internal();
  }

  TimerController._internal();

  /// 启动计时器（委托给统一控制器）
  void startTimer(
    Habit habit,
    TimerUpdateCallback onUpdate, {
    Duration? initialDuration,
  }) {
    // 停止旧计时器
    stopTimer(habit.id);

    // 使用统一计时器控制器启动
    unifiedTimerController.startTimer(
      id: habit.id,
      name: habit.title,
      type: TimerType.countUp,
      color: Colors.green,
      icon: Icons.check_circle,
      targetDuration:
          initialDuration ?? Duration(minutes: habit.durationMinutes),
      pluginId: 'habits',
    );

    // 设置回调（通过事件监听）
    _setupTimerCallback(habit.id, onUpdate);
  }

  /// 停止计时器（委托给统一控制器）
  void stopTimer(String habitId) {
    // 停止统一控制器中的计时器
    unifiedTimerController.stopTimer(habitId);
  }

  /// 暂停计时器（委托给统一控制器）
  void pauseTimer(String habitId) {
    unifiedTimerController.pauseTimer(habitId);
  }

  /// 恢复计时器（委托给统一控制器）
  void resumeTimer(String habitId) {
    unifiedTimerController.resumeTimer(habitId);
  }

  /// 切换计时器状态
  void toggleTimer(String habitId, bool isRunning) {
    final state = unifiedTimerController.getTimer(habitId);
    if (state != null) {
      if (isRunning) {
        resumeTimer(habitId);
      } else {
        pauseTimer(habitId);
      }
    }
  }

  /// 设置倒计时模式（通过更新计时器主题色或配置）
  void setCountdownMode(String habitId, bool isCountdown) {
    // 统一控制器暂时不支持动态切换模式
    // 这里可以记录模式状态，在启动时应用
  }

  /// 获取计时器数据
  Map<String, dynamic>? getTimerData(String habitId) {
    final state = unifiedTimerController.getTimer(habitId);
    if (state == null) return null;

    // 从统一状态转换回本地格式
    return {
      'isRunning': state.status == TimerStatus.running,
      'notes': '', // 统一控制器暂无备注功能
      'isCountdown': state.isCountdown,
      'elapsedSeconds': state.elapsed.inSeconds,
    };
  }

  /// 清除计时器数据
  void clearTimerData(String habitId) {
    unifiedTimerController.stopTimer(habitId);
  }

  /// 更新计时器数据
  void updateTimerData(String habitId, Map<String, dynamic> data) {
    // 统一控制器暂无动态更新功能
  }

  /// 获取所有活动计时器
  Map<String, bool> getActiveTimers() {
    final activeTimers = unifiedTimerController.getActiveTimersByPlugin(
      'habits',
    );
    return Map.fromEntries(
      activeTimers.map(
        (state) => MapEntry(state.id, state.status == TimerStatus.running),
      ),
    );
  }

  /// 检查习惯是否正在计时
  bool isHabitTiming(String habitId) {
    final state = unifiedTimerController.getTimer(habitId);
    return state != null && state.status == TimerStatus.running;
  }

  /// 设置计时器回调
  void _setupTimerCallback(String habitId, TimerUpdateCallback callback) {
    // 订阅统一计时器事件
    final subscriptionId = EventManager.instance.subscribe(
      'unified_timer_updated',
      (args) {
        if (args is UnifiedTimerEventArgs) {
          final state = args.timerState as TimerState;
          if (state.id == habitId) {
            callback(state.elapsed.inSeconds);
          }
        }
      },
    );

    // 启动时立即调用一次
    final state = unifiedTimerController.getTimer(habitId);
    if (state != null) {
      callback(state.elapsed.inSeconds);
    }
  }
}
