/// 标签组数据模型
class TagGroup {
  final String name;
  final List<String> tags;
  final List<String>? tagIds;

  const TagGroup({
    required this.name, 
    required this.tags, 
    this.tagIds,
  });

  /// 从Map创建TagGroup实例
  factory TagGroup.fromMap(Map<String, dynamic> map) {
    return TagGroup(
      name: map['name'] as String,
      tags: List<String>.from(map['tags'] as List),
      tagIds: map['tagIds'] != null ? List<String>.from(map['tagIds'] as List) : null,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tags': tags,
      'tagIds': tagIds,
    };
  }

  /// 创建TagGroup副本
  TagGroup copyWith({
    String? name,
    List<String>? tags,
    List<String>? tagIds,
  }) {
    return TagGroup(
      name: name ?? this.name,
      tags: tags ?? List.from(this.tags),
      tagIds: tagIds ?? (this.tagIds != null ? List.from(this.tagIds!) : null),
    );
  }
}