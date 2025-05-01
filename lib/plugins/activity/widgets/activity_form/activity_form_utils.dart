import 'package:flutter/material.dart';

/// 计算活动持续时间（分钟）
int calculateDuration(DateTime selectedDate, TimeOfDay startTime, TimeOfDay endTime) {
  final startDateTime = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    startTime.hour,
    startTime.minute,
  );
  final endDateTime = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    endTime.hour,
    endTime.minute,
  );

  // 处理跨天情况
  final duration = endDateTime.isAfter(startDateTime)
      ? endDateTime.difference(startDateTime)
      : endDateTime.add(const Duration(days: 1)).difference(startDateTime);

  return duration.inMinutes;
}

/// 获取活动的开始和结束时间
TimeOfDay getInitialTime({
  DateTime? activityTime,
  DateTime? initialTime,
  DateTime? lastActivityEndTime,
  required DateTime selectedDate,
  bool isStartTime = true,
}) {
  if (activityTime != null) {
    return TimeOfDay.fromDateTime(activityTime);
  }

  if (initialTime != null) {
    return TimeOfDay.fromDateTime(initialTime);
  }

  if (isStartTime && lastActivityEndTime != null) {
    return TimeOfDay.fromDateTime(lastActivityEndTime);
  }

  if (isStartTime) {
    return TimeOfDay.fromDateTime(selectedDate);
  }

  return TimeOfDay.fromDateTime(DateTime.now());
}