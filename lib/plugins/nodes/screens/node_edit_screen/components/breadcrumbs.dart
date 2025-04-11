import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/nodes_controller.dart';
import '../../../models/node.dart';
import '../../../l10n/nodes_localizations.dart';
import '../node_edit_screen.dart';

class NodeBreadcrumbs extends StatelessWidget {
  final String notebookId;
  final Node node;
  final bool isNew;
  final NodesController controller;

  const NodeBreadcrumbs({
    Key? key,
    required this.notebookId,
    required this.node,
    required this.isNew,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> path = [];
    List<String> nodeIds = [];
    
    if (isNew && node.parentId.isNotEmpty) {
      // 如果是新节点且有父节点，显示父节点的路径
      final parentNode = controller.findNodeById(notebookId, node.parentId);
      if (parentNode != null) {
        path = controller.getNodePath(notebookId, parentNode.id);
        nodeIds = controller.getNodePathIds(notebookId, parentNode.id);
        // 添加"新节点"作为路径的最后一个元素
        path.add(NodesLocalizations.of(context).addNode);
      }
    } else if (!isNew) {
      // 如果是编辑现有节点，显示节点自身的路径
      path = controller.getNodePath(notebookId, node.id);
      nodeIds = controller.getNodePathIds(notebookId, node.id);
    }
    
    if (path.isEmpty) {
      // 如果路径为空（例如新的根节点），则不显示任何内容
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 4,
      children: [
        for (int i = 0; i < path.length; i++)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                // 如果不是当前节点（最后一个元素），则导航到该节点
                if (i < path.length - 1 && i < nodeIds.length) {
                  // 导航到所选节点
                  final selectedNodeId = nodeIds[i];
                  final selectedNode = controller.findNodeById(notebookId, selectedNodeId);
                  
                  if (selectedNode != null) {
                    // 使用 Navigator.pop 返回上一级，然后打开新页面
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider<NodesController>.value(
                          value: controller,
                          child: NodeEditScreen(
                            notebookId: notebookId,
                            node: selectedNode,
                            isNew: false, // 确保不是新节点
                          ),
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(
                i == 0 ? path[i] : '/${path[i]}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}