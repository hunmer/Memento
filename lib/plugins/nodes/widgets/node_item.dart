import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/nodes_controller.dart';
import '../models/node.dart';
import '../screens/node_edit_screen.dart';
import '../l10n/nodes_localizations.dart';
import 'package:uuid/uuid.dart';

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

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NodesController>(context);
    final l10n = NodesLocalizations.of(context);

    Color? statusColor;
    switch (node.status) {
      case NodeStatus.todo:
        statusColor = Colors.grey;
        break;
      case NodeStatus.doing:
        statusColor = Colors.blue;
        break;
      case NodeStatus.done:
        statusColor = Colors.green;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () => _showNodeActions(context, controller, l10n),
          child: InkWell(
            onTap: node.children.isNotEmpty
                ? () => controller.toggleNodeExpansion(notebookId, node.id)
                : null,
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
                      color: statusColor,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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