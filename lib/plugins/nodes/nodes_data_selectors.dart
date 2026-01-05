part of 'nodes_plugin.dart';

// ========== 数据选择器 ==========

void _registerDataSelectors() {
  // 注册节点选择器
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'nodes.node',
      pluginId: NodesPlugin.instance.id,
      name: '选择节点',
      icon: NodesPlugin.instance.icon,
      color: NodesPlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'node',
          title: '选择节点',
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            // 获取所有笔记本的所有节点(扁平列表)
            final List<SelectableItem> items = [];

            for (var notebook in NodesPlugin.instance.controller.notebooks) {
              // 递归获取所有节点
              void addNodesRecursively(
                List<Node> nodes,
                String notebookTitle,
                String parentPath,
              ) {
                for (var node in nodes) {
                  // 构建节点路径
                  final nodePath =
                      parentPath.isEmpty
                          ? node.title
                          : '$parentPath / ${node.title}';

                  items.add(
                    SelectableItem(
                      id: '${notebook.id}:${node.id}',
                      title: node.title,
                      subtitle: '$notebookTitle · $nodePath',
                      icon: Icons.subdirectory_arrow_right,
                      rawData: {
                        'notebookId': notebook.id,
                        'notebookTitle': notebook.title,
                        'nodeId': node.id,
                        'node': node,
                      },
                    ),
                  );

                  // 递归添加子节点
                  if (node.children.isNotEmpty) {
                    addNodesRecursively(
                      node.children,
                      notebookTitle,
                      nodePath,
                    );
                  }
                }
              }

              addNodesRecursively(notebook.nodes, notebook.title, '');
            }

            return items;
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items
                .where(
                  (item) =>
                      item.title.toLowerCase().contains(lowerQuery) ||
                      (item.subtitle?.toLowerCase().contains(lowerQuery) ??
                          false),
                )
                .toList();
          },
        ),
      ],
    ),
  );

  // 注册笔记本选择器(用于节点列表小组件)
  pluginDataSelectorService.registerSelector(
    SelectorDefinition(
      id: 'nodes.notebook',
      pluginId: NodesPlugin.instance.id,
      name: 'nodes_selectNotebook'.tr,
      icon: Icons.book,
      color: NodesPlugin.instance.color,
      searchable: true,
      selectionMode: SelectionMode.single,
      steps: [
        SelectorStep(
          id: 'notebook',
          title: 'nodes_selectNotebook'.tr,
          viewType: SelectorViewType.list,
          isFinalStep: true,
          dataLoader: (_) async {
            return NodesPlugin.instance.controller.notebooks.map((notebook) {
              // 计算节点数量
              final nodeCount = _countAllNodes(notebook.nodes);

              return SelectableItem(
                id: notebook.id,
                title: notebook.title,
                subtitle: 'nodes_nodeCount'.trParams({'count': '$nodeCount'}),
                icon: notebook.icon,
                rawData: {
                  'id': notebook.id,
                  'title': notebook.title,
                  'icon': notebook.icon.codePoint,
                  'color': notebook.color.value,
                  'nodeCount': nodeCount,
                },
              );
            }).toList();
          },
          searchFilter: (items, query) {
            if (query.isEmpty) return items;
            final lowerQuery = query.toLowerCase();
            return items
                .where(
                  (item) =>
                      item.title.toLowerCase().contains(lowerQuery) ||
                      (item.subtitle?.toLowerCase().contains(lowerQuery) ??
                          false),
                )
                .toList();
          },
        ),
      ],
    ),
  );
}

// 计算所有笔记本中的节点总数
int _countAllNodes(List<Node> nodes) {
  int count = nodes.length;
  for (var node in nodes) {
    count += _countAllNodes(node.children);
  }
  return count;
}

// 计算所有待办节点数量
int _countTodoNodes(List<Node> nodes) {
  int count = 0;
  for (var node in nodes) {
    if (node.status == NodeStatus.todo) {
      count++;
    }
    count += _countTodoNodes(node.children);
  }
  return count;
}
