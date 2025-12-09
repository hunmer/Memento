import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CustomActivityEvent {
  final String id;
  final Color color;
  final String title;

  CustomActivityEvent({
    String? id,
    required this.color,
    required this.title,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'color': color.value,
      'title': title,
    };
  }

  factory CustomActivityEvent.fromJson(Map<String, dynamic> json) {
    return CustomActivityEvent(
      id: json['id'],
      color: Color(json['color']),
      title: json['title'],
    );
  }
}
