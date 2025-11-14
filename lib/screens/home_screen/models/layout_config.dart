import 'package:flutter/material.dart';

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

  /// 背景图路径
  final String? backgroundImagePath;

  /// 背景图填充方式
  final BoxFit backgroundFit;

  /// 背景图模糊程度 (0-10)
  final double backgroundBlur;

  const LayoutConfig({
    required this.id,
    required this.name,
    required this.items,
    required this.gridCrossAxisCount,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.backgroundImagePath,
    this.backgroundFit = BoxFit.cover,
    this.backgroundBlur = 0.0,
  });

  /// 从 JSON 反序列化
  factory LayoutConfig.fromJson(Map<String, dynamic> json) {
    // 深拷贝 items 列表，确保嵌套的 config 字段被保留
    final itemsList = (json['items'] as List)
        .map((item) {
          if (item is Map) {
            return _deepCopyMap(item);
          }
          return item as Map<String, dynamic>;
        })
        .toList();

    return LayoutConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      items: itemsList,
      gridCrossAxisCount: json['gridCrossAxisCount'] as int? ?? 4,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
      backgroundImagePath: json['backgroundImagePath'] as String?,
      backgroundFit: boxFitFromString(json['backgroundFit'] as String?),
      backgroundBlur: (json['backgroundBlur'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 深拷贝 Map，确保嵌套结构被正确保留
  static Map<String, dynamic> _deepCopyMap(Map map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = _deepCopyMap(value);
      } else if (value is List) {
        result[key.toString()] = value.map((item) {
          if (item is Map) {
            return _deepCopyMap(item);
          }
          return item;
        }).toList();
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  /// 将字符串转换为 BoxFit
  static BoxFit boxFitFromString(String? value) {
    switch (value) {
      case 'fill':
        return BoxFit.fill;
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaleDown':
        return BoxFit.scaleDown;
      default:
        return BoxFit.cover;
    }
  }

  /// 将 BoxFit 转换为字符串
  static String boxFitToString(BoxFit fit) {
    switch (fit) {
      case BoxFit.fill:
        return 'fill';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fitWidth:
        return 'fitWidth';
      case BoxFit.fitHeight:
        return 'fitHeight';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scaleDown';
    }
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
      'backgroundImagePath': backgroundImagePath,
      'backgroundFit': boxFitToString(backgroundFit),
      'backgroundBlur': backgroundBlur,
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
    String? backgroundImagePath,
    bool clearBackgroundImage = false,
    BoxFit? backgroundFit,
    double? backgroundBlur,
  }) {
    return LayoutConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      gridCrossAxisCount: gridCrossAxisCount ?? this.gridCrossAxisCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
      backgroundImagePath: clearBackgroundImage ? null : (backgroundImagePath ?? this.backgroundImagePath),
      backgroundFit: backgroundFit ?? this.backgroundFit,
      backgroundBlur: backgroundBlur ?? this.backgroundBlur,
    );
  }
}
