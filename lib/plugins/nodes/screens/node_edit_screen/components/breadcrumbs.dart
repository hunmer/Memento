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
    super.key,
    required this.notebookId,
    required this.node,
    required this.isNew,
    required this.controller,
  });

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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () async {
                    // 如果不是当前节点（最后一个元素），则导航到该节点
                    if (i < path.length - 1 && i < nodeIds.length) {
                      // 将当前编辑的节点设置为所选节点的子节点
                      final selectedNodeId = nodeIds[i];
                      final selectedNode = controller.findNodeById(notebookId, selectedNodeId);
                      final currentContext = context;
                      
                      if (selectedNode != null) {
                        try {
                          // 创建一个新的节点，保持原有的信息，但更新父节点ID
                          final updatedNode = Node(
                            id: node.id,
                            title: node.title,
                            createdAt: node.createdAt,
                            tags: node.tags,
                            status: node.status,
                            startDate: node.startDate,
                            endDate: node.endDate,
                            customFields: node.customFields,
                            notes: node.notes,
                            parentId: selectedNode.id, // 更新父节点ID
                            children: node.children,
                            pathValue: '${selectedNode.pathValue}/${node.title}',
                          );

                          // 更新节点树中的节点
                          await controller.updateNode(notebookId, updatedNode);

                          // 检查widget是否仍然挂载
                          if (!currentContext.mounted) return;

                          // 使用 Navigator.pop 返回上一级，然后用更新后的节点重新打开编辑页面
                          Navigator.pop(currentContext);
                          if (!currentContext.mounted) return;
                          
                          Navigator.of(currentContext).push(
                            MaterialPageRoute(
                              builder: (context) => ChangeNotifierProvider<NodesController>.value(
                                value: controller,
                                child: NodeEditScreen(
                                  notebookId: notebookId,
                                  node: updatedNode,
                                  isNew: isNew,
                                ),
                              ),
                            ),
                          );
                        } catch (e) {
                          debugPrint('Error updating node: $e');
                        }
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
              if (i < path.length - 1 && i < nodeIds.length) ...[
                const SizedBox(width: 4),
                _buildSiblingSelector(context, nodeIds[i], i),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildSiblingSelector(BuildContext context, String nodeId, int index) {
    // 获取同级节点列表
    final siblings = controller.getSiblingNodes(notebookId, nodeId);
    
    // 如果没有同级节点或只有一个节点（自身），则不显示选择器
    if (siblings.length <= 1) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (details) async {
          final RenderBox button = context.findRenderObject() as RenderBox;
          final Offset offset = button.localToGlobal(Offset.zero);
          
          final selectedNode = await showMenu<Node>(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx,
              offset.dy + button.size.height,
              details.globalPosition.dx + 200,
              offset.dy + button.size.height + 200,
            ),
            items: siblings
                .where((sibling) => sibling.id != nodeId) // 排除当前节点
                .map((sibling) => PopupMenuItem<Node>(
                      value: sibling,
                      child: Text(sibling.title),
                    ))
                .toList(),
          );

          if (selectedNode != null && context.mounted) {
            try {
              // 创建一个新的节点，保持原有的信息，但更新父节点ID
              final updatedNode = Node(
                id: node.id,
                title: node.title,
                createdAt: node.createdAt,
                tags: node.tags,
                status: node.status,
                startDate: node.startDate,
                endDate: node.endDate,
                customFields: node.customFields,
                notes: node.notes,
                parentId: selectedNode.id, // 更新父节点ID
                children: node.children,
                pathValue: '${selectedNode.pathValue}/${node.title}',
              );

              // 更新节点树中的节点
              await controller.updateNode(notebookId, updatedNode);

              // 返回上一级，然后用更新后的节点重新打开编辑页面
              if (!context.mounted) return;
              Navigator.pop(context);
              if (!context.mounted) return;
              
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider<NodesController>.value(
                    value: controller,
                    child: NodeEditScreen(
                      notebookId: notebookId,
                      node: updatedNode,
                      isNew: isNew,
                    ),
                  ),
                ),
              );
            } catch (e) {
              debugPrint('Error updating node: $e');
            }
          }
        },
        child: Icon(
          Icons.arrow_downward,
          size: 16,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}