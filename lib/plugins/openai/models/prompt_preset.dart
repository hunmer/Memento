/// Prompt 预设模型
/// 用于管理可复用的系统提示词模板
class PromptPreset {
  final String id;
  final String name;
  final String description;
  final String content;
  final List<String> tags;
  final String? category;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PromptPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.content,
    required this.tags,
    this.category,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'content': content,
    'tags': tags,
    'category': category,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PromptPreset.fromJson(Map<String, dynamic> json) => PromptPreset(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    content: json['content'] as String,
    tags: (json['tags'] as List?)?.cast<String>() ?? [],
    category: json['category'] as String?,
    isDefault: json['isDefault'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  PromptPreset copyWith({
    String? id,
    String? name,
    String? description,
    String? content,
    List<String>? tags,
    String? category,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromptPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
