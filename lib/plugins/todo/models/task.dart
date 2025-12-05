import 'package:flutter/material.dart';
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
  
  // 启动任务计时
  void startTimer() {
    if (status != TaskStatus.inProgress) {
      status = TaskStatus.inProgress;
    }
    startTime = DateTime.now();
    duration = null; // 重置持续时间
  }
  
  // 停止任务计时并计算持续时间
  void stopTimer() {
    if (startTime != null) {
      final now = DateTime.now();
      final currentDuration = now.difference(startTime!);
      
      // 如果已有记录的持续时间，则累加
      if (duration != null) {
        duration = duration! + currentDuration;
      } else {
        duration = currentDuration;
      }
    }
  }
  
  // 完成任务，停止计时
  void completeTask() {
    stopTimer();
    status = TaskStatus.done;
  }
  
  // 格式化显示持续时间
  String get formattedDuration {
    if (duration == null) {
      if (startTime != null && status == TaskStatus.inProgress) {
        // 计算当前进行中的时间
        final currentDuration = DateTime.now().difference(startTime!);
        return _formatDuration(currentDuration);
      }
      return '00:00:00';
    }
    return _formatDuration(duration!);
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