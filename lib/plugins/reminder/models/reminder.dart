import 'package:flutter/material.dart';

/// 提醒频率类型
enum ReminderFrequency {
  none, // 无（手动触发）
  daily, // 每天
  weekly, // 每周
  monthly, // 每月
}

/// 推送方式
enum ReminderPushMethod {
  localNotification, // 本地通知
  fcm, // FCM 推送（占位）
  both, // 两者都使用
}

/// 提醒数据模型
class Reminder {
  final String id;
  String title;
  String content;
  String? imageUrl;

  // 调度配置
  ReminderFrequency frequency;
  List<int> selectedDays; // 周几 (1-7) 或日期 (1-31)
  TimeOfDay time;

  // 推送配置
  ReminderPushMethod pushMethod;

  // 状态
  bool isEnabled;
  DateTime createdAt;
  DateTime? lastTriggeredAt;
  DateTime? nextTriggerAt;

  // 其他
  String? groupId; // 可选分组
  int priority; // 优先级 0-3

  Reminder({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.frequency,
    this.selectedDays = const [],
    required this.time,
    this.pushMethod = ReminderPushMethod.localNotification,
    this.isEnabled = true,
    required this.createdAt,
    this.lastTriggeredAt,
    this.nextTriggerAt,
    this.groupId,
    this.priority = 0,
  });

  // 序列化
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'frequency': frequency.index,
      'selectedDays': selectedDays,
      'time':
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'pushMethod': pushMethod.index,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
      'nextTriggerAt': nextTriggerAt?.toIso8601String(),
      'groupId': groupId,
      'priority': priority,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['time'] as String).split(':');
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      frequency: ReminderFrequency.values[json['frequency'] as int? ?? 1],
      selectedDays:
          (json['selectedDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      pushMethod: ReminderPushMethod.values[json['pushMethod'] as int? ?? 0],
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastTriggeredAt:
          json['lastTriggeredAt'] != null
              ? DateTime.parse(json['lastTriggeredAt'] as String)
              : null,
      nextTriggerAt:
          json['nextTriggerAt'] != null
              ? DateTime.parse(json['nextTriggerAt'] as String)
              : null,
      groupId: json['groupId'] as String?,
      priority: json['priority'] as int? ?? 0,
    );
  }

  // 计算下次触发时间
  DateTime calculateNextTriggerTime() {
    final now = DateTime.now();
    final targetTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    switch (frequency) {
      case ReminderFrequency.none:
        return now;

      case ReminderFrequency.daily:
        // 如果今天的时间还没到，就是今天；否则是明天
        if (targetTime.isAfter(now)) {
          return targetTime;
        }
        return targetTime.add(const Duration(days: 1));

      case ReminderFrequency.weekly:
        if (selectedDays.isEmpty) {
          return targetTime.add(const Duration(days: 1));
        }
        // 找到下一个匹配的星期几
        for (int i = 0; i <= 7; i++) {
          final checkDate = targetTime.add(Duration(days: i));
          final weekday = checkDate.weekday; // 1-7 (周一-周日)
          if (selectedDays.contains(weekday) && checkDate.isAfter(now)) {
            return checkDate;
          }
        }
        return targetTime.add(const Duration(days: 7));

      case ReminderFrequency.monthly:
        if (selectedDays.isEmpty) {
          return targetTime.add(const Duration(days: 1));
        }
        // 找到下一个匹配的日期
        for (int i = 0; i <= 31; i++) {
          final checkDate = targetTime.add(Duration(days: i));
          if (selectedDays.contains(checkDate.day) && checkDate.isAfter(now)) {
            return checkDate;
          }
        }
        // 如果本月没有匹配，找下个月
        return DateTime(
          now.year,
          now.month + 1,
          selectedDays.first,
          time.hour,
          time.minute,
        );
    }
  }

  // 获取显示文本
  String getFrequencyDisplayText() {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    switch (frequency) {
      case ReminderFrequency.none:
        return '无';
      case ReminderFrequency.daily:
        return '每天 $timeStr';
      case ReminderFrequency.weekly:
        if (selectedDays.length == 7) {
          return '每天 $timeStr';
        }
        final weekDays = ['一', '二', '三', '四', '五', '六', '日'];
        final days = selectedDays.map((d) => weekDays[d - 1]).join('、');
        return '周$days $timeStr';
      case ReminderFrequency.monthly:
        if (selectedDays.length == 31) {
          return '每天 $timeStr';
        }
        final days = selectedDays.map((d) => '$d').join('、');
        return '每月$days日 $timeStr';
    }
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    ReminderFrequency? frequency,
    List<int>? selectedDays,
    TimeOfDay? time,
    ReminderPushMethod? pushMethod,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? lastTriggeredAt,
    DateTime? nextTriggerAt,
    String? groupId,
    int? priority,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      frequency: frequency ?? this.frequency,
      selectedDays: selectedDays ?? List.from(this.selectedDays),
      time: time ?? this.time,
      pushMethod: pushMethod ?? this.pushMethod,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      nextTriggerAt: nextTriggerAt ?? this.nextTriggerAt,
      groupId: groupId ?? this.groupId,
      priority: priority ?? this.priority,
    );
  }
}
