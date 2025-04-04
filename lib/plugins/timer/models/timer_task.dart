import 'dart:convert';
import 'package:flutter/material.dart';
import 'timer_item.dart';
import '../timer_plugin.dart';

/// 计时器任务，一个任务可以包含多个计时器
class TimerTask {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final List<TimerItem> timerItems;
  final DateTime createdAt;
  bool isRunning;
  String group;
  Duration _elapsedDuration = Duration.zero;

  TimerTask({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.timerItems,
    required this.createdAt,
    this.isRunning = false,
    required this.group,
  });

  // 从JSON构造
  factory TimerTask.fromJson(Map<String, dynamic> json) {
    // 使用预定义的MaterialIcons中的图标
    final iconData =
        json['icon'] != null
            ? IconData(
              json['icon'] as int,
              fontFamily: 'MaterialIcons',
              fontPackage: null,
              matchTextDirection: false,
            )
            : Icons.timer; // 提供一个默认图标

    return TimerTask(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      icon: iconData,
      timerItems:
          (json['timerItems'] as List)
              .map((item) => TimerItem.fromJson(item))
              .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRunning: json['isRunning'] as bool,
      group: json['group'] as String? ?? '默认',
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'icon': icon.codePoint,
      'timerItems': timerItems.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isRunning': isRunning,
      'group': group,
    };
  }

  // 创建新任务
  factory TimerTask.create({
    required String name,
    required Color color,
    required IconData icon,
    required List<TimerItem> timerItems,
    String? group,
  }) {
    return TimerTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color,
      icon: icon,
      timerItems: timerItems,
      createdAt: DateTime.now(),
      group: group ?? '默认',
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

  // 获取总时长（所有计时器项的总和）
  Duration get totalDuration {
    Duration total = Duration.zero;
    for (var timer in timerItems) {
      total += timer.duration;
    }
    return total;
  }

  // 获取已完成时长
  Duration get completedDuration {
    Duration completed = Duration.zero;
    for (var timer in timerItems) {
      completed += timer.completedDuration;
    }
    return completed;
  }

  // 获取已经过去的时长
  Duration get elapsedDuration => _elapsedDuration;

  // 获取进度（0.0 - 1.0）
  double get progress {
    if (totalDuration.inSeconds == 0) return 0.0;
    return completedDuration.inSeconds / totalDuration.inSeconds;
  }

  // 启动任务
  void start() {
    if (!isRunning) {
      isRunning = true;
      _startNextTimer();
      TimerPlugin.instance.startNotificationService(this);
    }
  }

  // 启动下一个计时器
  void _startNextTimer() {
    if (isRunning && timerItems.isNotEmpty) {
      final currentIndex = timerItems.indexWhere((timer) => timer.isRunning);
      if (currentIndex == -1) {
        // 没有正在运行的计时器，启动第一个
        final firstTimer = timerItems.first;
        firstTimer.onComplete = () {
          if (isRunning) {
            _startNextTimer();
          }
        };
        firstTimer.onUpdate = (elapsed) {
          updateElapsedDuration(elapsed);
        };
        firstTimer.start();
      } else if (currentIndex < timerItems.length - 1) {
        // 当前计时器完成，启动下一个
        final nextTimer = timerItems[currentIndex + 1];
        nextTimer.onComplete = () {
          if (isRunning) {
            _startNextTimer();
          }
        };
        nextTimer.onUpdate = (elapsed) {
          updateElapsedDuration(elapsed);
        };
        nextTimer.start();
      } else {
        // 所有计时器都完成了
        isRunning = false;
        TimerPlugin.instance.stopNotificationService();
      }
    }
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
    }
    _elapsedDuration = Duration.zero;
    TimerPlugin.instance.stopNotificationService();
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

  // 复制并修改任务
  TimerTask copyWith({
    String? name,
    Color? color,
    IconData? icon,
    List<TimerItem>? timerItems,
    bool? isRunning,
    String? group,
  }) {
    return TimerTask(
      id: this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      timerItems: timerItems ?? List.from(this.timerItems),
      createdAt: this.createdAt,
      isRunning: isRunning ?? this.isRunning,
      group: group ?? this.group,
    );
  }
}
