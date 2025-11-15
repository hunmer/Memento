import 'package:flutter/material.dart';
import '../models/memorial_day.dart';
import '../controllers/day_controller.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Day插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class DayPromptReplacements {
  final DayController _dayController = DayController();

  /// 初始化并注册所有prompt替换方法
  void initialize() {
    // 确保DayController已初始化
    _dayController.initialize().catchError((e) {
      debugPrint('初始化DayController失败: $e');
    });
  }

  /// 获取纪念日数据并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, upcoming, past } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] }
  /// - full: 完整数据 (包含所有字段)
  Future<String> getDays(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final dateRange = _parseDateRange(params);

      // 2. 获取所有纪念日
      final allDays = _dayController.memorialDays;

      // 3. 根据日期范围过滤
      final filteredDays = _filterDaysByRange(allDays, dateRange);

      // 4. 根据模式转换数据
      final result = _convertByMode(filteredDays, mode);

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取纪念日数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取纪念日数据时出错',
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
      try {
        startDate = _parseDate(startDateStr);
      } catch (e) {
        debugPrint('解析开始日期失败: $e');
      }
    }

    if (endDateStr != null) {
      try {
        endDate = _parseDate(endDateStr);
      } catch (e) {
        debugPrint('解析结束日期失败: $e');
      }
    }

    if (startDate == null && endDate == null) {
      return null; // 不过滤日期
    }

    return {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
  }

  /// 根据日期范围过滤纪念日
  List<MemorialDay> _filterDaysByRange(
    List<MemorialDay> days,
    Map<String, DateTime>? dateRange,
  ) {
    if (dateRange == null || dateRange.isEmpty) {
      return days; // 不过滤
    }

    final startDate = dateRange['startDate'];
    final endDate = dateRange['endDate'];

    return days.where((day) {
      final targetDate = day.targetDate;

      if (startDate != null && targetDate.isBefore(startDate)) {
        return false;
      }

      if (endDate != null && targetDate.isAfter(endDate)) {
        return false;
      }

      return true;
    }).toList();
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
    List<MemorialDay> days,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(days);
      case AnalysisMode.compact:
        return _buildCompact(days);
      case AnalysisMode.full:
        return _buildFull(days);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "total": 10,
  ///     "upcoming": 3,
  ///     "past": 2
  ///   }
  /// }
  Map<String, dynamic> _buildSummary(List<MemorialDay> days) {
    if (days.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'upcoming': 0,
        'past': 0,
      });
    }

    // 统计即将到来的（7天内）和已过期的纪念日
    int upcomingCount = 0;
    int pastCount = 0;

    for (final day in days) {
      final daysRemaining = day.daysRemaining;
      if (daysRemaining >= 0 && daysRemaining <= 7) {
        upcomingCount++;
      } else if (daysRemaining < 0) {
        pastCount++;
      }
    }

    return FieldUtils.buildSummaryResponse({
      'total': days.length,
      'upcoming': upcomingCount,
      'past': pastCount,
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "total": 10, "upcoming": 3 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "title": "生日",
  ///       "date": "2025-06-15",
  ///       "daysRemaining": 120
  ///     }
  ///   ]
  /// }
  Map<String, dynamic> _buildCompact(List<MemorialDay> days) {
    if (days.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0, 'upcoming': 0},
        [],
      );
    }

    // 统计即将到来的纪念日数量
    final upcomingCount = days.where((day) {
      final daysRemaining = day.daysRemaining;
      return daysRemaining >= 0 && daysRemaining <= 7;
    }).length;

    // 简化记录（移除notes、背景等字段）
    final compactRecords = days.map((day) {
      return {
        'id': day.id,
        'title': day.title,
        'date': day.formattedTargetDate,
        'daysRemaining': day.daysRemaining,
      };
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': days.length,
        'upcoming': upcomingCount,
      },
      compactRecords,
    );
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: 包含所有字段的完整数据
  Map<String, dynamic> _buildFull(List<MemorialDay> days) {
    final fullRecords = days.map((day) {
      final record = {
        'id': day.id,
        'title': day.title,
        'date': day.formattedTargetDate,
        'targetDate': FieldUtils.formatDateTime(day.targetDate),
        'creationDate': FieldUtils.formatDateTime(day.creationDate),
        'daysRemaining': day.daysRemaining,
        'isExpired': day.isExpired,
        'isToday': day.isToday,
      };

      // 只有当备注非空时才添加notes字段
      if (day.notes.isNotEmpty) {
        record['notes'] = day.notes;
      }

      // 添加背景颜色（如果存在）
      if (day.backgroundColor != null) {
        record['backgroundColor'] = day.backgroundColor.toARGB32();
      }

      // 添加背景图片URL（如果存在）
      if (day.backgroundImageUrl != null && day.backgroundImageUrl!.isNotEmpty) {
        record['backgroundImageUrl'] = day.backgroundImageUrl!;
      }

      return record;
    }).toList();

    return FieldUtils.buildFullResponse(fullRecords);
  }

  /// 释放资源
  void dispose() {
    // 清理资源（如果需要）
  }
}
