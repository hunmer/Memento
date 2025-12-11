/// Activity 插件 - Repository 接口定义
///
/// 定义活动记录的数据访问抽象接口
library;

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 活动记录 DTO
class ActivityDto {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final List<String> tags;
  final String? description;
  final int? mood;
  final Map<String, dynamic>? metadata;

  const ActivityDto({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.tags = const [],
    this.description,
    this.mood,
    this.metadata,
  });

  factory ActivityDto.fromJson(Map<String, dynamic> json) {
    return ActivityDto(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      title: json['title'] as String,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      description: json['description'] as String?,
      mood: json['mood'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'title': title,
      'tags': tags,
      'description': description,
      'mood': mood,
      'metadata': metadata,
    };
  }

  ActivityDto copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? title,
    List<String>? tags,
    String? description,
    int? mood,
    Map<String, dynamic>? metadata,
  }) {
    return ActivityDto(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      mood: mood ?? this.mood,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 获取活动时长（分钟）
  int get durationMinutes => endTime.difference(startTime).inMinutes;
}

/// 统计数据 DTO
class ActivityStatsDto {
  final String date;
  final int activityCount;
  final int durationMinutes;
  final int durationHours;
  final int remainingMinutes;

  const ActivityStatsDto({
    required this.date,
    required this.activityCount,
    required this.durationMinutes,
    required this.durationHours,
    required this.remainingMinutes,
  });

  factory ActivityStatsDto.fromJson(Map<String, dynamic> json) {
    return ActivityStatsDto(
      date: json['date'] as String,
      activityCount: json['activityCount'] as int,
      durationMinutes: json['durationMinutes'] as int,
      durationHours: json['durationHours'] as int,
      remainingMinutes: json['remainingMinutes'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'activityCount': activityCount,
      'durationMinutes': durationMinutes,
      'durationHours': durationHours,
      'remainingMinutes': remainingMinutes,
    };
  }
}

/// 日期范围统计 DTO
class ActivityRangeStatsDto {
  final String startDate;
  final String endDate;
  final int totalActivities;
  final int totalMinutes;
  final int totalHours;
  final List<DailyStatsDto> dailyStats;

  const ActivityRangeStatsDto({
    required this.startDate,
    required this.endDate,
    required this.totalActivities,
    required this.totalMinutes,
    required this.totalHours,
    required this.dailyStats,
  });

  factory ActivityRangeStatsDto.fromJson(Map<String, dynamic> json) {
    return ActivityRangeStatsDto(
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      totalActivities: json['totalActivities'] as int,
      totalMinutes: json['totalMinutes'] as int,
      totalHours: json['totalHours'] as int,
      dailyStats: (json['dailyStats'] as List<dynamic>)
          .map((e) => DailyStatsDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'endDate': endDate,
      'totalActivities': totalActivities,
      'totalMinutes': totalMinutes,
      'totalHours': totalHours,
      'dailyStats': dailyStats.map((e) => e.toJson()).toList(),
    };
  }
}

/// 每日统计 DTO
class DailyStatsDto {
  final String date;
  final int activityCount;
  final int durationMinutes;

  const DailyStatsDto({
    required this.date,
    required this.activityCount,
    required this.durationMinutes,
  });

  factory DailyStatsDto.fromJson(Map<String, dynamic> json) {
    return DailyStatsDto(
      date: json['date'] as String,
      activityCount: json['activityCount'] as int,
      durationMinutes: json['durationMinutes'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'activityCount': activityCount,
      'durationMinutes': durationMinutes,
    };
  }
}

/// 标签分组 DTO
class TagGroupDto {
  final String name;
  final List<String> tags;

  const TagGroupDto({
    required this.name,
    required this.tags,
  });

  factory TagGroupDto.fromJson(Map<String, dynamic> json) {
    return TagGroupDto(
      name: json['name'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tags': tags,
    };
  }
}

// ============ Query Objects ============

/// 活动查询参数
class ActivityQuery {
  final String? date;
  final DateTime? startDate;
  final DateTime? endDate;
  final PaginationParams? pagination;

  const ActivityQuery({
    this.date,
    this.startDate,
    this.endDate,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Activity Repository 接口
///
/// 客户端和服务端都实现此接口，但使用不同的数据源
abstract class IActivityRepository {
  // ============ 活动操作 ============

  /// 获取指定日期的活动列表
  ///
  /// [date] 日期字符串 (YYYY-MM-DD 格式)
  Future<Result<List<ActivityDto>>> getActivities({
    required String date,
    PaginationParams? pagination,
  });

  /// 根据 ID 获取活动
  Future<Result<ActivityDto?>> getActivityById({
    required String id,
    required String date,
  });

  /// 创建活动
  Future<Result<ActivityDto>> createActivity(ActivityDto activity);

  /// 更新活动
  Future<Result<ActivityDto>> updateActivity({
    required String id,
    required String date,
    required ActivityDto activity,
  });

  /// 删除活动
  Future<Result<bool>> deleteActivity({
    required String id,
    required String date,
  });

  // ============ 统计操作 ============

  /// 获取今日统计
  Future<Result<ActivityStatsDto>> getTodayStats();

  /// 获取日期范围统计
  Future<Result<ActivityRangeStatsDto>> getRangeStats({
    required String startDate,
    required String endDate,
  });

  // ============ 标签操作 ============

  /// 获取标签分组
  Future<Result<List<TagGroupDto>>> getTagGroups();

  /// 获取最近使用的标签
  Future<Result<List<String>>> getRecentTags();
}
