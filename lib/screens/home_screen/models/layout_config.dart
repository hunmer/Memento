/// 布局配置数据模型
///
/// 用于保存和管理多个主页布局配置
class LayoutConfig {
  /// 配置ID
  final String id;

  /// 配置名称
  final String name;

  /// 布局项目数据
  final List<Map<String, dynamic>> items;

  /// 网格列数
  final int gridCrossAxisCount;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime updatedAt;

  /// 是否是默认布局
  final bool isDefault;

  const LayoutConfig({
    required this.id,
    required this.name,
    required this.items,
    required this.gridCrossAxisCount,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  /// 从 JSON 反序列化
  factory LayoutConfig.fromJson(Map<String, dynamic> json) {
    return LayoutConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List).cast<Map<String, dynamic>>(),
      gridCrossAxisCount: json['gridCrossAxisCount'] as int? ?? 4,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items,
      'gridCrossAxisCount': gridCrossAxisCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  /// 复制并修改部分属性
  LayoutConfig copyWith({
    String? id,
    String? name,
    List<Map<String, dynamic>>? items,
    int? gridCrossAxisCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
  }) {
    return LayoutConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      gridCrossAxisCount: gridCrossAxisCount ?? this.gridCrossAxisCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
