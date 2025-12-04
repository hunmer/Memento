/// 动作实例模型
/// 表示一个具体的动作配置和执行数据
library;

import 'package:flutter/material.dart';

/// 动作实例状态
enum ActionInstanceStatus {
  enabled,    // 已启用
  disabled,   // 已禁用
  pending,    // 待执行
  running,    // 正在执行
  completed,  // 执行完成
  failed,     // 执行失败
}

/// 动作实例类
/// 绑定一个具体的动作定义到执行数据
class ActionInstance {
  /// 动作实例唯一标识
  final String? id;

  /// 绑定的动作定义ID
  final String actionId;

  /// 执行数据（参数）
  final Map<String, dynamic> data;

  /// 实例状态
  final ActionInstanceStatus status;

  /// 是否启用
  final bool enabled;

  /// 自定义标题（覆盖动作定义的默认标题）
  final String? customTitle;

  /// 自定义描述
  final String? customDescription;

  /// 自定义图标
  final IconData? customIcon;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  /// 最后执行时间
  final DateTime? lastExecutedAt;

  /// 执行次数统计
  final int executionCount;

  /// 执行成功次数
  final int successCount;

  /// 执行失败次数
  final int failureCount;

  /// 平均执行耗时（毫秒）
  final int? averageExecutionTime;

  /// 动作实例标签
  final List<String> tags;

