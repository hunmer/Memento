import 'package:flutter/material.dart';

class Folder {
  final String id;
  String name;
  final String? parentId; // null for root folder
  final DateTime createdAt;
  DateTime updatedAt;
  Color color;
  IconData icon;

  Folder({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.color = Colors.blue,
    this.icon = Icons.folder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color.value,
      'icon': icon.codePoint,
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      color: Color(json['color'] as int? ?? Colors.blue.value),
      icon: IconData(json['icon'] as int? ?? Icons.folder.codePoint, fontFamily: 'MaterialIcons'),
    );
  }
}