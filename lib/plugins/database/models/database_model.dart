import 'package:flutter/material.dart';

/// 数据库模型
class DatabaseModel {
  final String id;
  String name;
  String? description;
  String? coverImagePath;
  DateTime createdAt;
  DateTime updatedAt;

  DatabaseModel({
    required this.id,
    required this.name,
    this.description,
    this.coverImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从Map创建DatabaseModel
  factory DatabaseModel.fromMap(Map<String, dynamic> map) {
    return DatabaseModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      coverImagePath: map['coverImagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverImagePath': coverImagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DatabaseModel copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DatabaseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 表字段模型
class TableField {
  final String id;
  String name;
  FieldType type;
  bool isRequired;
  dynamic defaultValue;

  TableField({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = false,
    this.defaultValue,
  });

  factory TableField.fromMap(Map<String, dynamic> map) {
    return TableField(
      id: map['id'],
      name: map['name'],
      type: FieldType.values[map['type']],
      isRequired: map['isRequired'] ?? false,
      defaultValue: map['defaultValue'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'isRequired': isRequired,
      'defaultValue': defaultValue,
    };
  }
}

/// 字段类型枚举
enum FieldType { text, number, boolean, date, image, color }
