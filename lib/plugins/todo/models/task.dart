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
}