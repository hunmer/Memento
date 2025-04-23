class TagGroup {
  final String name;
  final List<String> tags;

  TagGroup({
    required this.name,
    required this.tags,
  });

  // 从 JSON 创建 TagGroup
  factory TagGroup.fromJson(Map<String, dynamic> json) {
    return TagGroup(
      name: json['name'] as String,
      tags: List<String>.from(json['tags'] as List),
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tags': tags,
    };
  }

  // 创建新的 TagGroup 实例，更新标签列表
  TagGroup copyWith({
    String? name,
    List<String>? tags,
  }) {
    return TagGroup(
      name: name ?? this.name,
      tags: tags ?? List<String>.from(this.tags),
    );
  }
}