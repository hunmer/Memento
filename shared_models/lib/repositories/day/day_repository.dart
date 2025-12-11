/// Day 插件 - Repository 接口定义
///
/// 定义纪念日的数据访问抽象接口
library;

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 纪念日 DTO
class MemorialDayDto {
  final String id;
  final String title;
  final DateTime creationDate;
  final DateTime targetDate;
  final List<String> notes;
  final int backgroundColor;
  final String? backgroundImageUrl;
  final int sortIndex;

  const MemorialDayDto({
    required this.id,
    required this.title,
    required this.creationDate,
    required this.targetDate,
    this.notes = const [],
    required this.backgroundColor,
    this.backgroundImageUrl,
    this.sortIndex = 0,
  });

  factory MemorialDayDto.fromJson(Map<String, dynamic> json) {
    return MemorialDayDto(
      id: json['id'] as String,
      title: json['title'] as String,
      creationDate: DateTime.parse(json['creationDate'] as String),
      targetDate: DateTime.parse(json['targetDate'] as String),
      notes: (json['notes'] as List<dynamic>?)?.cast<String>() ?? [],
      backgroundColor: json['backgroundColor'] as int,
      backgroundImageUrl: json['backgroundImageUrl'] as String?,
      sortIndex: json['sortIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'creationDate': creationDate.toIso8601String(),
      'targetDate': targetDate.toIso8601String(),
      'notes': notes,
      'backgroundColor': backgroundColor,
      'backgroundImageUrl': backgroundImageUrl,
      'sortIndex': sortIndex,
    };
  }

  MemorialDayDto copyWith({
    String? id,
    String? title,
    DateTime? creationDate,
    DateTime? targetDate,
    List<String>? notes,
    int? backgroundColor,
    String? backgroundImageUrl,
    int? sortIndex,
  }) {
    return MemorialDayDto(
      id: id ?? this.id,
      title: title ?? this.title,
      creationDate: creationDate ?? this.creationDate,
      targetDate: targetDate ?? this.targetDate,
      notes: notes ?? this.notes,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      sortIndex: sortIndex ?? this.sortIndex,
    );
  }

  // 计算剩余天数
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }

  // 判断是否已经过期
  bool get isExpired => daysRemaining < 0;

  // 判断是否为今天
  bool get isToday => daysRemaining == 0;
}

/// 纪念日统计信息 DTO
class MemorialDayStatsDto {
  final int total;
  final int upcoming; // 7天内
  final int today;
  final int expired;

  const MemorialDayStatsDto({
    required this.total,
    required this.upcoming,
    required this.today,
    required this.expired,
  });

  factory MemorialDayStatsDto.fromJson(Map<String, dynamic> json) {
    return MemorialDayStatsDto(
      total: json['total'] as int,
      upcoming: json['upcoming'] as int,
      today: json['today'] as int,
      expired: json['expired'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'upcoming': upcoming,
      'today': today,
      'expired': expired,
    };
  }
}

// ============ Query Objects ============

/// 纪念日查询参数
class MemorialDayQuery {
  final String? sortMode; // upcoming, recent, manual
  final DateTime? startDate; // 时间范围查询
  final DateTime? endDate;
  final bool? includeExpired;
  final PaginationParams? pagination;

  const MemorialDayQuery({
    this.sortMode,
    this.startDate,
    this.endDate,
    this.includeExpired,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Day Repository 接口
///
/// 客户端和服务端都实现此接口，但使用不同的数据源
abstract class IDayRepository {
  // ============ 纪念日操作 ============

  /// 获取所有纪念日
  Future<Result<List<MemorialDayDto>>> getMemorialDays({
    String? sortMode,
    PaginationParams? pagination,
  });

  /// 根据 ID 获取纪念日
  Future<Result<MemorialDayDto?>> getMemorialDayById(String id);

  /// 创建纪念日
  Future<Result<MemorialDayDto>> createMemorialDay(MemorialDayDto memorialDay);

  /// 更新纪念日
  Future<Result<MemorialDayDto>> updateMemorialDay(
      String id, MemorialDayDto memorialDay);

  /// 删除纪念日
  Future<Result<bool>> deleteMemorialDay(String id);

  /// 重新排序纪念日
  Future<Result<bool>> reorderMemorialDays(List<String> orderedIds);

  /// 搜索纪念日
  Future<Result<List<MemorialDayDto>>> searchMemorialDays(
      MemorialDayQuery query);

  /// 获取统计信息
  Future<Result<MemorialDayStatsDto>> getStats();
}
