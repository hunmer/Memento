import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class ActivityRecord {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final List<String> tags;
  final String? description;
  final String? mood; // 添加心情字段
  final Color? color; // 活动颜色

  ActivityRecord({
    String? id,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.tags = const [],
    this.description,
    this.mood, // 心情emoji
    this.color, // 活动颜色
  }) : id = id ?? const Uuid().v4();

  // 计算持续时间（分钟）
  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  // 格式化持续时间显示
  String get formattedDuration {
    final hours = durationInMinutes ~/ 60;
    final minutes = durationInMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}時${minutes.toString().padLeft(2, '0')}分';
  }

  // 从JSON创建实例
  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    // 解析颜色（如果存在）
    Color? color;
    if (json['color'] != null) {
      try {
        color = Color(int.parse(json['color']));
      } catch (e) {
        debugPrint('解析颜色失败: $e');
      }
    }
    
    return ActivityRecord(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      title: json['title'],
      tags: List<String>.from(json['tags'] ?? []),
      description: json['description'],
      mood: json['mood'],
      color: color,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'title': title,
      'tags': tags,
      'description': description,
      'mood': mood,
      // ignore: deprecated_member_use
      'color': color?.value.toString(),
    };
  }
}
