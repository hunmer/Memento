/// Habits 插件 - Repository 接口定义
library;

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 习惯 DTO
class HabitDto {
  final String id;
  final String title;
  final String? notes;
  final String? group;
  final String? icon;
  final String? image;
  final List<int> reminderDays;
  final int intervalDays;
  final int durationMinutes;
  final List<String> tags;
  final String? skillId;

  const HabitDto({
    required this.id,
    required this.title,
    this.notes,
    this.group,
    this.icon,
    this.image,
    this.reminderDays = const [],
    this.intervalDays = 0,
    required this.durationMinutes,
    this.tags = const [],
    this.skillId,
  });

  factory HabitDto.fromJson(Map<String, dynamic> json) {
    return HabitDto(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      group: json['group'] as String?,
      icon: json['icon'] as String?,
      image: json['image'] as String?,
      reminderDays: (json['reminderDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      intervalDays: json['intervalDays'] as int? ?? 0,
      durationMinutes: json['durationMinutes'] as int,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      skillId: json['skillId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'group': group,
      'icon': icon,
      'image': image,
      'reminderDays': reminderDays,
      'intervalDays': intervalDays,
      'durationMinutes': durationMinutes,
      'tags': tags,
      'skillId': skillId,
    };
  }

  HabitDto copyWith({
    String? id,
    String? title,
    String? notes,
    String? group,
    String? icon,
    String? image,
    List<int>? reminderDays,
    int? intervalDays,
    int? durationMinutes,
    List<String>? tags,
    String? skillId,
  }) {
    return HabitDto(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      group: group ?? this.group,
      icon: icon ?? this.icon,
      image: image ?? this.image,
      reminderDays: reminderDays ?? this.reminderDays,
      intervalDays: intervalDays ?? this.intervalDays,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      tags: tags ?? this.tags,
      skillId: skillId ?? this.skillId,
    );
  }
}

/// 技能 DTO
class SkillDto {
  final String id;
  final String title;
  final String? description;
  final String? notes;
  final String? group;
  final String? icon;
  final String? image;
  final int targetMinutes;
  final int maxDurationMinutes;

  const SkillDto({
    required this.id,
    required this.title,
    this.description,
    this.notes,
    this.group,
    this.icon,
    this.image,
    this.targetMinutes = 0,
    this.maxDurationMinutes = 0,
  });

  factory SkillDto.fromJson(Map<String, dynamic> json) {
    return SkillDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      group: json['group'] as String?,
      icon: json['icon'] as String?,
      image: json['image'] as String?,
      targetMinutes: json['targetMinutes'] as int? ?? 0,
      maxDurationMinutes: json['maxDurationMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'notes': notes,
      'group': group,
      'icon': icon,
      'image': image,
      'targetMinutes': targetMinutes,
      'maxDurationMinutes': maxDurationMinutes,
    };
  }

  SkillDto copyWith({
    String? id,
    String? title,
    String? description,
    String? notes,
    String? group,
    String? icon,
    String? image,
    int? targetMinutes,
    int? maxDurationMinutes,
  }) {
    return SkillDto(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      group: group ?? this.group,
      icon: icon ?? this.icon,
      image: image ?? this.image,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      maxDurationMinutes: maxDurationMinutes ?? this.maxDurationMinutes,
    );
  }
}

/// 完成记录 DTO
class CompletionRecordDto {
  final String id;
  final String parentId;
  final DateTime date;
  final int durationSeconds;
  final String notes;

  const CompletionRecordDto({
    required this.id,
    required this.parentId,
    required this.date,
    required this.durationSeconds,
    this.notes = '',
  });

  factory CompletionRecordDto.fromJson(Map<String, dynamic> json) {
    return CompletionRecordDto(
      id: json['id'] as String,
      parentId: json['parentId'] as String,
      date: DateTime.parse(json['date'] as String),
      durationSeconds: json['durationSeconds'] as int,
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'date': date.toIso8601String(),
      'durationSeconds': durationSeconds,
      'notes': notes,
    };
  }

  CompletionRecordDto copyWith({
    String? id,
    String? parentId,
    DateTime? date,
    int? durationSeconds,
    String? notes,
  }) {
    return CompletionRecordDto(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      notes: notes ?? this.notes,
    );
  }
}

// ============ Query Objects ============

/// 习惯查询参数对象
class HabitQuery {
  final String? skillId;
  final String? group;
  final PaginationParams? pagination;

  const HabitQuery({
    this.skillId,
    this.group,
    this.pagination,
  });
}

/// 技能查询参数对象
class SkillQuery {
  final String? group;
  final String? titleKeyword;
  final PaginationParams? pagination;

  const SkillQuery({
    this.group,
    this.titleKeyword,
    this.pagination,
  });
}

/// 完成记录查询参数对象
class CompletionRecordQuery {
  final String parentId;
  final DateTime? startDate;
  final DateTime? endDate;
  final PaginationParams? pagination;

  const CompletionRecordQuery({
    required this.parentId,
    this.startDate,
    this.endDate,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Habits 插件 Repository 接口
abstract class IHabitsRepository {
  // ============ 习惯操作 ============

  /// 获取所有习惯
  Future<Result<List<HabitDto>>> getHabits({PaginationParams? pagination});

  /// 根据 ID 获取习惯
  Future<Result<HabitDto?>> getHabitById(String id);

  /// 创建习惯
  Future<Result<HabitDto>> createHabit(HabitDto habit);

  /// 更新习惯
  Future<Result<HabitDto>> updateHabit(String id, HabitDto habit);

  /// 删除习惯
  Future<Result<bool>> deleteHabit(String id);

  /// 搜索习惯
  Future<Result<List<HabitDto>>> searchHabits(HabitQuery query);

  // ============ 技能操作 ============

  /// 获取所有技能
  Future<Result<List<SkillDto>>> getSkills({PaginationParams? pagination});

  /// 根据 ID 获取技能
  Future<Result<SkillDto?>> getSkillById(String id);

  /// 创建技能
  Future<Result<SkillDto>> createSkill(SkillDto skill);

  /// 更新技能
  Future<Result<SkillDto>> updateSkill(String id, SkillDto skill);

  /// 删除技能
  Future<Result<bool>> deleteSkill(String id);

  /// 搜索技能
  Future<Result<List<SkillDto>>> searchSkills(SkillQuery query);

  // ============ 完成记录操作 ============

  /// 获取指定习惯的完成记录
  Future<Result<List<CompletionRecordDto>>> getCompletionRecords(
    String parentId, {
    PaginationParams? pagination,
  });

  /// 根据 ID 获取完成记录
  Future<Result<CompletionRecordDto?>> getCompletionRecordById(String id);

  /// 创建完成记录
  Future<Result<CompletionRecordDto>> createCompletionRecord(
    CompletionRecordDto record,
  );

  /// 删除完成记录
  Future<Result<bool>> deleteCompletionRecord(String id);

  /// 搜索完成记录
  Future<Result<List<CompletionRecordDto>>> searchCompletionRecords(
    CompletionRecordQuery query,
  );

  // ============ 统计操作 ============

  /// 获取习惯的总时长（分钟）
  Future<Result<int>> getHabitTotalDuration(String habitId);

  /// 获取习惯的完成次数
  Future<Result<int>> getHabitCompletionCount(String habitId);

  /// 获取技能的总时长（分钟）
  Future<Result<int>> getSkillTotalDuration(String skillId);

  /// 获取技能的完成次数
  Future<Result<int>> getSkillCompletionCount(String skillId);
}
