import 'package:flutter/material.dart';
import 'package:Memento/plugins/goods/models/custom_field.dart' as goods_custom_field;

enum NodeStatus { todo, doing, done, none }

/// 节点自定义字段类型（使用 goods 插件的 CustomField）
typedef NodeCustomField = goods_custom_field.CustomField;

class Node {
  String id;
  String title;
  DateTime createdAt;
  List<String> tags;
  NodeStatus status;
  DateTime? startDate;
  DateTime? endDate;
  List<NodeCustomField> customFields;
  String notes;
  String parentId;
  List<Node> children;
  bool isExpanded;
  String pathValue;
  Color color;

  Node({
    required this.id,
    required this.title,
    required this.createdAt,
    List<String>? tags,
    this.status = NodeStatus.todo,
    this.startDate,
    this.endDate,
    List<NodeCustomField>? customFields,
    this.notes = '',
    this.parentId = '',
    List<Node>? children,
    this.isExpanded = true,
    this.pathValue = '',
    this.color = Colors.grey,
  })  : tags = tags ?? [],
        customFields = customFields ?? [],
        children = children ?? [];

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
        'pathValue': pathValue,
        'color': color.value,
      };

  factory Node.fromJson(Map<String, dynamic> json) {
    final tagsList =
        (json['tags'] as List<dynamic>).map((e) => e as String).toList();
    final customFieldsList =
        (json['customFields'] as List<dynamic>)
            .map((e) => NodeCustomField.fromJson(e as Map<String, dynamic>))
            .toList();
    final childrenList =
        (json['children'] as List<dynamic>)
            .map((e) => Node.fromJson(e as Map<String, dynamic>))
            .toList();

    return Node(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      tags: tagsList,
      status: NodeStatus.values[json['status'] as int],
      startDate:
          json['startDate'] != null
              ? DateTime.parse(json['startDate'] as String)
              : null,
      endDate:
          json['endDate'] != null
              ? DateTime.parse(json['endDate'] as String)
              : null,
      customFields: customFieldsList,
      notes: json['notes'] as String,
      parentId: json['parentId'] as String,
      children: childrenList,
      pathValue: json['pathValue'] as String? ?? '',
      color: Color(json['color'] as int? ?? Colors.grey.value),
    );
  }
}
