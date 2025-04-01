import 'package:uuid/uuid.dart';

class ActivityRecord {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final List<String> tags;
  final String? description;
  final String? mood; // 添加心情字段

  ActivityRecord({
    String? id,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.tags = const [],
    this.description,
    this.mood, // 心情emoji
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
    return ActivityRecord(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      title: json['title'],
      tags: List<String>.from(json['tags'] ?? []),
      description: json['description'],
      mood: json['mood'],
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
    };
  }
}
