/// 节点笔记本插件 - 公共小组件数据提供者
library;

import 'package:Memento/core/plugin_manager.dart';
import 'package:Memento/plugins/nodes/models/node.dart' as node_models;
import 'package:Memento/plugins/nodes/models/notebook.dart';
import 'package:Memento/plugins/nodes/nodes_plugin.dart';

/// 提供公共小组件的数据
class NodesCommandWidgetsProvider {
  /// 获取公共小组件数据
  static Future<Map<String, Map<String, dynamic>>> provideCommonWidgets(
    Map<String, dynamic> data,
  ) async {
    final plugin = PluginManager.instance.getPlugin('nodes') as NodesPlugin?;
    if (plugin == null) return {};

    final controller = plugin.controller;
    final notebooks = controller.notebooks;

    return {
      // 笔记本列表卡片
      'notebookListCard': _buildNotebookListCardData(notebooks, controller),

      // 节点统计卡片
      'nodeStatsCard': _buildNodeStatsCardData(notebooks),

      // 待办节点列表
      'todoNodesList': _buildTodoNodesListData(notebooks),
    };
  }

  /// 构建笔记本列表卡片数据
  static Map<String, dynamic> _buildNotebookListCardData(
    List<Notebook> notebooks,
    dynamic controller,
  ) {
    // 获取所有笔记本和节点
    final items = <Map<String, dynamic>>[];

    for (var notebook in notebooks) {
      final flatNodes = _flattenNodesWithDepth(notebook.nodes);

      items.add({
        'id': notebook.id,
        'title': notebook.title,
        'icon': notebook.icon.codePoint,
        'color': notebook.color.value,
        'nodeCount': flatNodes.length,
        'nodes': flatNodes
            .map((item) {
              final node = item['node'] as node_models.Node;
              final depth = item['depth'] as int;
              return {
                'id': node.id,
                'title': node.title,
                'depth': depth,
                'color': node.color.value,
                'status': _nodeStatusToString(node.status),
              };
            })
            .toList(),
      });
    }

    return {
      'notebookCount': notebooks.length,
      'items': items,
    };
  }

  /// 构建节点统计卡片数据
  static Map<String, dynamic> _buildNodeStatsCardData(
    List<Notebook> notebooks,
  ) {
    int totalNodes = 0;
    int todoNodes = 0;
    int doingNodes = 0;
    int doneNodes = 0;

    for (var notebook in notebooks) {
      final stats = _countNodesByStatus(notebook.nodes);
      totalNodes += stats['total'] as int;
      todoNodes += stats['todo'] as int;
      doingNodes += stats['doing'] as int;
      doneNodes += stats['done'] as int;
    }

    return {
      'totalNodes': totalNodes,
      'todoNodes': todoNodes,
      'doingNodes': doingNodes,
      'doneNodes': doneNodes,
      'completedRate': totalNodes > 0 ? (doneNodes / totalNodes * 100) : 0,
    };
  }

  /// 构建待办节点列表数据
  static Map<String, dynamic> _buildTodoNodesListData(
    List<Notebook> notebooks,
  ) {
    final todoNodes = <Map<String, dynamic>>[];

    for (var notebook in notebooks) {
      void collectTodoNodes(
        List<node_models.Node> nodes,
        String notebookTitle,
        String parentPath,
      ) {
        for (var node in nodes) {
          if (node.status == node_models.NodeStatus.todo) {
            final nodePath =
                parentPath.isEmpty ? node.title : '$parentPath / ${node.title}';

            todoNodes.add({
              'id': '${notebook.id}:${node.id}',
              'notebookId': notebook.id,
              'notebookTitle': notebook.title,
              'nodeId': node.id,
              'title': node.title,
              'path': '$notebookTitle / $nodePath',
              'color': node.color.value,
            });
          }

          if (node.children.isNotEmpty) {
            collectTodoNodes(
              node.children,
              notebookTitle,
              parentPath.isEmpty ? node.title : '$parentPath / ${node.title}',
            );
          }
        }
      }

      collectTodoNodes(notebook.nodes, notebook.title, '');
    }

    return {
      'todoCount': todoNodes.length,
      'items': todoNodes.take(10).toList(),
      'moreCount': todoNodes.length > 10 ? todoNodes.length - 10 : 0,
    };
  }

  /// 扁平化节点树（带深度信息）
  static List<Map<String, dynamic>> _flattenNodesWithDepth(
    List<node_models.Node> nodeList,
  ) {
    final flatNodes = <Map<String, dynamic>>[];

    void flatten(List<node_models.Node> list, int depth) {
      for (var node in list) {
        flatNodes.add({'node': node, 'depth': depth});
        if (node.children.isNotEmpty) {
          flatten(node.children, depth + 1);
        }
      }
    }

    flatten(nodeList, 0);
    return flatNodes;
  }

  /// 按状态统计节点数量
  static Map<String, int> _countNodesByStatus(
    List<node_models.Node> nodes,
  ) {
    int total = 0;
    int todo = 0;
    int doing = 0;
    int done = 0;

    void count(List<node_models.Node> nodeList) {
      for (var node in nodeList) {
        total++;
        switch (node.status) {
          case node_models.NodeStatus.todo:
            todo++;
            break;
          case node_models.NodeStatus.doing:
            doing++;
            break;
          case node_models.NodeStatus.done:
            done++;
            break;
          case node_models.NodeStatus.none:
            break;
        }

        if (node.children.isNotEmpty) {
          count(node.children);
        }
      }
    }

    count(nodes);
    return {'total': total, 'todo': todo, 'doing': doing, 'done': done};
  }

  /// 将节点状态转换为字符串
  static String _nodeStatusToString(node_models.NodeStatus status) {
    switch (status) {
      case node_models.NodeStatus.todo:
        return 'todo';
      case node_models.NodeStatus.doing:
        return 'doing';
      case node_models.NodeStatus.done:
        return 'done';
      case node_models.NodeStatus.none:
        return 'none';
    }
  }
}
