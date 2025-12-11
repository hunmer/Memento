/// Tracker 插件 - Repository 接口定义
///
/// 定义目标和记录的数据访问抽象接口

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 日期设置 DTO
class DateSettingsDto {
  final String type; // daily/weekly/monthly/custom
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? selectedDays; // 用于 weekly
  final int? monthDay; // 用于 monthly

  const DateSettingsDto({
    required this.type,
    this.startDate,
    this.endDate,
    this.selectedDays,
    this.monthDay,
  });

  factory DateSettingsDto.fromJson(Map<String, dynamic> json) {
    return DateSettingsDto(
      type: json['type'] as String,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      selectedDays: (json['selectedDays'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      monthDay: json['monthDay'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'selectedDays': selectedDays,
      'monthDay': monthDay,
    };
  }

  DateSettingsDto copyWith({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? selectedDays,
    int? monthDay,
  }) {
    return DateSettingsDto(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedDays: selectedDays ?? this.selectedDays,
      monthDay: monthDay ?? this.monthDay,
    );
  }
}

/// 目标 DTO
class GoalDto {
  final String id;
  final String name;
  final String icon;
  final int? iconColor;
  final String unitType;
  final String group;
  final String? imagePath;
  final int? progressColor;
  final double targetValue;
  final double currentValue;
  final DateSettingsDto dateSettings;
  final String? reminderTime;
  final bool isLoopReset;
  final DateTime createdAt;

  const GoalDto({
    required this.id,
    required this.name,
    required this.icon,
    this.iconColor,
    required this.unitType,
    this.group = '默认',
    this.imagePath,
    this.progressColor,
    required this.targetValue,
    required this.currentValue,
    required this.dateSettings,
    this.reminderTime,
    required this.isLoopReset,
    required this.createdAt,
  });

  /// 计算是否完成
  bool get isCompleted => currentValue >= targetValue;

  /// 计算进度百分比（0.0 - 1.0）
  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  factory GoalDto.fromJson(Map<String, dynamic> json) {
    return GoalDto(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      iconColor: json['iconColor'] as int?,
      unitType: json['unitType'] as String,
      group: json['group'] as String? ?? '默认',
      imagePath: json['imagePath'] as String?,
      progressColor: json['progressColor'] as int?,
      targetValue: (json['targetValue'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      dateSettings: DateSettingsDto.fromJson(json['dateSettings'] as Map<String, dynamic>),
      reminderTime: json['reminderTime'] as String?,
      isLoopReset: json['isLoopReset'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'iconColor': iconColor,
      'unitType': unitType,
      'group': group,
      'imagePath': imagePath,
      'progressColor': progressColor,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'dateSettings': dateSettings.toJson(),
      'reminderTime': reminderTime,
      'isLoopReset': isLoopReset,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  GoalDto copyWith({
    String? id,
    String? name,
    String? icon,
    int? iconColor,
    String? unitType,
    String? group,
    String? imagePath,
    int? progressColor,
    double? targetValue,
    double? currentValue,
    DateSettingsDto? dateSettings,
    String? reminderTime,
    bool? isLoopReset,
    DateTime? createdAt,
  }) {
    return GoalDto(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      unitType: unitType ?? this.unitType,
      group: group ?? this.group,
      imagePath: imagePath ?? this.imagePath,
      progressColor: progressColor ?? this.progressColor,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      dateSettings: dateSettings ?? this.dateSettings,
      reminderTime: reminderTime ?? this.reminderTime,
      isLoopReset: isLoopReset ?? this.isLoopReset,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 记录 DTO
class RecordDto {
  final String id;
  final String goalId;
  final double value;
  final String? note;
  final DateTime recordedAt;
  final int? durationSeconds;

  const RecordDto({
    required this.id,
    required this.goalId,
    required this.value,
    this.note,
    required this.recordedAt,
    this.durationSeconds,
  });

  factory RecordDto.fromJson(Map<String, dynamic> json) {
    return RecordDto(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      value: (json['value'] as num).toDouble(),
      note: json['note'] as String?,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      durationSeconds: json['durationSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'value': value,
      'note': note,
      'recordedAt': recordedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }

  RecordDto copyWith({
    String? id,
    String? goalId,
    double? value,
    String? note,
    DateTime? recordedAt,
    int? durationSeconds,
  }) {
    return RecordDto(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      value: value ?? this.value,
      note: note ?? this.note,
      recordedAt: recordedAt ?? this.recordedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}

/// 统计信息 DTO
class TrackerStatsDto {
  final int todayCompletedGoals;
  final int monthCompletedGoals;
  final int monthAddedGoals;
  final int todayRecordCount;
  final int totalGoals;
  final int activeGoals;
  final int completedGoals;

  const TrackerStatsDto({
    required this.todayCompletedGoals,
    required this.monthCompletedGoals,
    required this.monthAddedGoals,
    required this.todayRecordCount,
    required this.totalGoals,
    required this.activeGoals,
    required this.completedGoals,
  });

  factory TrackerStatsDto.fromJson(Map<String, dynamic> json) {
    return TrackerStatsDto(
      todayCompletedGoals: json['todayCompletedGoals'] as int? ?? 0,
      monthCompletedGoals: json['monthCompletedGoals'] as int? ?? 0,
      monthAddedGoals: json['monthAddedGoals'] as int? ?? 0,
      todayRecordCount: json['todayRecordCount'] as int? ?? 0,
      totalGoals: json['totalGoals'] as int? ?? 0,
      activeGoals: json['activeGoals'] as int? ?? 0,
      completedGoals: json['completedGoals'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayCompletedGoals': todayCompletedGoals,
      'monthCompletedGoals': monthCompletedGoals,
      'monthAddedGoals': monthAddedGoals,
      'todayRecordCount': todayRecordCount,
      'totalGoals': totalGoals,
      'activeGoals': activeGoals,
      'completedGoals': completedGoals,
    };
  }
}

// ============ Query Objects ============

/// 目标查询参数
class GoalQuery {
  final String? status; // 'active' / 'completed' / null(all)
  final String? group;
  final String? field;
  final String? value;
  final bool fuzzy;
  final PaginationParams? pagination;

  const GoalQuery({
    this.status,
    this.group,
    this.field,
    this.value,
    this.fuzzy = false,
    this.pagination,
  });
}

/// 记录查询参数
class RecordQuery {
  final String? goalId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? field;
  final String? value;
  final bool fuzzy;
  final PaginationParams? pagination;

  const RecordQuery({
    this.goalId,
    this.startDate,
    this.endDate,
    this.field,
    this.value,
    this.fuzzy = false,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Tracker Repository 接口
///
/// 客户端和服务端都实现此接口，但使用不同的数据源
abstract class ITrackerRepository {
  // ============ 目标操作 ============

  /// 获取所有目标
  Future<Result<List<GoalDto>>> getGoals({
    String? status,
    String? group,
    PaginationParams? pagination,
  });

  /// 根据 ID 获取目标
  Future<Result<GoalDto?>> getGoalById(String id);

  /// 创建目标
  Future<Result<GoalDto>> createGoal(GoalDto goal);

  /// 更新目标
  Future<Result<GoalDto>> updateGoal(String id, GoalDto goal);

  /// 删除目标
  Future<Result<bool>> deleteGoal(String id);

  /// 搜索目标
  Future<Result<List<GoalDto>>> searchGoals(GoalQuery query);

  /// 获取所有分组
  Future<Result<List<String>>> getAllGroups();

  // ============ 记录操作 ============

  /// 获取目标的记录列表
  Future<Result<List<RecordDto>>> getRecordsForGoal(
    String goalId, {
    PaginationParams? pagination,
  });

  /// 添加记录（自动更新目标的 currentValue）
  Future<Result<RecordDto>> addRecord(RecordDto record);

  /// 删除记录（自动回退目标的 currentValue）
  Future<Result<bool>> deleteRecord(String recordId);

  /// 清空目标的所有记录（重置 currentValue 为 0）
  Future<Result<bool>> clearRecordsForGoal(String goalId);

  /// 搜索记录
  Future<Result<List<RecordDto>>> searchRecords(RecordQuery query);

  // ============ 统计操作 ============

  /// 获取统计信息
  Future<Result<TrackerStatsDto>> getStats();
}
