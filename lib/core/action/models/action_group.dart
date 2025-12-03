/// 动作组模型
/// 支持多个动作的组合执行
library action_group;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'action_definition.dart';
import 'action_instance.dart';

/// 动作组操作符
enum GroupOperator {
  sequence,    // 顺序执行
  parallel,    // 并行执行
  condition,   // 条件执行
}

/// 动作组执行模式
enum GroupExecutionMode {
  all,       // 执行所有动作
  any,       // 执行任一动作
  first,     // 只执行第一个
  last,      // 只执行最后一个
  custom,    // 自定义执行
}

/// 动作组状态
enum ActionGroupStatus {
  idle,       // 空闲
  running,    // 正在执行
  completed,  // 执行完成
  failed,     // 执行失败
  cancelled,  // 已取消
}

/// 动作组类
/// 封装多个动作实例，支持组合执行
class ActionGroup {
  /// 动作组唯一标识
  final String? id;

  /// 动作组标题
  final String title;

  /// 动作组描述
  final String? description;

  /// 图标
  final IconData? icon;

  /// 操作符
  final GroupOperator operator;

  /// 执行模式
  final GroupExecutionMode executionMode;

  /// 子动作列表
  final List<ActionInstance> actions;

  /// 条件表达式（条件执行时使用）
  final String? condition;

  /// 最大并行执行数量（并行执行时使用）
  final int? maxParallelCount;

  /// 超时时间（毫秒）
  final int? timeoutMs;

  /// 是否启用
  final bool enabled;

  /// 优先级（数值越大优先级越高）
  final int priority;

  /// 标签
  final List<String> tags;

  /// 颜色
  final Color? color;

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

  /// 状态
  final ActionGroupStatus status;

