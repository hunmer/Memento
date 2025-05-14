import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final IconData icon;
  final Color color;
  final String source;
  final int? reminderMinutes; // 提前提醒的分钟数
  final DateTime? completedTime;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    this.endTime,
    required this.icon,
    required this.color,
    this.source = 'default',
    this.reminderMinutes,
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
    String? source,
    int? reminderMinutes,
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
      source: source ?? this.source,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
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
    'source': source,
    'reminderMinutes': reminderMinutes,
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
    source: json['source'] ?? 'default',
    reminderMinutes: json['reminderMinutes'],
    completedTime: json['completedTime'] != null ? DateTime.parse(json['completedTime']) : null,
  );
}