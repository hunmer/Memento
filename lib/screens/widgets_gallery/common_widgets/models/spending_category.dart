import 'package:flutter/material.dart';

/// 消费分类数据模型
class SpendingCategory {
  /// 分类名称
  final String name;

  /// 消费金额
  final double amount;

  /// 分类颜色
  final Color color;

  const SpendingCategory({
    required this.name,
    required this.amount,
    required this.color,
  });

  /// 从 Map 创建实例
  factory SpendingCategory.fromMap(Map<String, dynamic> map) {
    return SpendingCategory(
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      color: Color(map['color'] as int? ?? 0xFF8E8E93),
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'color': color.value,
    };
  }

  /// 创建副本
  SpendingCategory copyWith({
    String? name,
    double? amount,
    Color? color,
  }) {
    return SpendingCategory(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      color: color ?? this.color,
    );
  }
}
