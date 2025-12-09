import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

const _uuid = Uuid();

/// 会话分组模型
class ConversationGroup {
  /// 分组ID
  final String id;

  /// 分组名称
  String name;

  /// 分组图标（可选）
  String? icon;

  /// 分组颜色（可选）
  String? color;

  /// 排序顺序
  int order;

  /// 创建时间
  final DateTime createdAt;

  ConversationGroup({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.order = 0,
    required this.createdAt,
  });

  /// 创建新分组
  factory ConversationGroup.create({
    required String name,
    String? icon,
    String? color,
    int order = 0,
  }) {
    return ConversationGroup(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: color,
      order: order,
      createdAt: DateTime.now(),
    );
  }

  /// 从JSON反序列化
  factory ConversationGroup.fromJson(Map<String, dynamic> json) {
    return ConversationGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 复制分组（用于修改）
  ConversationGroup copyWith({
    String? name,
    String? icon,
    String? color,
    int? order,
  }) {
    return ConversationGroup(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }

  /// 比较函数（用于排序）
  static int compare(ConversationGroup a, ConversationGroup b) {
    return a.order.compareTo(b.order);
  }
}
