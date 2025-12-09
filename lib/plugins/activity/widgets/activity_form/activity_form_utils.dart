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
    // 如果没有上一个活动，从00:00开始
    return const TimeOfDay(hour: 0, minute: 0);
  }

  // 如果是结束时间，确保不超过23:59
  if (!isStartTime) {
    final now = DateTime.now();
    if (now.hour == 0 && now.minute == 0) {
      // 如果当前是00:00，则返回23:59
      return const TimeOfDay(hour: 23, minute: 59);
    }
  }

  return TimeOfDay.fromDateTime(DateTime.now());
}

/// 确保结束时间不超过23:59
TimeOfDay ensureValidEndTime(TimeOfDay time) {
  if (time.hour == 0 && time.minute == 0) {
    return const TimeOfDay(hour: 23, minute: 59);
  }
  return time;
}