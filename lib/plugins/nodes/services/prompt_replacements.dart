import 'package:flutter/material.dart';
import '../../../core/plugin_manager.dart';
import '../nodes_plugin.dart';
import '../models/node.dart';
import '../../../core/analysis/analysis_mode.dart';
import '../../../core/analysis/field_utils.dart';

/// Nodes插件的Prompt替换服务
///
/// 遵循 Memento Prompt 数据格式规范 v2.0
/// 详见: docs/PROMPT_DATA_SPEC.md
class NodesPromptReplacements {
  NodesPromptReplacements();

  void initialize() {
    debugPrint('NodesPromptReplacements initialized');
  }

  void dispose() {
    debugPrint('NodesPromptReplacements disposed');
  }

  /// 获取节点数据并格式化为文本
  ///
  /// 参数:
  /// - notebook_id: 笔记本ID (必需)
  /// - mode: 数据模式 (summary/compact/full, 默认summary)
  ///
  /// 返回格式:
  /// - summary: 仅统计数据 { sum: { total, notebooks, completed, topTags } }
  /// - compact: 简化记录 { sum: {...}, recs: [...] } (无notes)
  /// - full: 完整数据 (包含所有字段)
  Future<String> getNodePaths(Map<String, dynamic> params) async {
    try {
      // 1. 解析参数
      final mode = AnalysisModeUtils.parseFromParams(params);
      final String notebookId = params['notebook_id'] as String;

      // 2. 获取 NodesPlugin 实例
      final nodesPlugin = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
      if (nodesPlugin == null) {
        throw Exception('NodesPlugin not found');
      }

      // 3. 获取笔记本
      final notebook = nodesPlugin.controller.getNotebook(notebookId);
      if (notebook == null || notebook.id.isEmpty) {
        return FieldUtils.toJsonString({
          'error': '笔记本不存在',
          'notebookId': notebookId,
        });
      }

      // 4. 根据模式转换数据
      final result = _convertByMode(notebook.title, notebook.nodes, mode);

      // 5. 返回 JSON 字符串
      return FieldUtils.toJsonString(result);
    } catch (e) {
      debugPrint('Error in getNodePaths: $e');
      return FieldUtils.toJsonString({
        'error': '获取节点数据时出错',
        'details': e.toString(),
      });
    }
  }

  /// 根据模式转换数据
  Map<String, dynamic> _convertByMode(
    String notebookTitle,
    List<Node> nodes,
    AnalysisMode mode,
  ) {
    switch (mode) {
      case AnalysisMode.summary:
        return _buildSummary(notebookTitle, nodes);
      case AnalysisMode.compact:
        return _buildCompact(notebookTitle, nodes);
      case AnalysisMode.full:
        return _buildFull(notebookTitle, nodes);
    }
  }

  /// 构建摘要数据 (summary模式)
  ///
  /// 返回格式:
  /// {
  ///   "notebook": "工作计划",
  ///   "sum": {
  ///     "total": 50,
  ///     "completed": 20,
  ///     "topTags": [{"tag": "重要", "cnt": 15}]
  ///   }
  /// }
  Map<String, dynamic> _buildSummary(String notebookTitle, List<Node> nodes) {
    if (nodes.isEmpty) {
      return {
        'notebook': notebookTitle,
        ...FieldUtils.buildSummaryResponse({
          'total': 0,
          'completed': 0,
        }),
      };
    }

    // 递归统计所有节点
    final stats = _calculateNodeStats(nodes);

    // 统计标签
    final Map<String, int> tagCounts = {};
    _collectTags(nodes, tagCounts);

    // 生成标签排行（按次数降序）
    final topTags = tagCounts.entries.map((entry) {
      return {
        'tag': entry.key,
        'cnt': entry.value,
      };
    }).toList()
      ..sort((a, b) => (b['cnt'] as int).compareTo(a['cnt'] as int));

    // 只保留前5个标签
    final topTagsLimited = topTags.take(5).toList();

    return {
      'notebook': notebookTitle,
      ...FieldUtils.buildSummaryResponse({
        'total': stats['total'],
        'completed': stats['done'],
        if (topTagsLimited.isNotEmpty) 'topTags': topTagsLimited,
      }),
    };
  }

