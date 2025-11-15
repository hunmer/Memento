import 'package:flutter/material.dart';
import 'timer_item.dart';
import '../timer_plugin.dart';
import '../../../../core/notification_manager.dart';
import '../../../../core/event/event_manager.dart';

class TimerTaskEventArgs extends EventArgs {
  final TimerTask task;
  TimerTaskEventArgs(this.task, [String eventName = 'timer_task_changed'])
    : super(eventName);
}

enum RepeatingPattern { daily, weekly, monthly }

/// 计时器任务，一个任务可以包含多个计时器
class TimerTask {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final List<TimerItem> timerItems;
  final DateTime createdAt;
  final int repeatCount; // 配置的重复次数
  int _currentRepeatCount; // 当前剩余的重复次数
  bool isRunning;
  String group;
  Duration _elapsedDuration = Duration.zero;
  final bool enableNotification; // 是否启用消息提醒

  TimerTask({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.timerItems,
    required this.createdAt,
    this.isRunning = false,
    required this.group,
    this.repeatCount = 1,
    this.enableNotification = false, // 默认关闭消息提醒
  }) : _currentRepeatCount = repeatCount;

  // 从JSON构造
  factory TimerTask.fromJson(Map<String, dynamic> json) {
    // 使用预定义的MaterialIcons常量
    final icon =
        json['icon'] != null
            ? IconData(json['icon'] as int, fontFamily: 'MaterialIcons')
            : Icons.timer_rounded;

    return TimerTask(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      icon: icon,
      timerItems:
          (json['timerItems'] as List)
              .map((item) => TimerItem.fromJson(item))
              .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRunning: json['isRunning'] as bool,
      group: json['group'] as String? ?? '默认',
      repeatCount: json['repeatCount'] as int? ?? 1,
      enableNotification: json['enableNotification'] as bool? ?? false,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'icon': icon.codePoint,
      'timerItems': timerItems.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isRunning': isRunning,
      'group': group,
      'repeatCount': repeatCount,
      'enableNotification': enableNotification,
    };
  }

  // 创建新任务
  factory TimerTask.create({
    required String id,
    required String name,
    required Color color,
    required IconData icon,
    required List<TimerItem> timerItems,
    String? group,
    DateTime? reminderTime,
    bool? isRepeating,
    RepeatingPattern? repeatingPattern,
    int? repeatCount,
    List<String>? steps,
    bool enableNotification = false,
  }) {
    return TimerTask(
      id: id,
      name: name,
      color: color,
      icon: icon,
      timerItems: timerItems,
      createdAt: DateTime.now(),
      group: group ?? '默认',
      repeatCount: repeatCount ?? 1,
      enableNotification: enableNotification,
    );
  }

  // 获取当前活动的计时器
  TimerItem? get activeTimer {
    for (var timer in timerItems) {
      if (timer.isRunning) {
        return timer;
      }
    }
    return null;
  }

  // 获取已经过去的时长
  Duration get elapsedDuration => _elapsedDuration;

  // 启动任务
  void start() {
    if (!isRunning) {
      isRunning = true;
      _startNextTimer();
      TimerPlugin.instance.startNotificationService(this);
      EventManager.instance.broadcast(
        'timer_task_changed',
        TimerTaskEventArgs(this),
      );
    }
  }

  int getCurrentIndex() {
    return timerItems.indexWhere((timer) => !timer.isCompleted);
  }

  // 启动下一个计时器
  void _startNextTimer() {
    if (!isRunning || timerItems.isEmpty) return;

    // 确保所有计时器都停止
    for (var timer in timerItems) {
      if (timer.isRunning) {
        timer.pause();
      }
    }

    final currentIndex = getCurrentIndex();
    if (currentIndex == -1) {
      // 检查是否有剩余重复次数
      if (_currentRepeatCount > 1) {
        _currentRepeatCount--;
        // 重置所有计时器
        for (var timer in timerItems) {
          timer.reset();
          timer.resetRepeatCount();
        }
        // 重新开始第一个计时器
        _startNextTimer();
        return;
      }

      // 所有计时器都完成了
      isRunning = false;
      TimerPlugin.instance.stopNotificationService();

      // 发送完成通知
      if (enableNotification) {
        NotificationManager.showInstantNotification(
          title: '计时任务完成',
          body: '计时任务"$name"已完成',
        );
      }
      return;
    }

    final nextTimer = timerItems[currentIndex];
    nextTimer.onComplete = () {
      if (isRunning) {
        _startNextTimer();
      }
    };
    nextTimer.onUpdate = (elapsed) {
      updateElapsedDuration(elapsed);
      // 强制UI更新
      TimerPlugin.instance.updateTask(this);
    };
    nextTimer.start();
  }

  // 计时器完成时的回调
  void onTimerComplete(TimerItem completedTimer) {
    if (isRunning) {
      _startNextTimer();
    }
  }

  // 暂停任务
  void pause() {
    if (isRunning) {
      isRunning = false;

      // 暂停当前活动的计时器
      final active = activeTimer;
      if (active != null) {
        active.pause();
      }
      TimerPlugin.instance.stopNotificationService();
      EventManager.instance.broadcast(
        'timer_task_changed',
        TimerTaskEventArgs(this),
      );
    }
  }

  // 恢复任务
  void resume() {
    if (!isRunning) {
      isRunning = true;
      _startNextTimer();
      TimerPlugin.instance.startNotificationService(this);
    }
  }

  // 重置任务
  void reset() {
    isRunning = false;
    for (var timer in timerItems) {
      timer.onComplete = null;
      timer.reset();
      timer.resetRepeatCount();
    }
    _elapsedDuration = Duration.zero;
    _currentRepeatCount = repeatCount; // 重置当前重复次数为配置值
    TimerPlugin.instance.stopNotificationService();
    EventManager.instance.broadcast(
      'timer_task_changed',
      TimerTaskEventArgs(this),
    );
  }

  void toggle() {
    if (isRunning) {
      pause();
    } else {
      resume();
    }
  }

  // 更新已经过去的时长
  void updateElapsedDuration(Duration elapsed) {
    _elapsedDuration = elapsed;
    if (isRunning) {
      TimerPlugin.instance.updateTask(this);
    }
  }

  // 检查任务是否已完成
  bool get isCompleted {
    for (var timer in timerItems) {
      if (!timer.isCompleted) {
        return false;
      }
    }
    return true;
  }

  // 获取当前活动的计时器的重复次数
  int? get activeTimerRepeatCount => activeTimer?.repeatCount;

  // 获取当前剩余重复次数
  int get remainingRepeatCount => _currentRepeatCount;

  // 复制并修改任务
  TimerTask copyWith({
    String? name,
    Color? color,
    IconData? icon,
    List<TimerItem>? timerItems,
    bool? isRunning,
    String? group,
    DateTime? reminderTime,
    bool? isRepeating,
    RepeatingPattern? repeatingPattern,
    int? repeatCount,
    bool enableNotification = false,
  }) {
    return TimerTask(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      timerItems: timerItems ?? List.from(this.timerItems),
      createdAt: createdAt,
      isRunning: isRunning ?? this.isRunning,
      group: group ?? this.group,
      repeatCount: repeatCount ?? this.repeatCount,
      enableNotification: enableNotification,
    );
  }
}
