import 'package:flutter/material.dart';
import '../checkin_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Checkin插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class CheckinPromptReplacements {
  CheckinPromptReplacements();

  /// 获取打卡数据并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式, 默认今天)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式, 默认今天)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, done, streak, topGroups } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无note)
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getCheckinHistory(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final dateRange = _parseDateRange(params);

      // 2. 获取日期范围内的所有打卡记录
      final allRecords = _getRecordsInRange(
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      // 3. 应用字段过滤
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          allRecords,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertByMode(allRecords, mode);
      }

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取打卡数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取打卡数据时出错',
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

  /// 获取指定日期范围内的所有打卡记录
  List<Map<String, dynamic>> _getRecordsInRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final checkinItems = CheckinPlugin.instance.checkinItems;
    final records = <Map<String, dynamic>>[];

    for (final item in checkinItems) {
      // 筛选指定日期范围内的记录
      final dateRangeRecords = item.checkInRecords.entries
          .where((entry) {
        // 解析日期字符串为DateTime对象
        final dateParts = entry.key.split('-');
        if (dateParts.length != 3) return false;

        final date = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );

        return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      })
          .expand((entry) => entry.value) // 展开List<CheckinRecord>
          .map((record) {
        return {
          'itemName': item.name,
          'group': item.group.isNotEmpty ? item.group : null,
          'checkinTime': record.checkinTime,
          'startTime': record.startTime,
          'endTime': record.endTime,
          'note': record.note,
        };
      })
          .toList();

      records.addAll(dateRangeRecords);
    }

    // 按打卡时间排序
    records.sort((a, b) =>
        (a['checkinTime'] as DateTime).compareTo(b['checkinTime'] as DateTime));

    return records;
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
    List<Map<String, dynamic>> records,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(records);
      case AnalysisMode.compact:
        return _buildCompact(records);
      case AnalysisMode.full:
        return _buildFull(records);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 50,
  ///     "done": 20,
  ///     "streak": 7,
  ///     "topGroups": [{"group": "健康习惯", "cnt": 15}]
  ///   }
  /// }
  Map<String, dynamic> _buildSummary(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'done': 0,
        'streak': 0,
      });
    }

    // 获取所有打卡项目
    final checkinItems = CheckinPlugin.instance.checkinItems;

    // 计算今日已打卡数量
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayRecords = records.where((record) {
      final checkinTime = record['checkinTime'] as DateTime;
      return checkinTime.isAfter(todayStart) && checkinTime.isBefore(todayEnd);
    }).length;

    // 统计分组打卡次数
    final Map<String, int> groupCounts = {};
    for (final record in records) {
      final group = record['group'] as String?;
      if (group != null && group.isNotEmpty) {
        groupCounts[group] = (groupCounts[group] ?? 0) + 1;
      }
    }

    // 生成分组排行（按次数降序）
    final topGroups = groupCounts.entries.map((entry) {
      return {
        'group': entry.key,
        'cnt': entry.value,
      };
    }).toList()
      ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int));

    // 只保留前5个分组
    final topGroupsLimited = topGroups.take(5).toList();

    // 计算最大连续打卡天数（取所有项目中的最大值）
    final maxStreak = checkinItems.fold<int>(
      0,
          (max, item) {
        final streak = item.getConsecutiveDays();
        return streak > max ? streak : max;
      },
    );

    return FieldUtils.buildSummaryResponse({
      'total': checkinItems.length,
      'done': todayRecords,
      'streak': maxStreak,
      if (topGroupsLimited.isNotEmpty) 'topGroups': topGroupsLimited,
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "total": 10, "done": 5 },
  ///   "recs": [
  ///     {
  ///       "id": "item-id",
  ///       "name": "早起",
  ///       "group": "健康习惯",
  ///       "done": "2025-01-15T06:30:00",
  ///       "start": "2025-01-15T06:00:00",
  ///       "end": "2025-01-15T06:30:00"
  ///     }
  ///   ]
  /// }
  Map<String, dynamic> _buildCompact(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0, 'done': 0},
        [],
      );
    }

    // 获取所有打卡项目
    final checkinItems = CheckinPlugin.instance.checkinItems;

    // 计算今日已打卡数量
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final todayRecords = records.where((record) {
      final checkinTime = record['checkinTime'] as DateTime;
      return checkinTime.isAfter(todayStart) && checkinTime.isBefore(todayEnd);
    }).length;

    // 简化记录（移除 note 字段）
    final compactRecords = records.map((record) {
      final startTime = record['startTime'] as DateTime;
      final endTime = record['endTime'] as DateTime;
      final checkinTime = record['checkinTime'] as DateTime;

      final compactRecord = {
        'name': record['itemName'],
        'done': FieldUtils.formatDateTime(checkinTime),
      };

      // 只添加非空字段
      if (record['group'] != null) {
        compactRecord['group'] = record['group'];
      }

      // 只有当时间段至少1分钟时才添加start/end
      final duration = endTime.difference(startTime).inMinutes;
      if (duration >= 1) {
        compactRecord['start'] = FieldUtils.formatDateTime(startTime);
        compactRecord['end'] = FieldUtils.formatDateTime(endTime);
      }

      return compactRecord;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': checkinItems.length,
        'done': todayRecords,
      },
      compactRecords,
    );
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: 原始数据格式
  Map<String, dynamic> _buildFull(List<Map<String, dynamic>> records) {
    final fullRecords = records.map((record) {
      final startTime = record['startTime'] as DateTime;
      final endTime = record['endTime'] as DateTime;
      final checkinTime = record['checkinTime'] as DateTime;

      final fullRecord = {
        'name': record['itemName'],
        'group': record['group'],
        'done': FieldUtils.formatDateTime(checkinTime),
        'start': FieldUtils.formatDateTime(startTime),
        'end': FieldUtils.formatDateTime(endTime),
        'note': record['note'],
      };

      // 移除空字段
      return Map<String, dynamic>.fromEntries(
        fullRecord.entries.where((entry) => entry.value != null),
      );
    }).toList();

    return FieldUtils.buildFullResponse(fullRecords);
  }

  void initialize() {
    // 初始化时的其他操作（如果需要）
  }

  void dispose() {
    // 清理资源（如果需要）
  }
}
