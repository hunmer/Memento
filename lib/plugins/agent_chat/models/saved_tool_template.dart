import 'package:uuid/uuid.dart';
import 'tool_call_step.dart';

const _uuid = Uuid();

/// 保存的工具模板
///
/// 用于保存工具调用步骤,以便后续快速执行
class SavedToolTemplate {
  /// 模板ID
  final String id;

  /// 模板名称
  final String name;

  /// 模板描述
  final String? description;

  /// 工具调用步骤列表
  final List<ToolCallStep> steps;

  /// 创建时间
  final DateTime createdAt;

  /// 最后使用时间
  DateTime? lastUsedAt;

  /// 使用次数
  int usageCount;

  SavedToolTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.steps,
    required this.createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
  });

  /// 创建新模板
  factory SavedToolTemplate.create({
    required String name,
    String? description,
    required List<ToolCallStep> steps,
  }) {
    return SavedToolTemplate(
      id: _uuid.v4(),
      name: name,
      description: description,
      steps: steps,
      createdAt: DateTime.now(),
      usageCount: 0,
    );
  }

  /// 从JSON反序列化
  factory SavedToolTemplate.fromJson(Map<String, dynamic> json) {
    return SavedToolTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => ToolCallStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      usageCount: json['usageCount'] as int? ?? 0,
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'steps': steps.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt!.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  /// 复制并修改
  SavedToolTemplate copyWith({
    String? name,
    String? description,
    List<ToolCallStep>? steps,
    DateTime? lastUsedAt,
    int? usageCount,
  }) {
    return SavedToolTemplate(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  /// 标记为已使用
  SavedToolTemplate markAsUsed() {
    return copyWith(
      lastUsedAt: DateTime.now(),
      usageCount: usageCount + 1,
    );
  }
}
