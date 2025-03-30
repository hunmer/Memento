class ActivityRecord {
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final List<String> tags;
  final String? description;

  ActivityRecord({
    required this.startTime,
    required this.endTime,
    required this.title,
    this.tags = const [],
    this.description,
  });

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
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      title: json['title'],
      tags: List<String>.from(json['tags'] ?? []),
      description: json['description'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'title': title,
      'tags': tags,
      'description': description,
    };
  }
}