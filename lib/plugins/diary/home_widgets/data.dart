/// 日记插件主页小组件数据模型
library;

import 'package:flutter/material.dart';

/// 日记统计项数据
///
/// 用于概览组件中的统计展示
class DiaryStatItemData {
  final String id;
  final String label;
  final String value;
  final bool highlight;
  final Color? color;

  const DiaryStatItemData({
    required this.id,
    required this.label,
    required this.value,
    this.highlight = false,
    this.color,
  });
}

/// 周日记卡片数据
///
/// 用于七日周报组件中的日期卡片数据
class WeekDiaryCardData {
  final DateTime date;
  final bool isToday;
  final String weekday;
  final String dayNumber;
  final String? mood;
  final String? title;
  final bool hasEntry;

  const WeekDiaryCardData({
    required this.date,
    required this.isToday,
    required this.weekday,
    required this.dayNumber,
    this.mood,
    this.title,
    required this.hasEntry,
  });
}
