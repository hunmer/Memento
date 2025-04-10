import 'package:flutter/material.dart';

enum NodeStatus {
  todo,
  doing,
  done,
}

class CustomField {
  final String key;
  final String value;

  CustomField({required this.key, required this.value});

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
  };

  factory CustomField.fromJson(Map<String, dynamic> json) => CustomField(
    key: json['key'] as String,
    value: json['value'] as String,
  );
}

class Node {
  String id;
  String title;
  DateTime createdAt;
  List<String> tags;
  NodeStatus status;
  DateTime? startDate;
  DateTime? endDate;
  List<CustomField> customFields;
  String notes;
  String parentId;
  List<Node> children;
  bool isExpanded;

  Node({
    required this.id,
    required this.title,
    required this.createdAt,
    this.tags = const [],
    this.status = NodeStatus.todo,
    this.startDate,
    this.endDate,
    this.customFields = const [],
    this.notes = '',
    this.parentId = '',
    this.children = const [],
    this.isExpanded = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'tags': tags,
    'status': status.index,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'customFields': customFields.map((field) => field.toJson()).toList(),
    'notes': notes,
    'parentId': parentId,
    'children': children.map((child) => child.toJson()).toList(),
  };

  factory Node.fromJson(Map<String, dynamic> json) => Node(
    id: json['id'] as String,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    status: NodeStatus.values[json['status'] as int],
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    customFields: (json['customFields'] as List<dynamic>)
        .map((e) => CustomField.fromJson(e as Map<String, dynamic>))
        .toList(),
    notes: json['notes'] as String,
    parentId: json['parentId'] as String,
    children: (json['children'] as List<dynamic>)
        .map((e) => Node.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}