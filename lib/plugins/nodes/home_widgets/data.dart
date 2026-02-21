/// 节点笔记本插件主页小组件数据模型
library;

import 'package:flutter/material.dart';

/// 节点列表项数据
class NodeListItemData {
  final String id;
  final String title;
  final int depth;
  final Color color;
  final String? statusText;

  const NodeListItemData({
    required this.id,
    required this.title,
    required this.depth,
    required this.color,
    this.statusText,
  });
}

/// 笔记本统计数据
class NotebookStatsData {
  final int notebookCount;
  final int totalNodes;
  final int todoNodes;

  const NotebookStatsData({
    required this.notebookCount,
    required this.totalNodes,
    required this.todoNodes,
  });
}
