import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import '../controllers/nodes_controller.dart';
import '../models/notebook.dart';
import '../models/node.dart';
import '../l10n/nodes_localizations.dart';
import '../widgets/node_item.dart';
import 'node_edit_screen.dart';
import 'package:uuid/uuid.dart';

class NodesScreen extends StatelessWidget {
  final Notebook notebook;

  const NodesScreen({super.key, required this.notebook});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NodesController>(context, listen: true);
    final l10n = NodesLocalizations.of(context);
    final currentNotebook = controller.getNotebook(notebook.id);
    final theme = Theme.of(context);

    return SuperCupertinoNavigationWrapper(
      title: Text(
        notebook.title,
        style: TextStyle(color: theme.textTheme.titleLarge?.color),
      ),
      largeTitle: '节点',
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
          onSelected:
              (value) => _handleMenuAction(
                value,
                context,
                controller,
                currentNotebook,
              ),
          itemBuilder:
              (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'copy',
                  child: ListTile(
                    leading: const Icon(Icons.copy),
                    title: Text(l10n.copyToText),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'clear',
                  child: ListTile(
                    leading: const Icon(Icons.clear_all),
                    title: Text(l10n.clearNodes),
                  ),
                ),
              ],
        ),
      ],
      body: Stack(
        children: [
          currentNotebook?.nodes.isEmpty ?? true
              ? Center(child: Text(l10n.noNodesYet))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentNotebook?.nodes.length ?? 0,
                itemBuilder: (context, index) {
                  return NodeItem(
                    node: currentNotebook!.nodes[index],
                    notebookId: notebook.id,
                    depth: 0,
                  );
                },
              ),
          // FAB 覆盖层
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => _addRootNode(context),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(
    String value,
    BuildContext context,
    NodesController controller,
    Notebook? currentNotebook,
  ) {
    if (currentNotebook == null) return;

    switch (value) {
      case 'copy':
        _copyToText(context, currentNotebook);
        break;
      case 'clear':
        _showClearConfirmDialog(context, controller, currentNotebook);
        break;
    }
  }

  void _copyToText(BuildContext context, Notebook notebook) {
    final buffer = StringBuffer();

    void processNode(Node node, int depth) {
      buffer.writeln('${'  ' * depth}${node.title}');
      if (node.notes.isNotEmpty) {
        buffer.writeln('${'  ' * (depth + 1)}${node.notes}');
      }
      for (var child in node.children) {
        processNode(child, depth + 1);
      }
    }

    for (var node in notebook.nodes) {
      processNode(node, 0);
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(NodesLocalizations.of(context).copiedToClipboard),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showClearConfirmDialog(
    BuildContext context,
    NodesController controller,
    Notebook notebook,
  ) {
    final l10n = NodesLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.clearNodesTitle),
            content: Text(l10n.clearNodesConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  controller.clearNodes(notebook.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.nodesCleared),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Text(l10n.clear),
              ),
            ],
          ),
    );
  }

  void _addRootNode(BuildContext context) {
    final controller = Provider.of<NodesController>(context, listen: false);
    final newNode = Node(
      id: const Uuid().v4(),
      title: '',
      status: NodeStatus.todo,
      createdAt: DateTime.now(),
    );

    NavigationHelper.push(context, ChangeNotifierProvider<NodesController>.value(
              value: controller,
              child: NodeEditScreen(
                notebookId: notebook.id,
                node: newNode,
                isNew: true,),
      ),
    );
  }
}
