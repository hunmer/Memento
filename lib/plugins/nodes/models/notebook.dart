import 'package:flutter/material.dart';
import 'node.dart';

class Notebook {
  String id;
  String title;
  IconData icon;
  Color color;
  List<Node> nodes;

  Notebook({
    required this.id,
    required this.title,
    this.icon = Icons.book,
    this.color = Colors.blue,
    this.nodes = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'icon': icon.codePoint,
    'color': color.value,
    'nodes': nodes.map((node) => node.toJson()).toList(),
  };

  factory Notebook.fromJson(Map<String, dynamic> json) => Notebook(
    id: json['id'] as String,
    title: json['title'] as String,
    icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
    color: Color(json['color'] as int? ?? Colors.blue.value),
    nodes: (json['nodes'] as List<dynamic>)
        .map((e) => Node.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}