import 'package:flutter/material.dart';
import 'subtask.dart';

enum TaskPriority { low, medium, high }
enum TaskStatus { todo, inProgress, done }

class Task {
  final String id;
  String title;
  String? description;
  final DateTime createdAt;
  DateTime? dueDate;
  TaskPriority priority;
  TaskStatus status;
  List<String> tags;
  List<Subtask> subtasks;
  List<DateTime> reminders;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    List<String>? tags,
    List<Subtask>? subtasks,
    List<DateTime>? reminders,
  })  : subtasks = subtasks ?? [],
        reminders = reminders ?? [],
        tags = tags ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority.index,
        'status': status.index,
        'tags': tags,
        'subtasks': subtasks.map((e) => e.toJson()).toList(),
        'reminders': reminders.map((e) => e.toIso8601String()).toList(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        createdAt: DateTime.parse(json['createdAt']),
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