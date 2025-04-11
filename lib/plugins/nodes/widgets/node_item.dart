import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../controllers/nodes_controller.dart';
import '../models/node.dart';
import '../screens/node_edit_screen.dart';
import '../l10n/nodes_localizations.dart';

class _StatusInfo {
  final Color color;
  final Color textColor;
  final String label;

  const _StatusInfo({
    required this.color,
    required this.textColor,
    required this.label,
  });
}

class NodeItem extends StatelessWidget {
  final Node node;
  final String notebookId;
  final int depth;

  const NodeItem({
    Key? key,
    required this.node,
    required this.notebookId,
    required this.depth,
  }) : super(key: key);
  
  Widget _buildStatusButton(
    BuildContext context,
    NodesController controller,
    NodeStatus status,
    String label,
    Color backgroundColor,
    Color textColor,
  ) {
    final isSelected = node.status == status;
    
    return InkWell(
      onTap: () {
        // 更新节点状态并保存
        final updatedNode = Node(
          id: node.id,
          title: node.title,
          createdAt: node.createdAt,
          tags: node.tags,
          status: status,
          startDate: node.startDate,
          endDate: node.endDate,
          customFields: node.customFields,
          notes: node.notes,
          parentId: node.parentId,
          pathValue: node.pathValue,
          color: node.color,
        );
        controller.updateNode(notebookId, updatedNode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: textColor, width: 2) 
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, NodeStatus status) {
    final Map<NodeStatus, _StatusInfo> statusInfo = {
      NodeStatus.todo: _StatusInfo(
        color: Colors.grey.shade200,
        textColor: Colors.grey.shade700,
        label: 'TODO',
      ),
      NodeStatus.doing: _StatusInfo(
        color: Colors.blue.shade100,
        textColor: Colors.blue.shade700,
        label: 'DOING',
      ),
      NodeStatus.done: _StatusInfo(
        color: Colors.green.shade100,
        textColor: Colors.green.shade700,
        label: 'DONE',
      ),
    };

    final info = statusInfo[status]!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: info.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          fontSize: 12,
          color: info.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NodesController>(context);
    final l10n = NodesLocalizations.of(context);

    // 使用节点自身的颜色
    Color nodeColor = node.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () => _showNodeActions(context, controller, l10n),
          child: InkWell(
            onTap: () {
              if (node.children.isNotEmpty) {
                // 如果有子节点，切换折叠状态
                controller.toggleNodeExpansion(notebookId, node.id);
              } else {
                // 如果没有子节点，直接进入编辑界面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider<NodesController>.value(
                      value: controller,
                      child: NodeEditScreen(
                        notebookId: notebookId,
                        node: node,
                      ),
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: EdgeInsets.only(left: depth * 24.0),
              child: Row(
                children: [
                  if (node.children.isNotEmpty)
                    Icon(
                      node.isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                    ),
                  if (node.children.isEmpty) const SizedBox(width: 20),
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: nodeColor,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  node.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(context, node.status),
                            ],
                          ),
                          if (node.tags.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              children: node.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (node.isExpanded && node.children.isNotEmpty)
          ...node.children.map((child) => NodeItem(
                node: child,
                notebookId: notebookId,
                depth: depth + 1,
              )),
      ],
    );
  }

  void _showNodeActions(
    BuildContext context,
    NodesController controller,
    NodesLocalizations l10n,
  ) {
    // 定义常用颜色列表
    final List<Color> commonColors = [
      Colors.grey,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.yellow,
      Colors.lime,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
    ];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Node Color',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: commonColors.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final color = commonColors[index];
                final isSelected = node.color.value == color.value;
                
                return GestureDetector(
                  onTap: () {
                    // 更新节点颜色并保存
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
                      parentId: node.parentId,
                      children: node.children,
                      isExpanded: node.isExpanded,
                      pathValue: node.pathValue,
                      color: color,
                    );
                    controller.updateNode(notebookId, updatedNode);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: Colors.black, width: 2) 
                          : null,
                    ),
                    child: isSelected 
                        ? const Icon(Icons.check, color: Colors.white, size: 20) 
                        : null,
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Node Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusButton(
                context, 
                controller, 
                NodeStatus.todo, 
                'TODO',
                Colors.grey.shade200,
                Colors.grey.shade700,
              ),
              _buildStatusButton(
                context, 
                controller, 
                NodeStatus.doing, 
                'DOING',
                Colors.blue.shade100,
                Colors.blue.shade700,
              ),
              _buildStatusButton(
                context, 
                controller, 
                NodeStatus.done, 
                'DONE',
                Colors.green.shade100,
                Colors.green.shade700,
              ),
            ],
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l10n.editNode),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider<NodesController>.value(
                    value: controller,
                    child: NodeEditScreen(
                      notebookId: notebookId,
                      node: node,
                    ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text(l10n.addChildNode),
            onTap: () {
              Navigator.pop(context);
              _addChildNode(context, controller);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.addSiblingNode),
            onTap: () {
              Navigator.pop(context);
              _addSiblingNode(context, controller);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(l10n.deleteNode),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, controller, l10n);
            },
          ),
        ],
      ),
    );
  }

  void _addChildNode(BuildContext context, NodesController controller) {
    final newNode = Node(
      id: const Uuid().v4(),
      title: '',
      createdAt: DateTime.now(),
      parentId: node.id,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<NodesController>.value(
          value: controller,
          child: NodeEditScreen(
            notebookId: notebookId,
            node: newNode,
            isNew: true,
          ),
        ),
      ),
    );
  }

  void _addSiblingNode(BuildContext context, NodesController controller) {
    final newNode = Node(
      id: const Uuid().v4(),
      title: '',
      createdAt: DateTime.now(),
      parentId: node.parentId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<NodesController>.value(
          value: controller,
          child: NodeEditScreen(
            notebookId: notebookId,
            node: newNode,
            isNew: true,
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    NodesController controller,
    NodesLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNode),
        content: Text('Are you sure you want to delete "${node.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              controller.deleteNode(notebookId, node.id);
              Navigator.pop(context);
            },
            child: Text(l10n.deleteNode),
          ),
        ],
      ),
    );
  }
}