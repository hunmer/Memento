import 'package:uuid/uuid.dart';

/// 分析预设数据模型
///
/// 用于保存常用的插件分析配置，包括标题、描述、标签、智能体和提示词等信息
class AnalysisPreset {
  /// 唯一标识符
  final String id;

  /// 预设标题
  String title;

  /// 预设描述/注释
  String description;

  /// 标签列表
  List<String> tags;

  /// 关联的智能体ID（可选）
  String? agentId;

  /// 提示词内容
  String prompt;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  DateTime updatedAt;

  AnalysisPreset({
    String? id,
    required this.title,
    this.description = '',
    List<String>? tags,
    this.agentId,
    this.prompt = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从JSON创建预设对象
  factory AnalysisPreset.fromJson(Map<String, dynamic> json) {
    return AnalysisPreset(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      agentId: json['agentId'] as String?,
      prompt: json['prompt'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tags': tags,
      'agentId': agentId,
      'prompt': prompt,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 创建副本（支持部分字段更新）
  AnalysisPreset copyWith({
    String? title,
    String? description,
    List<String>? tags,
    String? agentId,
    String? prompt,
    DateTime? updatedAt,
  }) {
    return AnalysisPreset(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      agentId: agentId ?? this.agentId,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AnalysisPreset(id: $id, title: $title, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnalysisPreset && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
