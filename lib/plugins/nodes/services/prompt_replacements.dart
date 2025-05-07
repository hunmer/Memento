import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/plugin_manager.dart';
import '../nodes_plugin.dart';
import '../models/node.dart';

class NodesPromptReplacements {
  NodesPromptReplacements();

  void initialize() {
    debugPrint('NodesPromptReplacements initialized');
  }

  void dispose() {
    debugPrint('NodesPromptReplacements disposed');
  }

  /// 获取指定笔记本的节点路径
  Future<String> getNodePaths(Map<String, dynamic> params) async {
    try {
      final String notebookId = params['notebook_id'] as String;

      // 获取 NodesPlugin 实例
      final nodesPlugin = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
      if (nodesPlugin == null) {
        throw Exception('NodesPlugin not found');
      }

      // 获取笔记本
      final notebook = nodesPlugin.controller.getNotebook(notebookId);
      if (notebook == null || notebook.id.isEmpty) {
        return jsonEncode({
          'notebook_title': '',
          'nodes': [],
        });
      }

      // 递归获取所有节点信息
      final nodes = _getNodesInfo(notebook.nodes);

      final result = {
        'notebook_title': notebook.title,
        'nodes': nodes,
      };

      return jsonEncode(result);
    } catch (e) {
      debugPrint('Error in getNodePaths: $e');
      return jsonEncode({
        'error': e.toString(),
        'notebook_title': '',
        'nodes': [],
      });
    }
  }

  /// 格式化日期为 y/m/d h:m 格式
  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}';
  }

  /// 移除Map中的空字段
  Map<String, dynamic> _removeEmptyFields(Map<String, dynamic> map) {
    return Map.fromEntries(
      map.entries.where((entry) {
        if (entry.value == null) return false;
        if (entry.value is String && entry.value.toString().isEmpty) return false;
        if (entry.value is List && (entry.value as List).isEmpty) return false;
        if (entry.value is Map && (entry.value as Map).isEmpty) return false;
        return true;
      }),
    );
  }

  List<Map<String, dynamic>> _getNodesInfo(List<Node> nodes) {
    return nodes.map((node) {
      // 构建基本信息
      final Map<String, dynamic> nodeInfo = {
        'title': node.title,
        'status': node.status.toString().split('.').last,
        'tags': node.tags,
        'date_range': _removeEmptyFields({
          'start': _formatDate(node.startDate),
          'end': _formatDate(node.endDate),
        }),
        'notes': node.notes,
      };

      // 添加自定义字段（如果有）
      if (node.customFields.isNotEmpty) {
        nodeInfo['custom_fields'] = node.customFields
            .map((field) => _removeEmptyFields({
                  'key': field.key,
                  'value': field.value,
                }))
            .where((field) => field.isNotEmpty)
            .toList();
      }

      // 添加子节点（如果有）
      final children = _getNodesInfo(node.children);
      if (children.isNotEmpty) {
        nodeInfo['children'] = children;
      }

      // 移除所有空字段
      return _removeEmptyFields(nodeInfo);
    }).toList();
  }
}