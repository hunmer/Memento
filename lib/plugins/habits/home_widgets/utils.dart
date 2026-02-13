/// 习惯追踪插件主页小组件工具函数
library;

import 'package:flutter/material.dart';
import 'package:Memento/plugins/habits/models/completion_record.dart';

/// 插件主题色
const Color pluginColor = Colors.amber;

/// 获取指定日期的完成时长（分钟）
int getMinutesForDate(List<CompletionRecord> records, DateTime date) {
  final dateStr =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  return records
      .where(
        (r) =>
            '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}' ==
            dateStr,
      )
      .fold<int>(0, (sum, r) => sum + r.duration.inMinutes);
}
