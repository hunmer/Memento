/// 脚本文件夹配置
///
/// 表示一个可以包含脚本的文件夹
class ScriptFolder {
  /// 文件夹唯一标识
  final String id;

  /// 文件夹显示名称
  final String name;

  /// 文件夹路径
  final String path;

  /// 是否为内置文件夹（不可删除）
  final bool isBuiltIn;

  /// 是否启用
  final bool enabled;

  /// 文件夹图标
  final String icon;

  /// 文件夹描述
  final String? description;

  const ScriptFolder({
    required this.id,
    required this.name,
    required this.path,
    this.isBuiltIn = false,
    this.enabled = true,
    this.icon = 'folder',
    this.description,
  });

  /// 从 JSON 创建
  factory ScriptFolder.fromJson(Map<String, dynamic> json) {
    return ScriptFolder(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
      icon: json['icon'] as String? ?? 'folder',
      description: json['description'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'isBuiltIn': isBuiltIn,
      'enabled': enabled,
      'icon': icon,
      if (description != null) 'description': description,
    };
  }

  /// 复制并修改部分属性
  ScriptFolder copyWith({
    String? id,
    String? name,
    String? path,
    bool? isBuiltIn,
    bool? enabled,
    String? icon,
    String? description,
  }) {
    return ScriptFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      enabled: enabled ?? this.enabled,
      icon: icon ?? this.icon,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'ScriptFolder(id: $id, name: $name, path: $path, enabled: $enabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScriptFolder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
