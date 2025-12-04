import 'dart:io' show Platform;
import 'package:Memento/core/plugin_manager.dart';
import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'dart:ui' show lerpDouble;
import 'package:provider/provider.dart';
import '../controllers/nodes_controller.dart';
import '../models/notebook.dart';
import '../l10n/nodes_localizations.dart';
import 'nodes_screen.dart';
import '../../../widgets/circle_icon_picker.dart';

class NotebooksScreen extends StatelessWidget {
  const NotebooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NodesController>(context);
    final l10n = NodesLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading:
            (Platform.isAndroid || Platform.isIOS)
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => PluginManager.toHomeScreen(context),
                ),
        title: Text(l10n.notebooks),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddNotebookDialog(context),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue = Curves.easeInOut.transform(
                animation.value,
              );
              final double elevation = lerpDouble(0, 6, animValue)!;
              return Material(
                elevation: elevation,
                color: Colors.transparent,
                shadowColor: Colors.transparent,
                child: child,
              );
            },
            child: child,
          );
        },
        itemCount: controller.notebooks.length,
        itemBuilder: (context, index) {
          final notebook = controller.notebooks[index];
          return Dismissible(
            key: Key(notebook.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              final bool? result = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text(l10n.deleteNotebook),
                      content: Text(
                        NodesLocalizations.of(context)
                            .deleteNotebookConfirmation
                            .replaceAll('{notebook.title}', notebook.title),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(NodesLocalizations.of(context).delete),
                        ),
                      ],
                    ),
              );
              if (result == true) {
                Provider.of<NodesController>(
                  context,
                  listen: false,
                ).deleteNotebook(notebook.id);
              }
              return false;
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Card(
              key: Key(notebook.id),
              margin: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: ListTile(
                leading: ReorderableDragStartListener(
                  index: index,
                  child: Icon(notebook.icon, color: notebook.color),
                ),
                title: Text(notebook.title),
                subtitle: Text(
                  '${notebook.nodes.length} ${NodesLocalizations.of(context).nodes}',
                ),
                selected: notebook.id == controller.selectedNotebook?.id,
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showNotebookActions(context, notebook),
                ),
                onTap: () {
                  controller.selectNotebook(notebook);
                  NavigationHelper.push(context, ChangeNotifierProvider<NodesController>.value(
                                value: controller,
                                child: NodesScreen(notebook: notebook),
                    ),
                  );
                },
              ),
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          controller.reorderNotebooks(oldIndex, newIndex);
        },
      ),
    );
  }

  void _showAddNotebookDialog(BuildContext context) {
    final l10n = NodesLocalizations.of(context);
    final nodesController = Provider.of<NodesController>(
      context,
      listen: false,
    );
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
                    decoration: InputDecoration(labelText: l10n.notebookTitle),
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
                      nodesController.addNotebook(
                        titleController.text,
                        selectedIcon,
                        color: selectedColor,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNotebookActions(BuildContext parentContext, Notebook notebook) {
    final l10n = NodesLocalizations.of(parentContext);

    showModalBottomSheet(
      context: parentContext,
      builder:
          (BuildContext context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(l10n.editNotebook),
                  onTap: () {
                    Navigator.pop(context); // 关闭 BottomSheet
                    _showEditNotebookDialog(parentContext, notebook);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: Text(l10n.deleteNotebook),
                  onTap: () {
                    Navigator.pop(context); // 关闭 BottomSheet
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
    final nodesController = Provider.of<NodesController>(
      context,
      listen: false,
    );
    final titleController = TextEditingController(text: notebook.title);
    IconData selectedIcon = notebook.icon;
    Color selectedColor = notebook.color;

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
                    decoration: InputDecoration(labelText: l10n.notebookTitle),
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
                      nodesController.updateNotebook(updatedNotebook);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteNotebookDialog(BuildContext context, Notebook notebook) {
    final l10n = NodesLocalizations.of(context);
    final nodesController = Provider.of<NodesController>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.deleteNotebook),
            content: Text(
              'Are you sure you want to delete "${notebook.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  nodesController.deleteNotebook(notebook.id);
                  Navigator.pop(context);
                },
                child: Text(l10n.deleteNode),
              ),
            ],
          ),
    );
  }
}
