import 'package:flutter/material.dart';
import 'package:Memento/core/services/timer/unified_timer_controller.dart';
import 'package:Memento/core/services/timer/models/timer_state.dart';
import 'subtask.dart';

enum TaskPriority { low, medium, high }
enum TaskStatus { todo, inProgress, done }

class Task {
  final String id;
  String title;
  String? description;
  final DateTime createdAt;
  DateTime? startDate;
  DateTime? dueDate;
  TaskPriority priority;
  TaskStatus status;
  List<String> tags;
  List<Subtask> subtasks;
  List<DateTime> reminders;

  final DateTime? completedDate;
  DateTime? startTime; // 记录任务开始时间
  Duration? duration; // 记录任务持续时间

  // 任务图标
  IconData? icon;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.startDate,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    List<String>? tags,
    List<Subtask>? subtasks,
    List<DateTime>? reminders,
    this.completedDate,
    this.startTime,
    this.duration,
    this.icon,
  })  : subtasks = subtasks ?? [],
        reminders = reminders ?? [],
        tags = tags ?? [];

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    List<String>? tags,
    List<Subtask>? subtasks,
    List<DateTime>? reminders,
    DateTime? completedDate,
    DateTime? startTime,
    Duration? duration,
    IconData? icon,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      reminders: reminders ?? this.reminders,
      completedDate: completedDate ?? this.completedDate,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority.index,
        'status': status.index,
        'tags': tags,
        'subtasks': subtasks.map((e) => e.toJson()).toList(),
        'reminders': reminders.map((e) => e.toIso8601String()).toList(),
        'completedDate': completedDate?.toIso8601String(),
        'startTime': startTime?.toIso8601String(),
        'duration': duration?.inMilliseconds, // 将持续时间转换为毫秒存储
        'iconCodePoint': icon?.codePoint, // 存储图标的 codePoint
        'iconFontFamily': icon?.fontFamily, // 存储图标的字体族
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        createdAt: DateTime.parse(json['createdAt']),
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        priority: TaskPriority.values[json['priority']],
        status: TaskStatus.values[json['status']],
        tags: json['tags'] != null
            ? List<String>.from(json['tags'])
            : [],
        subtasks: (json['subtasks'] as List)
            .map((e) => Subtask.fromJson(e))
            .toList(),
        reminders: (json['reminders'] as List)
            .map((e) => DateTime.parse(e))
            .toList(),
        completedDate: json['completedDate'] != null
            ? DateTime.parse(json['completedDate'])
            : null,
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'])
            : null,
        duration: json['duration'] != null
            ? Duration(milliseconds: json['duration'])
            : null,
        icon: json['iconCodePoint'] != null && json['iconFontFamily'] != null
            ? IconData(
                json['iconCodePoint'],
                fontFamily: json['iconFontFamily'],
              )
            : null,
      );

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.done:
        return Icons.check_circle_outline;
    }
  }
  
  // 启动任务计时（委托给统一控制器）
  void startTimer() {
    // 检查是否已有运行中的计时器
    final existingTimer = unifiedTimerController.getTimer(id);
    if (existingTimer != null && existingTimer.status == TimerStatus.running) {
      // 计时器已在运行，不重复启动
      print('[Task] Timer already running for task: $id');
      return;
    }

    // 使用统一计时器控制器启动
    unifiedTimerController.startTimer(
      id: id,
      name: title,
      type: TimerType.countUp,
      color: Colors.blue,
      icon: Icons.task_alt,
      pluginId: 'todo',
    );

    if (status != TaskStatus.inProgress) {
      status = TaskStatus.inProgress;
    }

    // 保留 startTime 用于向后兼容（但不在计时中使用）
    startTime = DateTime.now();
  }

  // 停止任务计时并保存持续时间（委托给统一控制器）
  void stopTimer() {
    // 从统一控制器获取计时器状态
    final timerState = unifiedTimerController.getTimer(id);
    if (timerState != null) {
      // 保存统一计时器的累计时间
      final elapsed = timerState.elapsed;
      if (duration != null) {
        duration = duration! + elapsed;
      } else {
        duration = elapsed;
      }
    }

    // 停止统一控制器中的计时器
    unifiedTimerController.stopTimer(id);
  }

  // 完成任务，停止计时（委托给统一控制器）
  void completeTask() {
    stopTimer();
    status = TaskStatus.done;
  }

  // 格式化显示持续时间
  String get formattedDuration {
    // 优先从统一计时器获取实时时间
    final timerState = unifiedTimerController.getTimer(id);
    if (timerState != null && timerState.status == TimerStatus.running) {
      // 计时器正在运行，显示实时时间
      final totalDuration = (duration ?? Duration.zero) + timerState.elapsed;
      return _formatDuration(totalDuration);
    }

    // 计时器未运行，显示已保存的时间
    if (duration != null) {
      return _formatDuration(duration!);
    }

    return '00:00:00';
  }
  
  // 格式化时间为 HH:MM:SS 格式
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
  
  // 检查任务是否正在计时
  bool get isTimerRunning {
    return status == TaskStatus.inProgress && startTime != null;
  }
}