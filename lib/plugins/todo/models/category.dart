import 'package:flutter/material.dart';

class Category {
  final String id;
  String name;
  String color; // 颜色编码，如 '#FF0000'
  String icon;  // 图标标识

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        color: json['color'],
        icon: json['icon'],
      );

  Color get colorValue => _hexToColor(color);

  IconData get iconData => _getIconData(icon);

  static Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static IconData _getIconData(String iconName) {
    // 这里可以根据字符串返回对应的图标
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'personal':
        return Icons.person;
      case 'shopping':
        return Icons.shopping_cart;
      case 'health':
        return Icons.favorite;
      case 'education':
        return Icons.school;
      default:
        return Icons.label;
    }
  }
}