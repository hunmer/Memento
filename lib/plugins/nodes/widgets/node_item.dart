import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/widgets/quill_viewer/quill_viewer.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:Memento/plugins/nodes/controllers/nodes_controller.dart';
import 'package:Memento/plugins/nodes/models/node.dart';
import 'package:Memento/plugins/nodes/screens/node_edit_screen.dart';
import 'package:Memento/plugins/nodes/l10n/nodes_localizations.dart';

class _StatusInfo {
  final Color color;
  final Color textColor;
  final Color backgroundColor;
  final String label;

  const _StatusInfo({
    required this.color,
    required this.textColor,
    required this.backgroundColor,
    required this.label,
  });
}

class NodeItem extends StatelessWidget {
  final Node node;
  final String notebookId;
  final int depth;

  const NodeItem({
    super.key,
    required this.node,
    required this.notebookId,
    required this.depth,
  });

  _StatusInfo _getStatusInfo(BuildContext context, NodeStatus status) {
    // Colors based on design:
    // Todo -> Blue (New)
    // Doing -> Yellow (In Progress)
    // Done -> Green (Completed)
    // None/Other -> Grey

    switch (status) {
      case NodeStatus.todo:
        return _StatusInfo(
          color: Colors.blue.shade400,
          textColor: Colors.blue.shade800,
          backgroundColor: Colors.blue.shade100,
          label: 'New', // Mapping TODO to New/Blue style
        );
      case NodeStatus.doing:
        return _StatusInfo(
          color: Colors.amber.shade400,
          textColor: Colors.amber.shade800,
          backgroundColor: Colors.amber.shade100,
          label: 'In Progress',
        );
      case NodeStatus.done:
        return _StatusInfo(
          color: Colors.green.shade400,
          textColor: Colors.green.shade800,
          backgroundColor: Colors.green.shade100,
          label: 'Completed',
        );
      case NodeStatus.none:
        return _StatusInfo(
          color: Colors.grey.shade400,
          textColor: Colors.grey.shade800,
          backgroundColor: Colors.grey.shade200,
          label: 'None',
        );
    }
  }

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
          children: node.children,
          isExpanded: node.isExpanded,
        );
        controller.updateNode(notebookId, updatedNode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: textColor, width: 2) : null,
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
    final info = _getStatusInfo(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: info.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          fontSize: 11,
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
    final statusInfo = _getStatusInfo(context, node.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () => _showNodeActions(context, controller, l10n),
          child: InkWell(
            onTap: () {
              if (node.children.isNotEmpty) {
                controller.toggleNodeExpansion(notebookId, node.id);
              } else {
                NavigationHelper.push(context, ChangeNotifierProvider<NodesController>.value(
                              value: controller,
                              child: NodeEditScreen(
                                notebookId: notebookId,
                                node: node,),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Bar
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: statusInfo.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Title + Icon + Badge
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        node.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.grey.shade50 : Colors.grey.shade900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (node.children.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        node.isExpanded
                                            ? Icons.expand_more
                                            : Icons.chevron_right,
                                        size: 20,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (node.status != NodeStatus.none) ...[
                                const SizedBox(width: 8),
                                _buildStatusBadge(context, node.status),
                              ],
                            ],
                          ),
                          
                          // Tags
                          if (node.tags.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: node.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade200.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          // Notes (Description)
                          if (node.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              height: 36,
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRect(
                                child: QuillViewer(
                                  data: node.notes,
                                  selectable: false,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Recursion for children
        if (node.isExpanded && node.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 36.0), // Align with HTML's pl-9
            child: Column(
              children: node.children.map(
                (child) =>
                    NodeItem(node: child, notebookId: notebookId, depth: depth + 1),
              ).toList(),
            ),
          ),
      ],
    );
  }

  void _showNodeActions(
    BuildContext context,
    NodesController controller,
    NodesLocalizations l10n,
  ) {
    // 定义常用颜色列表 - keeping existing functionality though UI changed
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
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Node Color',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
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
                          border:
                              isSelected
                                  ? Border.all(color: Colors.black, width: 2)
                                  : null,
                        ),
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
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
                    'New', // Updated label
                    Colors.blue.shade100,
                    Colors.blue.shade800,
                  ),
                  _buildStatusButton(
                    context,
                    controller,
                    NodeStatus.doing,
                    'In Progress', // Updated label
                    Colors.amber.shade100,
                    Colors.amber.shade800,
                  ),
                  _buildStatusButton(
                    context,
                    controller,
                    NodeStatus.done,
                    'Completed', // Updated label
                    Colors.green.shade100,
                    Colors.green.shade800,
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n.editNode),
                onTap: () {
                  Navigator.pop(context);
                  NavigationHelper.push(context, ChangeNotifierProvider<NodesController>.value(
                                value: controller,
                                child: NodeEditScreen(
                                  notebookId: notebookId,
                                  node: node,),
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
      status: NodeStatus.todo, // Default new nodes to Todo (New)
    );

    NavigationHelper.push(context, ChangeNotifierProvider<NodesController>.value(
              value: controller,
              child: NodeEditScreen(
                notebookId: notebookId,
                node: newNode,
                isNew: true,),
      ),
    );
  }

  void _addSiblingNode(BuildContext context, NodesController controller) {
    final newNode = Node(
      id: const Uuid().v4(),
      title: '',
      createdAt: DateTime.now(),
      parentId: node.parentId,
      status: NodeStatus.todo,
    );

    NavigationHelper.push(context, ChangeNotifierProvider<NodesController>.value(
              value: controller,
              child: NodeEditScreen(
                notebookId: notebookId,
                node: newNode,
                isNew: true,),
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
      builder:
          (context) => AlertDialog(
            title: Text(l10n.deleteNode),
            content: Text(
              NodesLocalizations.of(
                context,
              ).deleteNodeConfirmation.replaceAll('{node.title}', node.title),
            ),
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
                child: Text(NodesLocalizations.of(context).delete),
              ),
            ],
          ),
    );
  }
}
