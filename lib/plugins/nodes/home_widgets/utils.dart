/// 节点笔记本插件主页小组件工具函数
library;

import '../models/node.dart' as node_models;

/// 递归计算所有节点总数
int countAllNodes(List<node_models.Node> nodes) {
  int count = nodes.length;
  for (var node in nodes) {
    count += countAllNodes(node.children);
  }
  return count;
}

/// 递归计算待办节点数量
int countTodoNodes(List<node_models.Node> nodes) {
  int count = 0;
  for (var node in nodes) {
    // NodeStatus.todo 的值是 0
    if (node.status.index == 0) {
      count++;
    }
    count += countTodoNodes(node.children);
  }
  return count;
}

/// 扁平化节点树（显示所有节点包括子节点，带深度信息）
List<Map<String, dynamic>> flattenNodesWithDepth(List<node_models.Node> nodeList) {
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
