import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final IconData icon;
  final Color color;
  final bool isSystem;
  final DateTime? reminder;
  final DateTime? completedTime;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    this.endTime,
    required this.icon,
    required this.color,
    this.isSystem = false,
    this.reminder,
    this.completedTime,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    IconData? icon,
    Color? color,
    bool? isSystem,
    DateTime? reminder,
    DateTime? completedTime,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSystem: isSystem ?? this.isSystem,
      reminder: reminder ?? this.reminder,
      completedTime: completedTime ?? this.completedTime,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'icon': icon.codePoint,
    'color': color.value,
    'isSystem': isSystem,
    'reminder': reminder?.toIso8601String(),
    'completedTime': completedTime?.toIso8601String(),
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
    color: Color(json['color']),
    isSystem: json['isSystem'] ?? false,
    reminder: json['reminder'] != null ? DateTime.parse(json['reminder']) : null,
    completedTime: json['completedTime'] != null ? DateTime.parse(json['completedTime']) : null,
  );
}