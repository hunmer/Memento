/// Timer 插件 - Repository 接口定义

import 'package:shared_models/utils/result.dart';
import 'package:shared_models/utils/pagination.dart';

// ============ DTOs ============

/// 计时任务 DTO
class TimerTaskDto {
  final String id;
  final String name;
  final int color; // ARGB 颜色值
  final int iconCodePoint; // 图标代码点
  final List<TimerItemDto> timerItems;
  final DateTime createdAt;
  final int repeatCount; // 配置的重复次数
  final bool isRunning; // 是否正在运行
  final String group; // 分组名称
  final bool enableNotification; // 是否启用消息提醒

  const TimerTaskDto({
    required this.id,
    required this.name,
    required this.color,
    required this.iconCodePoint,
    required this.timerItems,
    required this.createdAt,
    this.repeatCount = 1,
    this.isRunning = false,
    required this.group,
    this.enableNotification = false,
  });

  factory TimerTaskDto.fromJson(Map<String, dynamic> json) {
    return TimerTaskDto(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as int,
      iconCodePoint: json['iconCodePoint'] as int,
      timerItems: (json['timerItems'] as List<dynamic>?)
              ?.map((e) => TimerItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      repeatCount: json['repeatCount'] as int? ?? 1,
      isRunning: json['isRunning'] as bool? ?? false,
      group: json['group'] as String? ?? '默认',
      enableNotification: json['enableNotification'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'iconCodePoint': iconCodePoint,
      'timerItems': timerItems.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'repeatCount': repeatCount,
      'isRunning': isRunning,
      'group': group,
      'enableNotification': enableNotification,
    };
  }

  TimerTaskDto copyWith({
    String? id,
    String? name,
    int? color,
    int? iconCodePoint,
    List<TimerItemDto>? timerItems,
    DateTime? createdAt,
    int? repeatCount,
    bool? isRunning,
    String? group,
    bool? enableNotification,
  }) {
    return TimerTaskDto(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      timerItems: timerItems ?? List.from(this.timerItems),
      createdAt: createdAt ?? this.createdAt,
      repeatCount: repeatCount ?? this.repeatCount,
      isRunning: isRunning ?? this.isRunning,
      group: group ?? this.group,
      enableNotification: enableNotification ?? this.enableNotification,
    );
  }
}

/// 计时器项 DTO
class TimerItemDto {
  final String id;
  final String name;
  final String? description;
  final int type; // TimerType 枚举值
  final int duration; // 设定时长（秒）
  final int completedDuration; // 已完成时长（秒）
  final bool isRunning;
  final int? workDuration; // 工作时长（秒）
  final int? breakDuration; // 休息时长（秒）
  final int? cycles; // 循环次数
  final int? currentCycle; // 当前循环
  final bool? isWorkPhase; // 是否处于工作阶段
  final int repeatCount; // 重复次数
  final int? intervalAlertDuration; // 间隔提示时长（秒）
  final bool enableNotification;

  const TimerItemDto({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.duration,
    this.completedDuration = 0,
    this.isRunning = false,
    this.workDuration,
    this.breakDuration,
    this.cycles,
    this.currentCycle,
    this.isWorkPhase,
    this.repeatCount = 1,
    this.intervalAlertDuration,
    this.enableNotification = false,
  });

  factory TimerItemDto.fromJson(Map<String, dynamic> json) {
    return TimerItemDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as int,
      duration: json['duration'] as int,
      completedDuration: json['completedDuration'] as int? ?? 0,
      isRunning: json['isRunning'] as bool? ?? false,
      workDuration: json['workDuration'] as int?,
      breakDuration: json['breakDuration'] as int?,
      cycles: json['cycles'] as int?,
      currentCycle: json['currentCycle'] as int?,
      isWorkPhase: json['isWorkPhase'] as bool?,
      repeatCount: json['repeatCount'] as int? ?? 1,
      intervalAlertDuration: json['intervalAlertDuration'] as int?,
      enableNotification: json['enableNotification'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'duration': duration,
      'completedDuration': completedDuration,
      'isRunning': isRunning,
      'workDuration': workDuration,
      'breakDuration': breakDuration,
      'cycles': cycles,
      'currentCycle': currentCycle,
      'isWorkPhase': isWorkPhase,
      'repeatCount': repeatCount,
      'intervalAlertDuration': intervalAlertDuration,
      'enableNotification': enableNotification,
    };
  }

  TimerItemDto copyWith({
    String? id,
    String? name,
    String? description,
    int? type,
    int? duration,
    int? completedDuration,
    bool? isRunning,
    int? workDuration,
    int? breakDuration,
    int? cycles,
    int? currentCycle,
    bool? isWorkPhase,
    int? repeatCount,
    int? intervalAlertDuration,
    bool? enableNotification,
  }) {
    return TimerItemDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      completedDuration: completedDuration ?? this.completedDuration,
      isRunning: isRunning ?? this.isRunning,
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      cycles: cycles ?? this.cycles,
      currentCycle: currentCycle ?? this.currentCycle,
      isWorkPhase: isWorkPhase ?? this.isWorkPhase,
      repeatCount: repeatCount ?? this.repeatCount,
      intervalAlertDuration: intervalAlertDuration ?? this.intervalAlertDuration,
      enableNotification: enableNotification ?? this.enableNotification,
    );
  }
}

// ============ Query Objects ============

/// 计时任务查询参数对象
class TimerTaskQuery {
  final String? group;
  final bool? isRunning;
  final PaginationParams? pagination;

  const TimerTaskQuery({
    this.group,
    this.isRunning,
    this.pagination,
  });
}

// ============ Repository Interface ============

/// Timer 插件 Repository 接口
abstract class ITimerRepository {
  // ============ 任务操作 ============

  /// 获取所有计时任务
  Future<Result<List<TimerTaskDto>>> getTimerTasks({PaginationParams? pagination});

  /// 根据 ID 获取任务
  Future<Result<TimerTaskDto?>> getTimerTaskById(String id);

  /// 创建任务
  Future<Result<TimerTaskDto>> createTimerTask(TimerTaskDto task);

  /// 更新任务
  Future<Result<TimerTaskDto>> updateTimerTask(String id, TimerTaskDto task);

  /// 删除任务
  Future<Result<bool>> deleteTimerTask(String id);

  /// 搜索任务
  Future<Result<List<TimerTaskDto>>> searchTimerTasks(TimerTaskQuery query);

  // ============ 计时器项操作 ============

  /// 获取指定任务的所有计时器项
  Future<Result<List<TimerItemDto>>> getTimerItems(String taskId,
      {PaginationParams? pagination});

  /// 根据 ID 获取计时器项
  Future<Result<TimerItemDto?>> getTimerItemById(String id);

  /// 创建计时器项
  Future<Result<TimerItemDto>> createTimerItem(TimerItemDto item);

  /// 更新计时器项
  Future<Result<TimerItemDto>> updateTimerItem(String id, TimerItemDto item);

  /// 删除计时器项
  Future<Result<bool>> deleteTimerItem(String id);

  // ============ 统计操作 ============

  /// 获取任务总数
  Future<Result<int>> getTotalTaskCount();

  /// 获取正在运行的任务数
  Future<Result<int>> getRunningTaskCount();

  /// 获取指定分组的任务数
  Future<Result<int>> getTaskCountByGroup(String group);
}
