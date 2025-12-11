/// Todo 插件 - Repository 接口定义

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 任务 DTO
class TaskDto {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final int priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  const TaskDto({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = 0,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.tags = const [],
    this.metadata,
  });

  factory TaskDto.fromJson(Map<String, dynamic> json) {
    return TaskDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'tags': tags,
      'metadata': metadata,
    };
  }

  TaskDto copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    int? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return TaskDto(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 任务统计 DTO
class TaskStatsDto {
  final int total;
  final int completed;
  final int pending;
  final int overdue;
  final int dueToday;

  const TaskStatsDto({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.dueToday,
  });

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
      'dueToday': dueToday,
    };
  }
}

// ============ Query Objects ============

/// 任务查询参数
class TaskQuery {
  final String? keyword;
  final bool? isCompleted;
  final DateTime? dueBefore;
  final DateTime? dueAfter;
  final List<String>? tags;
  final String? field;
  final String? value;
  final bool fuzzy;
  final bool findAll;
  final PaginationParams? pagination;

  const TaskQuery({
    this.keyword,
    this.isCompleted,
    this.dueBefore,
    this.dueAfter,
    this.tags,
    this.field,
    this.value,
    this.fuzzy = false,
    this.findAll = true,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Todo Repository 接口
abstract class ITodoRepository {
  // ============ 任务操作 ============

  /// 获取所有任务
  Future<Result<List<TaskDto>>> getTasks({PaginationParams? pagination});

  /// 根据 ID 获取任务
  Future<Result<TaskDto?>> getTaskById(String id);

  /// 创建任务
  Future<Result<TaskDto>> createTask(TaskDto task);

  /// 更新任务
  Future<Result<TaskDto>> updateTask(String id, TaskDto task);

  /// 删除任务
  Future<Result<bool>> deleteTask(String id);

  /// 完成任务
  Future<Result<TaskDto>> completeTask(String id);

  /// 取消完成任务
  Future<Result<TaskDto>> uncompleteTask(String id);

  /// 搜索任务
  Future<Result<List<TaskDto>>> searchTasks(TaskQuery query);

  /// 获取今日任务
  Future<Result<List<TaskDto>>> getTodayTasks({PaginationParams? pagination});

  /// 获取逾期任务
  Future<Result<List<TaskDto>>> getOverdueTasks({PaginationParams? pagination});

  /// 获取已完成任务
  Future<Result<List<TaskDto>>> getCompletedTasks({PaginationParams? pagination});

  /// 获取未完成任务
  Future<Result<List<TaskDto>>> getPendingTasks({PaginationParams? pagination});

  /// 获取统计数据
  Future<Result<TaskStatsDto>> getStats();
}
