import 'package:flutter/material.dart';

/// 分类项数据模型（用于 categoryItems）
class CategoryItem {
  /// 项目标题
  final String title;

  /// 项目副标题
  final String subtitle;

  const CategoryItem({
    required this.title,
    required this.subtitle,
  });

  /// 从 Map 创建实例
  factory CategoryItem.fromMap(Map<String, dynamic> map) {
    return CategoryItem(
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
    };
  }
}

/// 分类项目组（包含分类名称和项目列表）
class CategoryItemGroup {
  /// 分类名称
  final String categoryName;

  /// 项目列表
  final List<CategoryItem> items;

  const CategoryItemGroup({
    required this.categoryName,
    required this.items,
  });

  /// 从 Map 创建实例
  factory CategoryItemGroup.fromMap(Map<String, dynamic> map) {
    return CategoryItemGroup(
      categoryName: map['categoryName'] as String? ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => CategoryItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }
}

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
