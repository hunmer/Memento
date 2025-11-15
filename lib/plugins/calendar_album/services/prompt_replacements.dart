import 'package:flutter/material.dart';
import '../calendar_album_plugin.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';
import '../models/calendar_entry.dart';

/// CalendarAlbum插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class CalendarAlbumPromptReplacements {
  final CalendarAlbumPlugin _plugin;

  CalendarAlbumPromptReplacements(this._plugin);

  /// 获取日记列表并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  /// - tags: 标签筛选 (可选, 逗号分隔, AND逻辑)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, wordCnt, avgWords, topTags } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无content)
  /// - full: 完整数据 (包含所有字段)
  Future<String> getEntries(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final dateRange = _parseDateRange(params);
      final tags = _parseTags(params);

      // 2. 获取日期范围内的日记
      final entries = _getEntriesInRange(
        dateRange['startDate']!,
        dateRange['endDate']!,
        tags: tags,
      );

      // 3. 根据模式转换数据
      final result = _convertByMode(entries, mode);

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取日记列表失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取日记列表时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取照片列表并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, dateRange } }
  /// - compact: 简化记录 { sum: {...}, recs: [{date, url, entryId}] } (无entryTitle)
  /// - full: 完整数据 (包含entryTitle等所有字段)
  Future<String> getPhotos(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final dateRange = _parseDateRange(params);

      // 2. 获取照片数据
      final photos = _getPhotosInRange(
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      // 3. 根据模式转换数据
      final result = _convertPhotosMode(photos, mode, dateRange);

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取照片列表失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取照片列表时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取标签统计并格式化为文本
  ///
  /// 参数:
  /// - mode: 数据模式 (summary/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 简化统计 { sum: { total, top5: [{tag, cnt}] } }
  /// - full: 完整统计 { tagStats: [{tag, cnt, entryCnt}] }
  Future<String> getTagStats(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);

      // 2. 获取标签统计
      final tagStats = _calculateTagStats();

      // 3. 根据模式转换数据
      final result = _convertTagStatsMode(tagStats, mode);

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取标签统计失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取标签统计时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取心情和天气统计并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  /// - mode: 数据模式 (summary/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 简化统计 { sum: { moodCnt, weatherCnt } }
  /// - full: 完整统计 { moods: [{mood, cnt}], weathers: [{weather, cnt}] }
  Future<String> getMoodWeatherStats(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final dateRange = _parseDateRange(params);

      // 2. 获取心情和天气统计
      final stats = _calculateMoodWeatherStats(
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      // 3. 根据模式转换数据
      final result = _convertMoodWeatherStatsMode(stats, mode);

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取心情和天气统计失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取心情和天气统计时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取位置统计并格式化为文本
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  /// - mode: 数据模式 (summary/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 简化统计 { sum: { total, top5: [{loc, cnt}] } }
  /// - full: 完整统计 { locations: [{loc, cnt}] }
  Future<String> getLocationStats(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final dateRange = _parseDateRange(params);

      // 2. 获取位置统计
      final locationStats = _calculateLocationStats(
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      // 3. 根据模式转换数据
      final result = _convertLocationStatsMode(locationStats, mode);

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('获取位置统计失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取位置统计时出错',
        'details': e.toString(),
      });
    }
  }

  /// 获取统计概览
  ///
  /// 参数:
  /// - startDate: 开始日期 (可选, YYYY-MM-DD 格式)
  /// - endDate: 结束日期 (可选, YYYY-MM-DD 格式)
  ///
  /// 返回格式 (固定为summary模式):
  /// {
  ///   "total": 100,
  ///   "wordCnt": 50000,
  ///   "photoCnt": 200,
  ///   "tagCnt": 15,
  ///   "avgWords": 500
  /// }
  Future<String> getStatistics(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final dateRange = _parseDateRange(params);

      // 2. 获取统计数据
      final entries = _getEntriesInRange(
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      // 3. 计算统计信息
      final stats = _calculateStatistics(entries);

      // 4. 返回 JSON 字符串
      return FieldUtils.toJsonString(stats);
    } catch (e) {
      debugPrint('获取统计概览失败: $e');
      return FieldUtils.toJsonString({
        'error': '获取统计概览时出错',
        'details': e.toString(),
      });
    }
  }

  // ==================== 私有辅助方法 ====================

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

    // 如果没有提供日期，使用全部数据
    if (startDate == null && endDate == null) {
      // 使用一个很早的日期作为开始，当前日期作为结束
      startDate = DateTime(2000, 1, 1);
      endDate = DateTime.now();
    } else if (startDate != null && endDate == null) {
      // 如果只提供了开始日期，结束日期设为开始日期的当天结束
      endDate = DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
    } else if (startDate == null && endDate != null) {
      // 如果只提供了结束日期，开始日期设为一个很早的日期
      startDate = DateTime(2000, 1, 1);
    }

    return {
      'startDate': startDate!,
      'endDate': endDate!,
    };
  }

  /// 解析标签参数
  List<String> _parseTags(Map<String, dynamic> params) {
    final String? tagsStr = params['tags'] as String?;
    if (tagsStr == null || tagsStr.isEmpty) {
      return [];
    }
    return tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
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

  /// 获取指定日期范围内的所有日记
  List<CalendarEntry> _getEntriesInRange(
    DateTime start,
    DateTime end, {
    List<String>? tags,
  }) {
    final List<CalendarEntry> result = [];

    _plugin.calendarController.entries.forEach((date, entries) {
      if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
          (date.isBefore(end) || date.isAtSameMomentAs(end))) {
        for (var entry in entries) {
          // 如果指定了标签筛选，应用AND逻辑
          if (tags != null && tags.isNotEmpty) {
            if (tags.every((tag) => entry.tags.contains(tag))) {
              result.add(entry);
            }
          } else {
            result.add(entry);
          }
        }
      }
    });

    // 按创建时间降序排序
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// 获取指定日期范围内的所有照片
  List<Map<String, dynamic>> _getPhotosInRange(DateTime start, DateTime end) {
    final List<Map<String, dynamic>> photos = [];

    _plugin.calendarController.entries.forEach((date, entries) {
      if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
          (date.isBefore(end) || date.isAtSameMomentAs(end))) {
        for (var entry in entries) {
          final allImages = <String>[...entry.imageUrls, ...entry.extractImagesFromMarkdown()];
          for (var imageUrl in allImages) {
            photos.add({
              'date': date.toIso8601String(),
              'url': imageUrl,
              'entryId': entry.id,
              'entryTitle': entry.title,
            });
          }
        }
      }
    });

    return photos;
  }

  /// 计算标签统计
  List<Map<String, dynamic>> _calculateTagStats() {
    final Map<String, int> tagCounts = {};

    _plugin.calendarController.entries.forEach((date, entries) {
      for (var entry in entries) {
        for (var tag in entry.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    });

    // 转换为列表并按次数降序排序
    final stats = tagCounts.entries.map((entry) {
      return {
        'tag': entry.key,
        'cnt': entry.value,
      };
    }).toList()
      ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int));

    return stats;
  }

  /// 计算心情和天气统计
  Map<String, dynamic> _calculateMoodWeatherStats(DateTime start, DateTime end) {
    final Map<String, int> moodCounts = {};
    final Map<String, int> weatherCounts = {};

    _plugin.calendarController.entries.forEach((date, entries) {
      if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
          (date.isBefore(end) || date.isAtSameMomentAs(end))) {
        for (var entry in entries) {
          if (entry.mood != null && entry.mood!.isNotEmpty) {
            moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
          }
          if (entry.weather != null && entry.weather!.isNotEmpty) {
            weatherCounts[entry.weather!] = (weatherCounts[entry.weather!] ?? 0) + 1;
          }
        }
      }
    });

    return {
      'moods': moodCounts.entries.map((e) => {'mood': e.key, 'cnt': e.value}).toList()
        ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int)),
      'weathers': weatherCounts.entries.map((e) => {'weather': e.key, 'cnt': e.value}).toList()
        ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int)),
    };
  }

  /// 计算位置统计
  List<Map<String, dynamic>> _calculateLocationStats(DateTime start, DateTime end) {
    final Map<String, int> locationCounts = {};

    _plugin.calendarController.entries.forEach((date, entries) {
      if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
          (date.isBefore(end) || date.isAtSameMomentAs(end))) {
        for (var entry in entries) {
          if (entry.location != null && entry.location!.isNotEmpty) {
            locationCounts[entry.location!] = (locationCounts[entry.location!] ?? 0) + 1;
          }
        }
      }
    });

    // 转换为列表并按次数降序排序
    final stats = locationCounts.entries.map((entry) {
      return {
        'loc': entry.key,
        'cnt': entry.value,
      };
    }).toList()
      ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int));

    return stats;
  }

  /// 计算统计信息
  Map<String, dynamic> _calculateStatistics(List<CalendarEntry> entries) {
    int totalWords = 0;
    int totalPhotos = 0;
    final Set<String> allTags = {};

    for (var entry in entries) {
      totalWords += entry.wordCount;
      totalPhotos += entry.imageUrls.length;
      totalPhotos += entry.extractImagesFromMarkdown().length;
      allTags.addAll(entry.tags);
    }

    return {
      'total': entries.length,
      'wordCnt': totalWords,
      'photoCnt': totalPhotos,
      'tagCnt': allTags.length,
      'avgWords': entries.isNotEmpty ? (totalWords / entries.length).round() : 0,
    };
  }

  /// 根据模式转换日记数据
  Map<String, dynamic> _convertByMode(
    List<CalendarEntry> entries,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildEntriesSummary(entries);
      case AnalysisMode.compact:
        return _buildEntriesCompact(entries);
      case AnalysisMode.full:
        return _buildEntriesFull(entries);
    }
  }

  /// 构建日记摘要数据 (summary模式)
  Map<String, dynamic> _buildEntriesSummary(List<CalendarEntry> entries) {
    if (entries.isEmpty) {
      return FieldUtils.buildSummaryResponse({
        'total': 0,
        'wordCnt': 0,
        'avgWords': 0,
      });
    }

    // 计算总字数
    int totalWords = 0;
    final Map<String, int> tagCounts = {};

    for (var entry in entries) {
      totalWords += entry.wordCount;
      for (var tag in entry.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // 生成标签排行（按次数降序）
    final topTags = tagCounts.entries.map((entry) {
      return {
        'tag': entry.key,
        'cnt': entry.value,
      };
    }).toList()
      ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int));

    // 只保留前5个标签
    final topTagsLimited = topTags.take(5).toList();

    return FieldUtils.buildSummaryResponse({
      'total': entries.length,
      'wordCnt': totalWords,
      'avgWords': (totalWords / entries.length).round(),
      if (topTagsLimited.isNotEmpty) 'topTags': topTagsLimited,
    });
  }

  /// 构建日记紧凑数据 (compact模式)
  Map<String, dynamic> _buildEntriesCompact(List<CalendarEntry> entries) {
    if (entries.isEmpty) {
      return FieldUtils.buildCompactResponse(
        {'total': 0, 'wordCnt': 0},
        [],
      );
    }

    // 计算总字数
    int totalWords = 0;
    for (var entry in entries) {
      totalWords += entry.wordCount;
    }

    // 简化记录（移除 content 字段）
    final compactRecords = entries.map((entry) {
      final record = {
        'id': entry.id,
        'title': entry.title,
        'created': FieldUtils.formatDateTime(entry.createdAt),
        'updated': FieldUtils.formatDateTime(entry.updatedAt),
        'wordCnt': entry.wordCount,
      };

      // 只添加非空字段
      if (entry.tags.isNotEmpty) {
        record['tags'] = entry.tags;
      }
      if (entry.location != null && entry.location!.isNotEmpty) {
        record['loc'] = entry.location!;
      }
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        record['mood'] = entry.mood!;
      }
      if (entry.weather != null && entry.weather!.isNotEmpty) {
        record['weather'] = entry.weather!;
      }
      if (entry.imageUrls.isNotEmpty) {
        record['imgCnt'] = entry.imageUrls.length + entry.extractImagesFromMarkdown().length;
      }

      return record;
    }).toList();

    return FieldUtils.buildCompactResponse(
      {
        'total': entries.length,
        'wordCnt': totalWords,
      },
      compactRecords,
    );
  }

  /// 构建日记完整数据 (full模式)
  Map<String, dynamic> _buildEntriesFull(List<CalendarEntry> entries) {
    return FieldUtils.buildFullResponse(entries.map((e) => e.toJson()).toList());
  }

  /// 根据模式转换照片数据
  Map<String, dynamic> _convertPhotosMode(
    List<Map<String, dynamic>> photos,
    AnalysisMode mode,
    Map<String, DateTime> dateRange,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildPhotosSummary(photos, dateRange);
      case AnalysisMode.compact:
        return _buildPhotosCompact(photos);
      case AnalysisMode.full:
        return _buildPhotosFull(photos);
    }
  }

  /// 构建照片摘要数据 (summary模式)
  Map<String, dynamic> _buildPhotosSummary(
    List<Map<String, dynamic>> photos,
    Map<String, DateTime> dateRange,
  ) {
    return FieldUtils.buildSummaryResponse({
      'total': photos.length,
      'dateRange': {
        'start': FieldUtils.formatDateTime(dateRange['startDate']),
        'end': FieldUtils.formatDateTime(dateRange['endDate']),
      },
    });
  }

  /// 构建照片紧凑数据 (compact模式)
  Map<String, dynamic> _buildPhotosCompact(List<Map<String, dynamic>> photos) {
    // 移除 entryTitle 字段
    final compactRecords = photos.map((photo) {
      return {
        'date': photo['date'],
        'url': photo['url'],
        'entryId': photo['entryId'],
      };
    }).toList();

    return FieldUtils.buildCompactResponse(
      {'total': photos.length},
      compactRecords,
    );
  }

  /// 构建照片完整数据 (full模式)
  Map<String, dynamic> _buildPhotosFull(List<Map<String, dynamic>> photos) {
    return FieldUtils.buildFullResponse(photos);
  }

  /// 根据模式转换标签统计数据
  Map<String, dynamic> _convertTagStatsMode(
    List<Map<String, dynamic>> tagStats,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildTagStatsSummary(tagStats);
      case AnalysisMode.compact:
      case AnalysisMode.full:
        return _buildTagStatsFull(tagStats);
    }
  }

  /// 构建标签统计摘要数据 (summary模式)
  Map<String, dynamic> _buildTagStatsSummary(List<Map<String, dynamic>> tagStats) {
    return FieldUtils.buildSummaryResponse({
      'total': tagStats.length,
      'top5': tagStats.take(5).toList(),
    });
  }

  /// 构建标签统计完整数据 (full模式)
  Map<String, dynamic> _buildTagStatsFull(List<Map<String, dynamic>> tagStats) {
    return {
      'tagStats': tagStats,
    };
  }

  /// 根据模式转换心情天气统计数据
  Map<String, dynamic> _convertMoodWeatherStatsMode(
    Map<String, dynamic> stats,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildMoodWeatherStatsSummary(stats);
      case AnalysisMode.compact:
      case AnalysisMode.full:
        return _buildMoodWeatherStatsFull(stats);
    }
  }

  /// 构建心情天气统计摘要数据 (summary模式)
  Map<String, dynamic> _buildMoodWeatherStatsSummary(Map<String, dynamic> stats) {
    final moods = stats['moods'] as List;
    final weathers = stats['weathers'] as List;

    return FieldUtils.buildSummaryResponse({
      'moodCnt': moods.length,
      'weatherCnt': weathers.length,
    });
  }

  /// 构建心情天气统计完整数据 (full模式)
  Map<String, dynamic> _buildMoodWeatherStatsFull(Map<String, dynamic> stats) {
    return stats;
  }

  /// 根据模式转换位置统计数据
  Map<String, dynamic> _convertLocationStatsMode(
    List<Map<String, dynamic>> locationStats,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildLocationStatsSummary(locationStats);
      case AnalysisMode.compact:
      case AnalysisMode.full:
        return _buildLocationStatsFull(locationStats);
    }
  }

  /// 构建位置统计摘要数据 (summary模式)
  Map<String, dynamic> _buildLocationStatsSummary(List<Map<String, dynamic>> locationStats) {
    return FieldUtils.buildSummaryResponse({
      'total': locationStats.length,
      'top5': locationStats.take(5).toList(),
    });
  }

  /// 构建位置统计完整数据 (full模式)
  Map<String, dynamic> _buildLocationStatsFull(List<Map<String, dynamic>> locationStats) {
    return {
      'locations': locationStats,
    };
  }

  /// 释放资源
  void dispose() {}
}
