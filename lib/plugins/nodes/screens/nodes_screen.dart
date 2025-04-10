import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/nodes_controller.dart';
import '../models/notebook.dart';
import '../models/node.dart';
import '../l10n/nodes_localizations.dart';
import '../widgets/node_item.dart';
import 'node_edit_screen.dart';
import 'package:uuid/uuid.dart';

class NodesScreen extends StatelessWidget {
  final Notebook notebook;

  const NodesScreen({Key? key, required this.notebook}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NodesController>(context);
    final l10n = NodesLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(notebook.title),
      ),
      body: notebook.nodes.isEmpty
          ? Center(
              child: Text('No nodes yet. Tap + to add one.'),
            )
          : ListView.builder(
              itemCount: notebook.nodes.length,
              itemBuilder: (context, index) {
                return NodeItem(
                  node: notebook.nodes[index],
                  notebookId: notebook.id,
                  depth: 0,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _addRootNode(context),
      ),
    );
  }

  void _addRootNode(BuildContext context) {
    final controller = Provider.of<NodesController>(context, listen: false);
    final newNode = Node(
      id: const Uuid().v4(),
      title: '',
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<NodesController>.value(
          value: controller,
          child: NodeEditScreen(
            notebookId: notebook.id,
            node: newNode,
            isNew: true,
          ),
        ),
      ),
    );
  }
}