  /// 构建紧凑数据 (compact模式)
  ///
  /// 返回格式:
  /// {
  ///   "notebook": "工作计划",
  ///   "sum": { "total": 10, "completed": 5 },
  ///   "recs": [
  ///     {
  ///       "id": "uuid",
  ///       "title": "项目A",
  ///       "status": "doing",
  ///       "tags": ["重要"]
  ///     }
  ///   ]
  /// }
  Map<String, dynamic> _buildCompact(String notebookTitle, List<Node> nodes) {
    if (nodes.isEmpty) {
      return {
        'notebook': notebookTitle,
        ...FieldUtils.buildCompactResponse(
          {'total': 0, 'completed': 0},
          [],
        ),
      };
    }

    // 递归统计所有节点
    final stats = _calculateNodeStats(nodes);

    // 递归获取所有节点的简化信息（移除notes字段）
    final compactRecords = _getNodesInfoCompact(nodes);

    return {
      'notebook': notebookTitle,
      ...FieldUtils.buildCompactResponse(
        {
          'total': stats['total'],
          'completed': stats['done'],
        },
        compactRecords,
      ),
    };
  }

  /// 构建完整数据 (full模式)
  ///
  /// 返回格式: 包含所有字段的完整数据
  Map<String, dynamic> _buildFull(String notebookTitle, List<Node> nodes) {
    final fullRecords = _getNodesInfoFull(nodes);

    return {
      'notebook': notebookTitle,
      ...FieldUtils.buildFullResponse(fullRecords),
    };
  }

  /// 递归统计节点数量
  Map<String, int> _calculateNodeStats(List<Node> nodes) {
    int total = 0;
    int done = 0;

    void countNodes(List<Node> nodeList) {
      for (final node in nodeList) {
        total++;
        if (node.status == NodeStatus.done) {
          done++;
        }
        if (node.children.isNotEmpty) {
          countNodes(node.children);
        }
      }
    }

    countNodes(nodes);

    return {
      'total': total,
      'done': done,
    };
  }

  /// 递归收集所有标签
  void _collectTags(List<Node> nodes, Map<String, int> tagCounts) {
    for (final node in nodes) {
      for (final tag in node.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
      if (node.children.isNotEmpty) {
        _collectTags(node.children, tagCounts);
      }
    }
  }

  /// 递归获取节点的紧凑信息（移除notes字段）
  List<Map<String, dynamic>> _getNodesInfoCompact(List<Node> nodes) {
    return nodes.map((node) {
      final Map<String, dynamic> nodeInfo = {
        'id': node.id,
        'title': node.title,
        'status': node.status.toString().split('.').last,
      };

      // 只添加非空字段
      if (node.tags.isNotEmpty) {
        nodeInfo['tags'] = node.tags;
      }

      // 添加日期范围（如果存在）
      if (node.startDate != null || node.endDate != null) {
        final dateRange = <String, String>{};
        if (node.startDate != null) {
          dateRange['start'] = FieldUtils.formatDateTime(node.startDate!);
        }
        if (node.endDate != null) {
          dateRange['end'] = FieldUtils.formatDateTime(node.endDate!);
        }
        if (dateRange.isNotEmpty) {
          nodeInfo['dateRange'] = dateRange;
        }
      }

      // 添加自定义字段（如果有）
      if (node.customFields.isNotEmpty) {
        nodeInfo['customFields'] = node.customFields
            .map((field) => {
                  'key': field.key,
                  'value': field.value,
                })
            .toList();
      }

      // 添加子节点（如果有）
      if (node.children.isNotEmpty) {
        nodeInfo['children'] = _getNodesInfoCompact(node.children);
      }

      return nodeInfo;
    }).toList();
  }

  /// 递归获取节点的完整信息
  List<Map<String, dynamic>> _getNodesInfoFull(List<Node> nodes) {
    return nodes.map((node) {
      final Map<String, dynamic> nodeInfo = {
        'id': node.id,
        'title': node.title,
        'status': node.status.toString().split('.').last,
        'createdAt': FieldUtils.formatDateTime(node.createdAt),
      };

      // 添加标签
      if (node.tags.isNotEmpty) {
        nodeInfo['tags'] = node.tags;
      }

      // 添加日期范围
      if (node.startDate != null) {
        nodeInfo['startDate'] = FieldUtils.formatDateTime(node.startDate!);
      }
      if (node.endDate != null) {
        nodeInfo['endDate'] = FieldUtils.formatDateTime(node.endDate!);
      }

      // 添加笔记内容
      if (node.notes.isNotEmpty) {
        nodeInfo['notes'] = node.notes;
      }

      // 添加自定义字段
      if (node.customFields.isNotEmpty) {
        nodeInfo['customFields'] = node.customFields
            .map((field) => {
                  'key': field.key,
                  'value': field.value,
                })
            .toList();
      }

      // 添加颜色
      if (node.color != Colors.grey) {
        nodeInfo['color'] = node.color.toARGB32();
      }

      // 添加路径值
      if (node.pathValue.isNotEmpty) {
        nodeInfo['path'] = node.pathValue;
      }

      // 添加子节点
      if (node.children.isNotEmpty) {
        nodeInfo['children'] = _getNodesInfoFull(node.children);
      }

      return nodeInfo;
    }).toList();
  }
}
