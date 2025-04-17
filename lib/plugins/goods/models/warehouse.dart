import 'package:flutter/material.dart';
import 'goods_item.dart';

class Warehouse {
  final String id;
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? imageUrl;
  final List<GoodsItem> items;

  Warehouse({
    required this.id,
    required this.title,
    required this.icon,
    this.iconColor = Colors.blue,
    this.imageUrl,
    List<GoodsItem>? items,
  }) : items = items ?? [];

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as String,
      title: json['title'] as String,
      icon:
          json['iconData'] != null
              ? IconData(json['iconData'] as int, fontFamily: 'MaterialIcons')
              : Icons.inventory_2,
      iconColor:
          json['iconColor'] != null
              ? Color(json['iconColor'] as int)
              : Colors.blue,
      items:
          (json['items'] as List?)
              ?.map((item) => GoodsItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'iconData': icon.codePoint,
      'iconColor': iconColor.value,
      'imageUrl': imageUrl,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Warehouse copyWith({
    String? title,
    IconData? icon,
    Color? iconColor,
    String? imageUrl,
    List<GoodsItem>? items,
  }) {
    return Warehouse(
      id: id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      imageUrl: imageUrl ?? this.imageUrl,
      items: items ?? List.from(this.items),
    );
  }
}
