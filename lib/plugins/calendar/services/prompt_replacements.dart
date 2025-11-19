import 'package:flutter/material.dart';
import '../calendar_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Calendar插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class CalendarPromptReplacements {
  final CalendarPlugin _plugin;

  CalendarPromptReplacements(this._plugin);

  /// 获取事件数据并格式化为文本
  ///
  /// 参数:
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  /// - source: 事件来源筛选 (可选, "default" 或 "todo")
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, today, upcoming } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无description)
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getEvents(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final dateRange = params['startDate'] != null || params['endDate'] != null
          ? _parseDateRange(params)
          : null;
      final String? source = params['source'] as String?;

      // 2. 获取所有事件数据 (包括 Todo 任务事件)
      final events = _plugin.controller.getAllEvents();

      // 3. 应用筛选
      var filteredEvents = events;

      // 日期范围筛选
      if (dateRange != null) {
        filteredEvents = filteredEvents.where((event) {
          return event.startTime.isAfter(dateRange['startDate']!.subtract(const Duration(seconds: 1))) &&
                 event.startTime.isBefore(dateRange['endDate']!.add(const Duration(days: 1)));
        }).toList();
      }

      // 来源筛选
      if (source != null && source.isNotEmpty) {
        filteredEvents = filteredEvents.where((e) => e.source == source).toList();
      }

      // 4. 应用字段过滤
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          filteredEvents.map((e) => e.toJson()).toList(),
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertByMode(filteredEvents, mode);
      }

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取事件数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取事件数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取今日事件
  ///
  /// 参数:
  /// - mode: 数据模式 (summary/compact/full, 默认compact)
  ///
  /// 返回格式: 与 getEvents 相同
  Future<String> getTodayEvents(Map<String, dynamic> params) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // 设置日期范围为今天
    params['startDate'] = today.toIso8601String();
    params['endDate'] = tomorrow.subtract(const Duration(seconds: 1)).toIso8601String();

    // 如果未指定模式,默认使用 compact
    if (params['mode'] == null) {
      params['mode'] = 'compact';
    }

    return getEvents(params);
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
  Map<String, dynamic> _convertByMode(
    List events,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(events);
      case AnalysisMode.compact:
        return _buildCompact(events);
      case AnalysisMode.full:
        return _buildFull(events);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 50,
  ///     "today": 3,
  ///     "upcoming": 8
  ///   }
  /// }
  Map<String, dynamic> _buildSummary(List events) {
    if (events.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'today': 0,
        'upcoming': 0,
      });
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final sevenDaysLater = now.add(const Duration(days: 7));

    // 统计今日事件
    final todayCount = events.where((event) {
      return event.startTime.isAfter(today.subtract(const Duration(seconds: 1))) &&
             event.startTime.isBefore(tomorrow);
    }).length;

    // 统计未来7天事件
    final upcomingCount = events.where((event) {
      return event.startTime.isAfter(now) &&
             event.startTime.isBefore(sevenDaysLater);
    }).length;

    return FieldUtils.buildSummaryResponse({
      'total': events.length,
      'today': todayCount,
      'upcoming': upcomingCount,
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "total": 50, "today": 3 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "title": "项目会议",
  ///       "start": "2025-01-15T09:00:00",
  ///       "end": "2025-01-15T10:00:00",
  ///       "type": "default",
  ///       "source": "default"
  ///     }
  ///   ]
  /// }
  Map<String, dynamic> _buildCompact(List events) {
    if (events.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0, 'today': 0},
        [],
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // 统计今日事件
    final todayCount = events.where((event) {
      return event.startTime.isAfter(today.subtract(const Duration(seconds: 1))) &&
             event.startTime.isBefore(tomorrow);
    }).length;

    // 简化记录（移除 description 字段）
    final compactRecords = events.map((event) {
      final record = {
        'id': event.id,
        'title': event.title,
        'start': FieldUtils.formatDateTime(event.startTime),
      };

      // 只添加非空字段
      if (event.endTime != null) {
        record['end'] = FieldUtils.formatDateTime(event.endTime!);
      }

      record['type'] = event.source;
      record['source'] = event.source;

      // 添加提醒信息
      if (event.reminderMinutes != null && event.reminderMinutes! > 0) {
        record['reminder'] = '${event.reminderMinutes}分钟';
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': events.length,
        'today': todayCount,
      },
      compactRecords,
    );
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: 包含所有事件的完整数据
  Map<String, dynamic> _buildFull(List events) {
    final fullRecords = events.map((event) {
      final eventMap = event.toJson();

      // 转换时间戳为可读格式
      eventMap['startTime'] = FieldUtils.formatDateTime(event.startTime);
      if (event.endTime != null) {
        eventMap['endTime'] = FieldUtils.formatDateTime(event.endTime!);
      }
      if (event.completedTime != null) {
        eventMap['completedTime'] = FieldUtils.formatDateTime(event.completedTime!);
      }

      return eventMap;
    }).toList();

    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 释放资源
  void dispose() {}
}
