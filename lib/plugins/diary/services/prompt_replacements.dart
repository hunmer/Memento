import 'package:flutter/material.dart';
import '../diary_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Diary插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class DiaryPromptReplacements {
  final DiaryPlugin _plugin;

  DiaryPromptReplacements(this._plugin);

  /// 获取日记数据并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式, 默认今天)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式, 默认今天)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  /// - fields: 自定义返回字段列表 (可选, 优先级高于 mode)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { cnt: 7, totalWords: 15000 }, topMoods: [...] }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (content截断至100字为desc)
  /// - full: 完整数据 (包含所有字段)
  /// - fields: 自定义字段 { recs: [...] } (仅包含指定字段)
  Future<String> getDiaries(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final customFields = params['fields'] as List<dynamic>?;
      final dateRange = _parseDateRange(params);

      // 2. 调用 jsAPI 获取日期范围内的所有日记数据
      final allDiaries = await _getDiariesInRange(
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      // 3. 应用字段过滤
      Map<String, dynamic> result;

      if (customFields != null && customFields.isNotEmpty) {
        // 优先使用 fields 参数（白名单模式）
        final fieldList = customFields.map((e) => e.toString()).toList();
        final filteredRecords = FieldUtils.simplifyRecords(
          allDiaries,
          keepFields: fieldList,
        );
        result = FieldUtils.buildCompactResponse(
          {'total': filteredRecords.length},
          filteredRecords,
        );
      } else {
        // 使用 mode 参数
        result = _convertByMode(allDiaries, mode);
      }

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取日记数据失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取日记数据时出错',
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

  /// 获取指定日期范围内的所有日记
  Future<List<Map<String, dynamic>>> _getDiariesInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // 直接调用插件的 jsAPI 方法
      final jsAPI = _plugin.defineJSAPI();
      final getDiariesFunc = jsAPI['getDiaries'];

      if (getDiariesFunc == null) {
        debugPrint('getDiaries jsAPI 未定义');
        return [];
      }

      // 调用 jsAPI 获取日记列表
      final String jsonResult = await getDiariesFunc(
        start.toIso8601String().split('T')[0],
        end.toIso8601String().split('T')[0],
      );

      // 解析 JSON 结果
      final Map<String, dynamic> result = FieldUtils.fromJsonString(jsonResult);

      if (result.containsKey('error')) {
        debugPrint('获取日记失败: ${result['error']}');
        return [];
      }

      final List<dynamic> diaries = result['diaries'] ?? [];
      return diaries.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('调用 jsAPI 失败: $e');
      return [];
    }
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
    List<Map<String, dynamic>> diaries,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(diaries);
      case AnalysisMode.compact:
        return _buildCompact(diaries);
      case AnalysisMode.full:
        return _buildFull(diaries);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": {
  ///     "cnt": 7,
  ///     "totalWords": 15000,
  ///     "avgWords": 2142
  ///   },
  ///   "topMoods": [
  ///     {"mood": "😊", "cnt": 3},
  ///     {"mood": "😢", "cnt": 2}
  ///   ]
  /// }
  Map<String, dynamic> _buildSummary(List<Map<String, dynamic>> diaries) {
    if (diaries.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'cnt': 0,
        'totalWords': 0,
        'avgWords': 0,
      });
    }

    // 计算总字数
    int totalWords = 0;
    final Map<String, int> moodCounts = {}; // 心情统计

    for (final diary in diaries) {
      final int wordCount = (diary['wordCount'] as int?) ??
                           (diary['content'] as String?)?.length ??
                           0;
      totalWords += wordCount;

      // 统计心情
      final mood = diary['mood'] as String?;
      if (mood != null && mood.isNotEmpty) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
    }

    // 计算平均字数
    final avgWords = (totalWords / diaries.length).round();

    // 生成心情排行（按次数降序）
    final topMoods = moodCounts.entries.map((entry) {
      return {
        'mood': entry.key,
        'cnt': entry.value,
      };
    }).toList()
      ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int));

    // 只保留前5个心情
    final topMoodsLimited = topMoods.take(5).toList();

    return FieldUtils.buildSummaryResponse({
      'cnt': diaries.length,
      'totalWords': totalWords,
      'avgWords': avgWords,
      if (topMoodsLimited.isNotEmpty) 'topMoods': topMoodsLimited,
    });
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "sum": { "cnt": 7, "totalWords": 15000 },
  ///   "recs": [
  ///     {
  ///       "date": "2025-01-15",
  ///       "title": "美好的一天",
  ///       "desc": "今天天气很好...",  // content截断至100字
  ///       "mood": "😊"
  ///     }
  ///   ]
  /// }
  Map<String, dynamic> _buildCompact(List<Map<String, dynamic>> diaries) {
    if (diaries.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'cnt': 0, 'totalWords': 0},
        [],
      );
    }

    // 计算总字数
    int totalWords = 0;
    for (final diary in diaries) {
      final int wordCount = (diary['wordCount'] as int?) ??
                           (diary['content'] as String?)?.length ??
                           0;
      totalWords += wordCount;
    }

    // 简化记录（截断 content 字段至100字并重命名为 desc）
    final compactRecords = diaries.map((diary) {
      final record = <String, dynamic>{
        'date': diary['date'],
        'title': diary['title'],
      };

      // 截断 content 为 desc (最多100字)
      final content = diary['content'] as String?;
      if (content != null && content.isNotEmpty) {
        record['desc'] = FieldUtils.truncateText(content, 100);
      }

      // 只添加非空字段
      if (diary['mood'] != null && (diary['mood'] as String).isNotEmpty) {
        record['mood'] = diary['mood'];
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'cnt': diaries.length,
        'totalWords': totalWords,
      },
      compactRecords,
    );
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: jsAPI 的原始数据
  Map<String, dynamic> _buildFull(List<Map<String, dynamic>> diaries) {
    return FieldUtils.buildFullResponse(diaries);
  }

  /// 释放资源
  void dispose() {}
}
