import 'package:Memento/core/storage/storage_manager.dart';
import 'package:flutter/material.dart';
import 'goods_item.dart';
import 'path_constants.dart';

class Warehouse {
  final String id;
  final String title;
  final IconData icon;
  final Color iconColor;
  String? _imageUrl;

  // 获取图片URL，如果是相对路径则转换为绝对路径
  Future<String?> getImageUrl() async {
    if (_imageUrl == null) return null;
    final appDir = await StorageManager.getApplicationDocumentsDirectory();
    return GoodsPathConstants.toAbsolutePath(appDir.path, _imageUrl);
  }

  // 同步获取相对路径
  String? get imageUrl => _imageUrl;
  final List<GoodsItem> items;

  Warehouse({
    required this.id,
    required this.title,
    required this.icon,
    this.iconColor = Colors.blue,
    String? imageUrl,
    List<GoodsItem>? items,
  }) : items = items ?? [] {
    _imageUrl = GoodsPathConstants.toRelativePath(imageUrl);
  }

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
      imageUrl: json['imageUrl'] as String?, // 会在构造函数中转换为相对路径
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
      // ignore: deprecated_member_use
      'iconColor': iconColor.value,
      'imageUrl': _imageUrl, // 保存相对路径
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
      imageUrl: imageUrl ?? _imageUrl, // 使用已存储的相对路径
      items: items ?? List.from(this.items),
    );
  }
}