  /// 创建动作组
  ActionGroup({
    this.id,
    required this.title,
    this.description,
    this.icon,
    required this.operator,
    this.executionMode = GroupExecutionMode.all,
    required this.actions,
    this.condition,
    this.maxParallelCount,
    this.timeoutMs,
    this.enabled = true,
    this.priority = 0,
    this.tags = const [],
    this.color,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastExecutedAt,
    this.executionCount = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.averageExecutionTime,
    this.status = ActionGroupStatus.idle,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 创建动作组（带ID生成）
  factory ActionGroup.create({
    required String title,
    String? description,
    IconData? icon,
    GroupOperator operator = GroupOperator.sequence,
    GroupExecutionMode executionMode = GroupExecutionMode.all,
    List<ActionInstance> actions = const [],
    String? condition,
    int? maxParallelCount,
    int? timeoutMs,
    int priority = 0,
    List<String> tags = const [],
    Color? color,
  }) {
    final now = DateTime.now();
    return ActionGroup(
      id: 'group_${now.millisecondsSinceEpoch}',
      title: title,
      description: description,
      icon: icon,
      operator: operator,
      executionMode: executionMode,
      actions: actions,
      condition: condition,
      maxParallelCount: maxParallelCount,
      timeoutMs: timeoutMs,
      priority: priority,
      tags: tags,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从JSON创建
  factory ActionGroup.fromJson(Map<String, dynamic> json) {
    return ActionGroup(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      icon: json['iconCodePoint'] != null
          ? IconData(
              json['iconCodePoint'] as int,
              fontFamily: json['iconFontFamily'] as String?,
            )
          : null,
      operator: GroupOperator.values.firstWhere(
        (e) => e.name == json['operator'],
        orElse: () => GroupOperator.sequence,
      ),
      executionMode: GroupExecutionMode.values.firstWhere(
        (e) => e.name == json['executionMode'],
        orElse: () => GroupExecutionMode.all,
      ),
      actions: (json['actions'] as List<dynamic>)
          .map((a) => ActionInstance.fromJson(a as Map<String, dynamic>))
          .toList(),
      condition: json['condition'] as String?,
      maxParallelCount: json['maxParallelCount'] as int?,
      timeoutMs: json['timeoutMs'] as int?,
      enabled: json['enabled'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          const [],
      color: json['color'] != null
          ? Color(json['color'] as int)
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
      status: ActionGroupStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ActionGroupStatus.idle,
      ),
    );
  }

  /// 序列化到JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCodePoint': icon?.codePoint,
      'iconFontFamily': icon?.fontFamily,
      'operator': operator.name,
      'executionMode': executionMode.name,
      'actions': actions.map((a) => a.toJson()).toList(),
      'condition': condition,
      'maxParallelCount': maxParallelCount,
      'timeoutMs': timeoutMs,
      'enabled': enabled,
      'priority': priority,
      'tags': tags,
      'color': color?.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastExecutedAt': lastExecutedAt?.toIso8601String(),
      'executionCount': executionCount,
      'successCount': successCount,
      'failureCount': failureCount,
      'averageExecutionTime': averageExecutionTime,
      'status': status.name,
    };
  }

  /// 获取显示标题
  String get displayTitle => title;

  /// 获取显示描述
  String? get displayDescription => description;

  /// 获取显示图标
  IconData? get displayIcon => icon;

  /// 获取显示颜色
  Color? get displayColor => color;

  /// 检查是否可以使用
  bool get isAvailable => enabled && actions.isNotEmpty;

  /// 获取成功率（百分比）
  double get successRate {
    if (executionCount == 0) return 0.0;
    return (successCount / executionCount) * 100;
  }

  /// 获取平均动作数量
  double get averageActionCount {
    if (executionCount == 0) return actions.length.toDouble();
    return actions.length.toDouble();
  }

  /// 复制并修改属性
  ActionGroup copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    GroupOperator? operator,
    GroupExecutionMode? executionMode,
    List<ActionInstance>? actions,
    String? condition,
    int? maxParallelCount,
    int? timeoutMs,
    bool? enabled,
    int? priority,
    List<String>? tags,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastExecutedAt,
    int? executionCount,
    int? successCount,
    int? failureCount,
    int? averageExecutionTime,
    ActionGroupStatus? status,
  }) {
    return ActionGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      operator: operator ?? this.operator,
      executionMode: executionMode ?? this.executionMode,
      actions: actions ?? this.actions,
      condition: condition ?? this.condition,
      maxParallelCount: maxParallelCount ?? this.maxParallelCount,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      enabled: enabled ?? this.enabled,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      executionCount: executionCount ?? this.executionCount,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      averageExecutionTime: averageExecutionTime ?? this.averageExecutionTime,
      status: status ?? this.status,
    );
  }

  /// 更新统计信息
  ActionGroup updateExecution({
    required bool success,
    int? executionTime,
    DateTime? executedAt,
    List<ActionInstance>? updatedActions,
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
      status: success ? ActionGroupStatus.completed : ActionGroupStatus.failed,
      lastExecutedAt: now,
      executionCount: newCount,
      successCount: newSuccess,
      failureCount: newFailure,
      averageExecutionTime: newAvgTime,
      actions: updatedActions ?? actions,
      updatedAt: now,
    );
  }

  /// 标记为正在执行
  ActionGroup markAsRunning() {
    return copyWith(
      status: ActionGroupStatus.running,
      updatedAt: DateTime.now(),
    );
  }

  /// 标记为已取消
  ActionGroup markAsCancelled() {
    return copyWith(
      status: ActionGroupStatus.cancelled,
      updatedAt: DateTime.now(),
    );
  }

  /// 重置统计信息
  ActionGroup resetStats() {
    return copyWith(
      executionCount: 0,
      successCount: 0,
      failureCount: 0,
      averageExecutionTime: null,
      updatedAt: DateTime.now(),
    );
  }

  /// 添加动作
  ActionGroup addAction(ActionInstance action) {
    return copyWith(actions: [...actions, action]);
  }

  /// 移除动作
  ActionGroup removeAction(String actionId) {
    return copyWith(
      actions: actions.where((a) => a.actionId != actionId).toList(),
    );
  }

  /// 更新动作
  ActionGroup updateAction(String actionId, ActionInstance newAction) {
    return copyWith(
      actions: actions
          .map((a) => a.actionId == actionId ? newAction : a)
          .toList(),
    );
  }

  /// 清空动作
  ActionGroup clearActions() {
    return copyWith(actions: []);
  }

  /// 添加标签
  ActionGroup addTag(String tag) {
    if (!tags.contains(tag)) {
      return copyWith(tags: [...tags, tag]);
    }
    return this;
  }

  /// 移除标签
  ActionGroup removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toList());
  }

  /// 更新标题
  ActionGroup updateTitle(String title) {
    return copyWith(title: title, updatedAt: DateTime.now());
  }

  /// 更新描述
  ActionGroup updateDescription(String description) {
    return copyWith(description: description, updatedAt: DateTime.now());
  }

  /// 更新图标
  ActionGroup updateIcon(IconData icon) {
    return copyWith(icon: icon, updatedAt: DateTime.now());
  }

  /// 更新颜色
  ActionGroup updateColor(Color color) {
    return copyWith(color: color, updatedAt: DateTime.now());
  }

  /// 设置启用状态
  ActionGroup setEnabled(bool value) {
    return copyWith(
      enabled: value,
      updatedAt: DateTime.now(),
    );
  }

  /// 设置操作符
  ActionGroup setOperator(GroupOperator operator) {
    return copyWith(operator: operator, updatedAt: DateTime.now());
  }

  /// 设置优先级
  ActionGroup setPriority(int priority) {
    return copyWith(priority: priority, updatedAt: DateTime.now());
  }

  /// 检查是否包含指定标签
  bool hasTag(String tag) => tags.contains(tag);

  /// 检查是否包含任意标签
  bool hasAnyTag(List<String> tags) =>
      tags.any((t) => this.tags.contains(t));

  /// 检查是否包含所有标签
  bool hasAllTags(List<String> tags) =>
      tags.every((t) => this.tags.contains(t));

  /// 动作数量
  int get actionCount => actions.length;

  /// 启用的动作数量
  int get enabledActionCount => actions.where((a) => a.enabled).length;

  /// 禁用的动作数量
  int get disabledActionCount => actions.where((a) => !a.enabled).length;

  /// 获取操作符的显示名称
  String get operatorDisplayName {
    switch (operator) {
      case GroupOperator.sequence:
        return '顺序执行';
      case GroupOperator.parallel:
        return '并行执行';
      case GroupOperator.condition:
        return '条件执行';
    }
  }

  /// 获取执行模式的显示名称
  String get executionModeDisplayName {
    switch (executionMode) {
      case GroupExecutionMode.all:
        return '执行所有';
      case GroupExecutionMode.any:
        return '执行任一';
      case GroupExecutionMode.first:
        return '只执行第一个';
      case GroupExecutionMode.last:
        return '只执行最后一个';
      case GroupExecutionMode.custom:
        return '自定义执行';
    }
  }

  /// 获取状态的显示名称
  String get statusDisplayName {
    switch (status) {
      case ActionGroupStatus.idle:
        return '空闲';
      case ActionGroupStatus.running:
        return '正在执行';
      case ActionGroupStatus.completed:
        return '执行完成';
      case ActionGroupStatus.failed:
        return '执行失败';
      case ActionGroupStatus.cancelled:
        return '已取消';
    }
  }

  /// 获取状态的颜色
  Color get statusColor {
    switch (status) {
      case ActionGroupStatus.idle:
        return Colors.grey;
      case ActionGroupStatus.running:
        return Colors.blue;
      case ActionGroupStatus.completed:
        return Colors.green;
      case ActionGroupStatus.failed:
        return Colors.red;
      case ActionGroupStatus.cancelled:
        return Colors.orange;
    }
  }

  @override
  String toString() {
    return 'ActionGroup(id: $id, title: $title, operator: $operator, actionCount: $actionCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is ActionGroup) {
      return id == other.id || (id != null && other.id != null && id == other.id);
    }
    return false;
  }

  @override
  int get hashCode {
    return id?.hashCode ?? title.hashCode;
  }
}

/// 动作组模板
class ActionGroupTemplate {
  final String id;
  final String name;
  final String description;
  final IconData? icon;
  final GroupOperator operator;
  final List<String> actionIds;
  final Map<String, dynamic>? defaultData;

  const ActionGroupTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    required this.operator,
    required this.actionIds,
    this.defaultData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon?.codePoint,
      'iconFontFamily': icon?.fontFamily,
      'operator': operator.name,
      'actionIds': actionIds,
      'defaultData': defaultData,
    };
  }

  factory ActionGroupTemplate.fromJson(Map<String, dynamic> json) {
    return ActionGroupTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['iconCodePoint'] != null
          ? IconData(
              json['iconCodePoint'] as int,
              fontFamily: json['iconFontFamily'] as String?,
            )
          : null,
      operator: GroupOperator.values.firstWhere(
        (e) => e.name == json['operator'],
        orElse: () => GroupOperator.sequence,
      ),
      actionIds: (json['actionIds'] as List<dynamic>)
          .map((id) => id as String)
          .toList(),
      defaultData: json['defaultData'] as Map<String, dynamic>?,
    );
  }
}
