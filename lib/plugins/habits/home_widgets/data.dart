/// 习惯追踪插件主页小组件数据模型
library;

import 'package:Memento/plugins/habits/models/completion_record.dart';

/// 习惯热力图数据模型
class HabitHeatmapData {
  final String habitId;
  final List<CompletionRecord> records;
  final int totalMinutes;

  const HabitHeatmapData({
    required this.habitId,
    required this.records,
    required this.totalMinutes,
  });
}
