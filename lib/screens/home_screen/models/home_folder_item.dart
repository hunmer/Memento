import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_item.dart';

/// 主页文件夹
///
/// 可以包含多个小组件或其他文件夹（嵌套）
class HomeFolderItem extends HomeItem {
  /// 文件夹名称
  final String name;

  /// 图标
  final IconData icon;

  /// 颜色
  final Color color;

  /// 文件夹内的项目列表
  final List<HomeItem> children;

  HomeFolderItem({
    required super.id,
    required this.name,
    required this.icon,
    required this.color,
    this.children = const [],
  }) : super(type: HomeItemType.folder);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'icon': icon.codePoint,
    'iconFontFamily': icon.fontFamily,
    'color': color.value,
    'children': children.map((c) => c.toJson()).toList(),
  };

  /// 从 JSON 加载
  factory HomeFolderItem.fromJson(Map<String, dynamic> json) {
    return HomeFolderItem(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(
        json['icon'] as int,
        fontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
      ),
      color: Color(json['color'] as int),
      children: (json['children'] as List?)
          ?.map((c) => HomeItem.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// 创建副本，允许修改部分字段
  HomeFolderItem copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    List<HomeItem>? children,
  }) {
    return HomeFolderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      children: children ?? this.children,
    );
  }

  /// 获取文件夹内项目数量（递归计算）
  int get itemCount {
    int count = children.length;
    for (var child in children) {
      if (child is HomeFolderItem) {
        count += child.itemCount;
      }
    }
    return count;
  }
}
