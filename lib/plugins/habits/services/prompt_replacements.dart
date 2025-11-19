import 'package:flutter/material.dart';
import '../habits_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Habits插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class HabitsPromptReplacements {
  final HabitsPlugin _plugin;

  HabitsPromptReplacements(this._plugin);

  /// 获取习惯数据并格式化为文本
  ///
  /// 参数:
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, completions, totalTime, currentStreak } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无notes)
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getHabits(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final dateRange =
          params['startDate'] != null || params['endDate'] != null
              ? _parseDateRange(params)
              : null;

      // 2. 获取所有习惯数据
      final habits = _plugin.getHabitController().getHabits();

      // 3. 获取完成记录 (用于统计)
      final recordController = _plugin.getRecordController();
      final skillController = _plugin.getSkillController();

      // 4. 根据 customFields 或 mode 转换数据
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        // 构建完整数据用于字段过滤
        final fullRecords = <Map<String, dynamic>>[];
        for (final habit in habits) {
          final habitMap = habit.toMap();
          // 获取完成记录
          final records = await recordController.getHabitCompletionRecords(habit.id);
          final filteredRecords = dateRange != null
              ? records.where((r) {
                return r.date.isAfter(
                      dateRange['startDate']!.subtract(const Duration(seconds: 1)),
                    ) &&
                    r.date.isBefore(
                      dateRange['endDate']!.add(const Duration(days: 1)),
                    );
              }).toList()
              : records;
          // 添加统计信息
          habitMap['completionCount'] = filteredRecords.length;
          habitMap['totalDuration'] = filteredRecords.fold<int>(
            0,
            (sum, r) => sum + r.duration.inMinutes,
          );
          // 获取技能名称
          if (habit.skillId != null) {
            try {
              final skill = skillController.getSkillById(habit.skillId);
              habitMap['skillName'] = skill.title;
            } catch (_) {}
          }
          fullRecords.add(habitMap);
        }
        final filteredRecords = FieldUtils.simplifyRecords(
          fullRecords,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = await _convertByMode(
          habits,
          recordController,
          skillController,
          mode,
          dateRange,
        );
      }

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取习惯数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取习惯数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取统计数据
  ///
  /// 参数:
  /// - habitId: 习惯ID (可选, 不提供则返回全局统计)
  ///
  /// 返回格式:
  /// {
  ///   "habitId": "uuid",
  ///   "totalDurationMinutes": 3600,
  ///   "completionCount": 50,
  ///   "averageDuration": 72
  /// }
  Future<String> getStats(Map<String, dynamic> params) async {
    try {
      final String? habitId = params['habitId'] as String?;
      final recordController = _plugin.getRecordController();

      if (habitId != null) {
        // 单个习惯统计
        final totalDuration = await recordController.getTotalDuration(habitId);
        final completionCount = await recordController.getCompletionCount(
          habitId,
        );
        final avgDuration =
            completionCount > 0
                ? (totalDuration.toDouble() / completionCount.toDouble())
                    .round()
                : 0;

        return FieldUtils.toJsonString({
          'habitId': habitId,
          'totalDurationMinutes': totalDuration,
          'completionCount': completionCount,
          'averageDuration': avgDuration,
        });
      } else {
        // 全局统计
        final habits = _plugin.getHabitController().getHabits();
        int totalDuration = 0;
        int totalCompletions = 0;

        for (final habit in habits) {
          final duration = await recordController.getTotalDuration(habit.id);
          final completions = await recordController.getCompletionCount(
            habit.id,
          );
          final int durationInt = duration.toInt();
          final int completionsInt = completions.toInt();
          totalDuration = totalDuration + durationInt;
          totalCompletions = totalCompletions + completionsInt;
        }

        final avgDuration =
            totalCompletions > 0
                ? (totalDuration.toDouble() / totalCompletions.toDouble())
                    .round()
                : 0;

        return FieldUtils.toJsonString({
          'totalHabits': habits.length,
          'totalDurationMinutes': totalDuration,
          'totalCompletions': totalCompletions,
          'averageDuration': avgDuration,
        });
      }
    } catch (e) {
      debugPrint('获取统计数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取统计数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 解析日期范围参数
  Map<String, DateTime>? _parseDateRange(Map<String, dynamic> params) {
    final String? startDateStr = params['startDate'] as String?;
    final String? endDateStr = params['endDate'] as String?;

    DateTime? startDate;
    DateTime? endDate;

    // 解析日期字符串
    if (startDateStr != null) {
      startDate = _parseDate(startDateStr);
    }

    if (endDateStr != null) {
      endDate = _parseDate(endDateStr);
    }

    if (startDate == null && endDate == null) {
      return null;
    }

    return {
      'startDate': startDate ?? DateTime(2000, 1, 1),
      'endDate': endDate ?? DateTime.now(),
    };
  }

  /// 尝试多种格式解析日期字符串
  DateTime _parseDate(String dateStr) {
    // 尝试解析 yyyy/MM/dd 格式
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}

    // 尝试解析 yyyy-MM-dd 格式
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}

    // 尝试使用DateTime.parse
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // 如果所有尝试都失败，抛出异常
    throw FormatException('无法解析日期: $dateStr');
  }

  /// 根据模式转换数据
  Future<Map<String, dynamic>> _convertByMode(
    List habits,
    dynamic recordController,
    dynamic skillController,
    AnalysisMode mode,
    Map<String, DateTime>? dateRange,
  ) async {
    switch (mode) {
      case AnalysisMode.summary:
        return await _buildSummary(habits, recordController, dateRange);
      case AnalysisMode.compact:
        return await _buildCompact(
          habits,
          recordController,
          skillController,
          dateRange,
        );
      case AnalysisMode.full:
        return await _buildFull(
          habits,
          recordController,
          skillController,
          dateRange,
        );
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 10,
  ///     "completions": 150,
  ///     "totalTime": 4500,
  ///     "currentStreak": 7
  ///   }
  /// }
  Future<Map<String, dynamic>> _buildSummary(
    List habits,
    dynamic recordController,
    Map<String, DateTime>? dateRange,
  ) async {
    int totalCompletions = 0;
    int totalTime = 0;

    for (final habit in habits) {
      final records = await recordController.getHabitCompletionRecords(
        habit.id,
      );

      // 如果有日期范围,过滤记录
      final filteredRecords =
          dateRange != null
              ? records.where((r) {
                return r.date.isAfter(
                      dateRange['startDate']!.subtract(
                        const Duration(seconds: 1),
                      ),
                    ) &&
                    r.date.isBefore(
                      dateRange['endDate']!.add(const Duration(days: 1)),
                    );
              }).toList()
              : records;

      final int recordCount = filteredRecords.length;
      totalCompletions = totalCompletions + recordCount;
      for (final record in filteredRecords) {
        final int minutes = record.duration.inMinutes;
        totalTime = totalTime + minutes;
      }
    }

    return FieldUtils.buildSummaryResponse({
      'total': habits.length,
      'completions': totalCompletions,
      'totalTime': totalTime,
      'avg':
          totalCompletions > 0
              ? (totalTime.toDouble() / totalCompletions.toDouble()).round()
              : 0,
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "total": 10, "completions": 150 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "title": "晨跑",
  ///       "durationMinutes": 30,
  ///       "skillName": "健康生活",
  ///       "tags": ["运动"]
  ///     }
  ///   ]
  /// }
  Future<Map<String, dynamic>> _buildCompact(
    List habits,
    dynamic recordController,
    dynamic skillController,
    Map<String, DateTime>? dateRange,
  ) async {
    int totalCompletions = 0;
    int totalTime = 0;
    final compactRecords = <Map<String, dynamic>>[];

    for (final habit in habits) {
      final records = await recordController.getHabitCompletionRecords(
        habit.id,
      );

      // 如果有日期范围,过滤记录
      final filteredRecords =
          dateRange != null
              ? records.where((r) {
                return r.date.isAfter(
                      dateRange['startDate']!.subtract(
                        const Duration(seconds: 1),
                      ),
                    ) &&
                    r.date.isBefore(
                      dateRange['endDate']!.add(const Duration(days: 1)),
                    );
              }).toList()
              : records;

      final int recordCount = filteredRecords.length;
      totalCompletions = totalCompletions + recordCount;
      for (final record in filteredRecords) {
        final int minutes = record.duration.inMinutes;
        totalTime = totalTime + minutes;
      }

      // 获取技能名称
      String? skillName;
      if (habit.skillId != null) {
        try {
          final skill = skillController.getSkillById(habit.skillId);
          skillName = skill.title;
        } catch (_) {}
      }

      final record = {
        'id': habit.id,
        'title': habit.title,
        'dur': habit.durationMinutes,
      };

      // 只添加非空字段
      if (skillName != null && skillName.isNotEmpty) {
        record['skill'] = skillName;
      }
      if (habit.tags != null && habit.tags.isNotEmpty) {
        record['tags'] = habit.tags;
      }

      compactRecords.add(record);
    }

    return FieldUtils.buildCompactResponse({
      'total': habits.length,
      'completions': totalCompletions,
      'totalTime': totalTime,
    }, compactRecords);
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: 包含所有习惯的完整数据,包括notes等字段
  Future<Map<String, dynamic>> _buildFull(
    List habits,
    dynamic recordController,
    dynamic skillController,
    Map<String, DateTime>? dateRange,
  ) async {
    final fullRecords = <Map<String, dynamic>>[];

    for (final habit in habits) {
      final habitMap = habit.toMap();

      // 获取完成记录
      final records = await recordController.getHabitCompletionRecords(
        habit.id,
      );
      final filteredRecords =
          dateRange != null
              ? records.where((r) {
                return r.date.isAfter(
                      dateRange['startDate']!.subtract(
                        const Duration(seconds: 1),
                      ),
                    ) &&
                    r.date.isBefore(
                      dateRange['endDate']!.add(const Duration(days: 1)),
                    );
              }).toList()
              : records;

      // 添加统计信息
      habitMap['completionCount'] = filteredRecords.length;
      habitMap['totalDuration'] = filteredRecords.fold<int>(
        0,
        (sum, r) => sum + r.duration.inMinutes,
      );

      // 获取技能名称
      if (habit.skillId != null) {
        try {
          final skill = skillController.getSkillById(habit.skillId);
          habitMap['skillName'] = skill.title;
        } catch (_) {}
      }

      fullRecords.add(habitMap);
    }

    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 释放资源
  void dispose() {}
}
