import 'package:flutter/material.dart';
import '../activity_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Activity插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class ActivityPromptReplacements {
  final ActivityPlugin _plugin;

  ActivityPromptReplacements(this._plugin);

  /// 获取活动数据并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式, 默认今天)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式, 默认今天)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, dur, avg, topTags } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无description)
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getActivities(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final dateRange = _parseDateRange(params);

      // 2. 调用 jsAPI 获取日期范围内的所有活动数据
      final allActivities = await _getActivitiesInRange(
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      // 3. 根据 customFields 或 mode 转换数据
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          allActivities,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertByMode(allActivities, mode);
      }

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取活动数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取活动数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 解析日期范围参数
  Map<String, DateTime> _parseDateRange(Map<String, dynamic> params) {
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

    // 如果没有提供日期，使用当天
    if (startDate == null && endDate == null) {
      final now = DateTime.now();
      startDate = DateTime(now.year, now.month, now.day);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (startDate != null && endDate == null) {
      // 如果只提供了开始日期，结束日期设为开始日期的当天结束
      endDate = DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
    } else if (startDate == null && endDate != null) {
      // 如果只提供了结束日期，开始日期设为结束日期的当天开始
      startDate = DateTime(endDate.year, endDate.month, endDate.day);
    }

    return {
      'startDate': startDate!,
      'endDate': endDate!,
    };
  }

  /// 获取指定日期范围内的所有活动 (复用插件的 ActivityService)
  Future<List<Map<String, dynamic>>> _getActivitiesInRange(
    DateTime start,
    DateTime end,
  ) async {
    List<Map<String, dynamic>> allActivities = [];

    // 计算日期范围内的每一天
    for (DateTime date = DateTime(start.year, start.month, start.day);
        date.isBefore(DateTime(end.year, end.month, end.day).add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      // 直接调用插件的 ActivityService 获取当天的活动
      final dailyActivities = await _plugin.activityService.getActivitiesForDate(date);

      // 过滤出在时间范围内的活动
      final filteredActivities = dailyActivities.where((activity) {
        return (activity.startTime.isAfter(start) || activity.startTime.isAtSameMomentAs(start)) &&
            (activity.endTime.isBefore(end) || activity.endTime.isAtSameMomentAs(end));
      }).toList();

      // 转换为 JSON 格式
      allActivities.addAll(filteredActivities.map((a) => a.toJson()).toList());
    }

    // 按开始时间排序
    allActivities.sort((a, b) {
      final aStart = DateTime.parse(a['startTime'] as String);
      final bStart = DateTime.parse(b['startTime'] as String);
      return aStart.compareTo(bStart);
    });

    return allActivities;
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
  Map<String, dynamic> _convertByMode(
    List<Map<String, dynamic>> activities,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(activities);
      case AnalysisMode.compact:
        return _buildCompact(activities);
      case AnalysisMode.full:
        return _buildFull(activities);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 50,
  ///     "dur": 3600,
  ///     "avg": 72,
  ///     "topTags": [{"tag": "学习", "cnt": 20, "dur": 1200}]
  ///   }
  /// }
  Map<String, dynamic> _buildSummary(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'dur': 0,
        'avg': 0,
      });
    }

    // 计算总时长
    int totalDuration = 0;
    final Map<String, int> tagDurations = {}; // 标签时长统计
    final Map<String, int> tagCounts = {}; // 标签次数统计

    for (final activity in activities) {
      final startTime = DateTime.parse(activity['startTime'] as String);
      final endTime = DateTime.parse(activity['endTime'] as String);
      final duration = endTime.difference(startTime).inMinutes;

      totalDuration += duration;

      // 统计标签
      final tags = (activity['tags'] as List?)?.cast<String>() ?? [];
      for (final tag in tags) {
        tagDurations[tag] = (tagDurations[tag] ?? 0) + duration;
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // 计算平均时长
    final avgDuration = (totalDuration / activities.length).round();

    // 生成标签排行（按时长降序）
    final topTags = tagDurations.entries.map((entry) {
      return {
        'tag': entry.key,
        'cnt': tagCounts[entry.key]!,
        'dur': entry.value,
      };
    }).toList()
      ..sort((a, b) => (b['dur'] as int).compareTo(a['dur'] as int));

    // 只保留前5个标签
    final topTagsLimited = topTags.take(5).toList();

    return FieldUtils.buildSummaryResponse({
      'total': activities.length,
      'dur': totalDuration,
      'avg': avgDuration,
      if (topTagsLimited.isNotEmpty) 'topTags': topTagsLimited,
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "total": 50, "dur": 3600 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "title": "阅读",
  ///       "start": "2025-01-15T09:00:00",
  ///       "end": "2025-01-15T10:30:00",
  ///       "dur": 90,
  ///       "tags": ["学习"],
  ///       "mood": "😊"
  ///     }
  ///   ]
  /// }
  Map<String, dynamic> _buildCompact(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0, 'dur': 0},
        [],
      );
    }

    // 计算总时长
    int totalDuration = 0;
    for (final activity in activities) {
      final startTime = DateTime.parse(activity['startTime'] as String);
      final endTime = DateTime.parse(activity['endTime'] as String);
      totalDuration += endTime.difference(startTime).inMinutes;
    }

    // 简化记录（移除 description 字段）
    final compactRecords = activities.map((activity) {
      final startTime = DateTime.parse(activity['startTime'] as String);
      final endTime = DateTime.parse(activity['endTime'] as String);
      final duration = endTime.difference(startTime).inMinutes;

      final record = {
        'id': activity['id'],
        'title': activity['title'],
        'start': FieldUtils.formatDateTime(startTime),
        'end': FieldUtils.formatDateTime(endTime),
        'dur': duration,
      };

      // 只添加非空字段
      if (activity['tags'] != null && (activity['tags'] as List).isNotEmpty) {
        record['tags'] = activity['tags'];
      }
      if (activity['mood'] != null && (activity['mood'] as String).isNotEmpty) {
        record['mood'] = activity['mood'];
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': activities.length,
        'dur': totalDuration,
      },
      compactRecords,
    );
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: jsAPI 的原始数据
  Map<String, dynamic> _buildFull(List<Map<String, dynamic>> activities) {
    return FieldUtils.buildFullResponse(activities);
  }

  /// 释放资源
  void dispose() {}
}