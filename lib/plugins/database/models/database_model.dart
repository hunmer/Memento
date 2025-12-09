import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './database_field.dart';

/// 数据库模型
@immutable
class DatabaseModel {
  final String id;
  final String name;
  final String? description;
  final String? coverImage;
  final List<DatabaseField> fields;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DatabaseModel({
    required this.id,
    required this.name,
    this.description,
    this.coverImage,
    this.fields = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从Map创建DatabaseModel
  factory DatabaseModel.fromMap(Map<String, dynamic> map) {
    return DatabaseModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      coverImage: map['coverImage'],
      fields:
          (map['fields'] as List).map((e) => DatabaseField.fromMap(e)).toList(),
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
      'coverImage': coverImage,
      'fields': fields.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DatabaseModel copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImage,
    List<DatabaseField>? fields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DatabaseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      fields: fields ?? this.fields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
