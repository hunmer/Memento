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
    List<Node>? nodes,
  }) : nodes = nodes ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'icon': icon.codePoint,
    'color': color.value,
    'nodes': nodes.map((node) => node.toJson()).toList(),
  };

  factory Notebook.fromJson(Map<String, dynamic> json) {
    final nodesList =
        (json['nodes'] as List<dynamic>)
            .map((e) => Node.fromJson(e as Map<String, dynamic>))
            .toList();

    // 预定义常用Material图标常量
    const materialIcons = {
      0xe3a9: Icons.check, // check图标
      0xe5ca: Icons.arrow_back, // arrow_back图标
      0xe5cd: Icons.arrow_forward, // arrow_forward图标
      0xe7fd: Icons.person, // person图标
      0xe0be: Icons.home, // home图标
    };

    return Notebook(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: materialIcons[json['icon'] as int] ?? Icons.book,
      color: Color(json['color'] as int? ?? Colors.blue.value),
      nodes: nodesList,
    );
  }
}
