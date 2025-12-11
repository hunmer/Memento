/// Diary 插件 - Repository 接口定义
///
/// 定义日记条目的数据访问抽象接口

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 日记条目 DTO
class DiaryEntryDto {
  final String date; // 日期字符串，格式: YYYY-MM-DD
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? mood;

  const DiaryEntryDto({
    required this.date,
    this.title = '',
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.mood,
  });

  factory DiaryEntryDto.fromJson(Map<String, dynamic> json) {
    return DiaryEntryDto(
      date: json['date'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      mood: json['mood'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'mood': mood,
    };
  }

  DiaryEntryDto copyWith({
    String? date,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mood,
  }) {
    return DiaryEntryDto(
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mood: mood ?? this.mood,
    );
  }
}

/// 日记统计信息 DTO
class DiaryStatsDto {
  final int totalEntries; // 日记总数
  final int totalWords; // 总字数
  final int averageWords; // 平均字数

  const DiaryStatsDto({
    required this.totalEntries,
    required this.totalWords,
    required this.averageWords,
  });

  factory DiaryStatsDto.fromJson(Map<String, dynamic> json) {
    return DiaryStatsDto(
      totalEntries: json['totalEntries'] as int,
      totalWords: json['totalWords'] as int,
      averageWords: json['averageWords'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEntries': totalEntries,
      'totalWords': totalWords,
      'averageWords': averageWords,
    };
  }
}

// ============ Query Objects ============

/// 日记查询参数
class DiaryQuery {
  final String? startDate; // 开始日期 (YYYY-MM-DD)
  final String? endDate; // 结束日期 (YYYY-MM-DD)
  final String? keyword; // 搜索关键词
  final String? mood; // 心情过滤
  final PaginationParams? pagination;

  const DiaryQuery({
    this.startDate,
    this.endDate,
    this.keyword,
    this.mood,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Diary Repository 接口
///
/// 客户端和服务端都实现此接口，但使用不同的数据源
abstract class IDiaryRepository {
  /// 获取日记列表（支持日期范围过滤）
  Future<Result<List<DiaryEntryDto>>> getEntries({
    String? startDate,
    String? endDate,
    PaginationParams? pagination,
  });

  /// 根据日期获取日记
  Future<Result<DiaryEntryDto?>> getEntryByDate(String date);

  /// 创建日记
  Future<Result<DiaryEntryDto>> createEntry(DiaryEntryDto entry);

  /// 更新日记
  Future<Result<DiaryEntryDto>> updateEntry(String date, DiaryEntryDto entry);

  /// 删除日记
  Future<Result<bool>> deleteEntry(String date);

  /// 搜索日记
  Future<Result<List<DiaryEntryDto>>> searchEntries(DiaryQuery query);

  /// 获取统计信息
  Future<Result<DiaryStatsDto>> getStats();

  /// 获取今日字数
  Future<Result<int>> getTodayWordCount();

  /// 获取本月字数
  Future<Result<int>> getMonthWordCount();

  /// 获取本月进度（已完成天数/总天数）
  Future<Result<Map<String, int>>> getMonthProgress();
}