  /// 创建动作实例
  ActionInstance({
    this.id,
    required this.actionId,
    required this.data,
    this.status = ActionInstanceStatus.enabled,
    this.enabled = true,
    this.customTitle,
    this.customDescription,
    this.customIcon,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastExecutedAt,
    this.executionCount = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.averageExecutionTime,
    this.tags = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 创建动作实例（带ID生成）
  factory ActionInstance.create({
    required String actionId,
    Map<String, dynamic> data = const {},
    String? customTitle,
    String? customDescription,
    IconData? customIcon,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    return ActionInstance(
      id: 'inst_${now.millisecondsSinceEpoch}_${actionId.hashCode}',
      actionId: actionId,
      data: data,
      createdAt: now,
      updatedAt: now,
      customTitle: customTitle,
      customDescription: customDescription,
      customIcon: customIcon,
      tags: tags,
    );
  }

  /// 从JSON创建
  factory ActionInstance.fromJson(Map<String, dynamic> json) {
    return ActionInstance(
      id: json['id'] as String?,
      actionId: json['actionId'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      status: ActionInstanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ActionInstanceStatus.enabled,
      ),
      enabled: json['enabled'] as bool? ?? true,
      customTitle: json['customTitle'] as String?,
      customDescription: json['customDescription'] as String?,
      customIcon: json['customIconCodePoint'] != null
          ? IconData(
              json['customIconCodePoint'] as int,
              fontFamily: json['customIconFontFamily'] as String?,
            )
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastExecutedAt: json['lastExecutedAt'] != null
          ? DateTime.parse(json['lastExecutedAt'] as String)
          : null,
      executionCount: json['executionCount'] as int? ?? 0,
      successCount: json['successCount'] as int? ?? 0,
      failureCount: json['failureCount'] as int? ?? 0,
      averageExecutionTime: json['averageExecutionTime'] as int?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          const [],
    );
  }

  /// 序列化到JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionId': actionId,
      'data': data,
      'status': status.name,
      'enabled': enabled,
      'customTitle': customTitle,
      'customDescription': customDescription,
      'customIconCodePoint': customIcon?.codePoint,
      'customIconFontFamily': customIcon?.fontFamily,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastExecutedAt': lastExecutedAt?.toIso8601String(),
      'executionCount': executionCount,
      'successCount': successCount,
      'failureCount': failureCount,
      'averageExecutionTime': averageExecutionTime,
      'tags': tags,
    };
  }

  /// 获取显示标题（优先使用自定义标题）
  String get displayTitle => customTitle ?? actionId;

  /// 获取显示描述
  String? get displayDescription => customDescription;

  /// 获取显示图标
  IconData? get displayIcon => customIcon;

  /// 检查实例是否可以使用
  bool get isAvailable => enabled && status == ActionInstanceStatus.enabled;

  /// 获取成功率（百分比）
  double get successRate {
    if (executionCount == 0) return 0.0;
    return (successCount / executionCount) * 100;
  }

  /// 复制并修改属性
  ActionInstance copyWith({
    String? id,
    String? actionId,
    Map<String, dynamic>? data,
    ActionInstanceStatus? status,
    bool? enabled,
    String? customTitle,
    String? customDescription,
    IconData? customIcon,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastExecutedAt,
    int? executionCount,
    int? successCount,
    int? failureCount,
    int? averageExecutionTime,
    List<String>? tags,
  }) {
    return ActionInstance(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      data: data ?? this.data,
      status: status ?? this.status,
      enabled: enabled ?? this.enabled,
      customTitle: customTitle ?? this.customTitle,
      customDescription: customDescription ?? this.customDescription,
      customIcon: customIcon ?? this.customIcon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      executionCount: executionCount ?? this.executionCount,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      averageExecutionTime: averageExecutionTime ?? this.averageExecutionTime,
      tags: tags ?? this.tags,
    );
  }

  /// 更新执行统计信息
  ActionInstance updateExecution({
    required bool success,
    int? executionTime,
    DateTime? executedAt,
  }) {
    final now = executedAt ?? DateTime.now();
    final newCount = executionCount + 1;
    final newSuccess = successCount + (success ? 1 : 0);
    final newFailure = failureCount + (success ? 0 : 1);

    // 计算平均执行时间
    int? newAvgTime;
    if (executionTime != null) {
      if (averageExecutionTime == null) {
        newAvgTime = executionTime;
      } else {
        newAvgTime =
            ((averageExecutionTime! * executionCount) + executionTime) ~/
                newCount;
      }
    }

    return copyWith(
      status: success ? ActionInstanceStatus.completed : ActionInstanceStatus.failed,
      lastExecutedAt: now,
      executionCount: newCount,
      successCount: newSuccess,
      failureCount: newFailure,
      averageExecutionTime: newAvgTime,
      updatedAt: now,
    );
  }

  /// 标记为正在执行
  ActionInstance markAsRunning() {
    return copyWith(
      status: ActionInstanceStatus.running,
      updatedAt: DateTime.now(),
    );
  }

  /// 重置统计信息
  ActionInstance resetStats() {
    return copyWith(
      executionCount: 0,
      successCount: 0,
      failureCount: 0,
      averageExecutionTime: null,
      updatedAt: DateTime.now(),
    );
  }

  /// 添加标签
  ActionInstance addTag(String tag) {
    if (!tags.contains(tag)) {
      return copyWith(tags: [...tags, tag]);
    }
    return this;
  }

  /// 移除标签
  ActionInstance removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toList());
  }

  /// 更新自定义标题
  ActionInstance updateTitle(String title) {
    return copyWith(customTitle: title, updatedAt: DateTime.now());
  }

  /// 更新自定义描述
  ActionInstance updateDescription(String description) {
    return copyWith(customDescription: description, updatedAt: DateTime.now());
  }

  /// 更新自定义图标
  ActionInstance updateIcon(IconData icon) {
    return copyWith(customIcon: icon, updatedAt: DateTime.now());
  }

  /// 启用/禁用实例
  ActionInstance setEnabled(bool value) {
    return copyWith(
      enabled: value,
      status: value ? ActionInstanceStatus.enabled : ActionInstanceStatus.disabled,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ActionInstance(id: $id, actionId: $actionId, enabled: $enabled, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is ActionInstance) {
      return id == other.id || (id != null && other.id != null && id == other.id);
    }
    return false;
  }

  @override
  int get hashCode {
    return id?.hashCode ?? actionId.hashCode;
  }
}

/// 动作实例分组
class ActionInstanceGroup {
  final String id;
  final String name;
  final List<ActionInstance> instances;
  final String? description;

  const ActionInstanceGroup({
    required this.id,
    required this.name,
    required this.instances,
    this.description,
  });

  factory ActionInstanceGroup.fromJson(Map<String, dynamic> json) {
    return ActionInstanceGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      instances: (json['instances'] as List<dynamic>)
          .map((i) => ActionInstance.fromJson(i as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'instances': instances.map((i) => i.toJson()).toList(),
      'description': description,
    };
  }
}
