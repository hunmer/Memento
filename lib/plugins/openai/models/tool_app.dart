import 'package:flutter/foundation.dart';

@immutable
class ToolApp {
  final String id;
  final String title;
  final String description;

  const ToolApp({
    required this.id,
    required this.title,
    required this.description,
  });

  factory ToolApp.fromJson(Map<String, dynamic> json) {
    return ToolApp(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolApp &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description;

  @override
  int get hashCode => Object.hash(id, title, description);
}