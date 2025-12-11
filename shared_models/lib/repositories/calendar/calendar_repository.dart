/// Calendar 插件 - Repository 接口定义

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 日历事件 DTO
class CalendarEventDto {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final int icon;
  final int color;
  final String source;
  final int? reminderMinutes;
  final DateTime? completedTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarEventDto({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    this.endTime,
    required this.icon,
    required this.color,
    this.source = 'default',
    this.reminderMinutes,
    this.completedTime,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 构造
  factory CalendarEventDto.fromJson(Map<String, dynamic> json) {
    return CalendarEventDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      icon: json['icon'] as int,
      color: json['color'] as int,
      source: json['source'] as String? ?? 'default',
      reminderMinutes: json['reminderMinutes'] as int?,
      completedTime: json['completedTime'] != null ? DateTime.parse(json['completedTime'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'icon': icon,
      'color': color,
      'source': source,
      'reminderMinutes': reminderMinutes,
      'completedTime': completedTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改
  CalendarEventDto copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    int? icon,
    int? color,
    String? source,
    int? reminderMinutes,
    DateTime? completedTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEventDto(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      source: source ?? this.source,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      completedTime: completedTime ?? this.completedTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ============ Query Objects ============

/// 事件查询参数对象
class CalendarEventQuery {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? source;
  final String? titleKeyword;
  final bool? includeCompleted;
  final PaginationParams? pagination;

  const CalendarEventQuery({
    this.startDate,
    this.endDate,
    this.source,
    this.titleKeyword,
    this.includeCompleted,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Calendar 插件 Repository 接口
abstract class ICalendarRepository {
  // ============ 事件操作 ============

  /// 获取所有事件
  Future<Result<List<CalendarEventDto>>> getEvents({PaginationParams? pagination});

  /// 根据 ID 获取事件
  Future<Result<CalendarEventDto?>> getEventById(String id);

  /// 创建事件
  Future<Result<CalendarEventDto>> createEvent(CalendarEventDto event);

  /// 更新事件
  Future<Result<CalendarEventDto>> updateEvent(String id, CalendarEventDto event);

  /// 删除事件
  Future<Result<bool>> deleteEvent(String id);

  /// 完成事件
  Future<Result<CalendarEventDto>> completeEvent(String id, DateTime completedTime);

  /// 搜索事件
  Future<Result<List<CalendarEventDto>>> searchEvents(CalendarEventQuery query);

  // ============ 已完成事件操作 ============

  /// 获取已完成事件
  Future<Result<List<CalendarEventDto>>> getCompletedEvents({PaginationParams? pagination});

  /// 根据 ID 获取已完成事件
  Future<Result<CalendarEventDto?>> getCompletedEventById(String id);

  /// 恢复已完成事件（移回未完成列表）
  Future<Result<CalendarEventDto>> restoreCompletedEvent(String id);

  /// 删除已完成事件
  Future<Result<bool>> deleteCompletedEvent(String id);
}
