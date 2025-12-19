import 'package:flutter/material.dart';

/// 消息标签模型
/// 用于表示从消息中提取的标签及其统计信息
class MessageTag {
  /// 标签名称（不含 # 前缀）
  final String name;

  /// 关联的消息数量
  final int messageCount;

  /// 最后使用时间（最新消息的时间）
  final DateTime lastUsed;

  /// 标签颜色（可选，用于未来扩展）
  Color? color;

  /// 标签分类（可选，用于未来扩展）
  String? category;

  MessageTag({
    required this.name,
    required this.messageCount,
    required this.lastUsed,
    this.color,
    this.category,
  });

  /// 创建副本，可选择性地更新某些字段
  MessageTag copyWith({
    String? name,
    int? messageCount,
    DateTime? lastUsed,
    Color? color,
    String? category,
  }) {
    return MessageTag(
      name: name ?? this.name,
      messageCount: messageCount ?? this.messageCount,
      lastUsed: lastUsed ?? this.lastUsed,
      color: color ?? this.color,
      category: category ?? this.category,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageTag && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return 'MessageTag(name: $name, messageCount: $messageCount, lastUsed: $lastUsed)';
  }
}
