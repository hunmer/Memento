import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/nodes_controller.dart';
import '../models/notebook.dart';
import '../l10n/nodes_localizations.dart';
import 'nodes_screen.dart';
import '../../../widgets/circle_icon_picker.dart';

class NotebooksScreen extends StatelessWidget {
  static const List<IconData> _availableIcons = [
    Icons.book,
    Icons.work,
    Icons.school,
    Icons.home,
    Icons.favorite,
    Icons.star,
  ];

  const NotebooksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NodesController>(context);
    final l10n = NodesLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notebooks),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddNotebookDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: controller.notebooks.length,
        itemBuilder: (context, index) {
          final notebook = controller.notebooks[index];
          return ListTile(
            leading: Icon(notebook.icon, color: notebook.color),
            title: Text(notebook.title),
            subtitle: Text('${notebook.nodes.length} ${l10n.nodes}'),
            selected: notebook.id == controller.selectedNotebook?.id,
            onTap: () {
              controller.selectNotebook(notebook);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider<NodesController>.value(
                    value: controller,
                    child: NodesScreen(notebook: notebook),
                  ),
                ),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteNotebookDialog(context, notebook),
            ),
            onLongPress: () => _showNotebookActions(context, notebook),
          );
        },
      ),
    );
  }

  void _showAddNotebookDialog(BuildContext context) {
    final l10n = NodesLocalizations.of(context);
    final controller = Provider.of<NodesController>(context, listen: false);
    final titleController = TextEditingController();
    IconData selectedIcon = Icons.book;
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.addNotebook),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleIconPicker(
                    currentIcon: selectedIcon,
                    backgroundColor: selectedColor,
                    onIconSelected: (icon) {
                      setState(() {
                        selectedIcon = icon;
                      });
                    },
                    onColorSelected: (color) {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.notebookTitle,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      controller.addNotebook(titleController.text, selectedIcon, color: selectedColor);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showNotebookActions(BuildContext parentContext, Notebook notebook) {
    final l10n = NodesLocalizations.of(parentContext);
    final controller = Provider.of<NodesController>(parentContext, listen: false);

    showModalBottomSheet(
      context: parentContext,
      builder: (BuildContext context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.editNotebook),
              onTap: () {
                Navigator.pop(context);  // 关闭 BottomSheet
                _showEditNotebookDialog(parentContext, notebook);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(l10n.deleteNotebook),
              onTap: () {
                Navigator.pop(context);  // 关闭 BottomSheet
                _showDeleteNotebookDialog(parentContext, notebook);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNotebookDialog(BuildContext context, Notebook notebook) {
    final l10n = NodesLocalizations.of(context);
    final controller = Provider.of<NodesController>(context, listen: false);
    final titleController = TextEditingController(text: notebook.title);
    IconData selectedIcon = notebook.icon;
    Color selectedColor = notebook.color ?? Colors.blue;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.editNotebook),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleIconPicker(
                    currentIcon: selectedIcon,
                    backgroundColor: selectedColor,
                    onIconSelected: (icon) {
                      setState(() {
                        selectedIcon = icon;
                      });
                    },
                    onColorSelected: (color) {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.notebookTitle,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final updatedNotebook = Notebook(
                        id: notebook.id,
                        title: titleController.text,
                        icon: selectedIcon,
                        color: selectedColor,
                        nodes: notebook.nodes,
                      );
                      controller.updateNotebook(updatedNotebook);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showDeleteNotebookDialog(BuildContext context, Notebook notebook) {
    final l10n = NodesLocalizations.of(context);
    final controller = Provider.of<NodesController>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNotebook),
        content: Text('Are you sure you want to delete "${notebook.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              controller.deleteNotebook(notebook.id);
              Navigator.pop(context);
            },
            child: Text(l10n.deleteNode),
          ),
        ],
      ),
    );
  }
}