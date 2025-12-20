import 'package:get/get.dart' hide Node;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:provider/provider.dart';
import 'package:Memento/widgets/super_cupertino_navigation_wrapper.dart';
import 'package:Memento/widgets/smooth_bottom_sheet.dart';
import 'package:Memento/plugins/nodes/controllers/nodes_controller.dart';
import 'package:Memento/plugins/nodes/models/notebook.dart';
import 'nodes_screen.dart';
import 'package:Memento/widgets/circle_icon_picker.dart';

class NotebooksScreen extends StatefulWidget {
  const NotebooksScreen({super.key});

  @override
  State<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends State<NotebooksScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<NodesController>(context);

    final theme = Theme.of(context);

    // 过滤笔记本列表
    final filteredNotebooks = _searchQuery.isEmpty
        ? controller.notebooks
        : controller.notebooks.where((notebook) {
            return notebook.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
          }).toList();

    return SuperCupertinoNavigationWrapper(
      title: Text(
        'nodes_notebooks'.tr,
        style: TextStyle(color: theme.textTheme.titleLarge?.color),
      ),
      largeTitle: 'nodes_notebooks'.tr,
      automaticallyImplyLeading: !(Platform.isAndroid || Platform.isIOS),
      enableSearchBar: true,
      searchPlaceholder: 'nodes_searchNotebooks'.tr,
      onSearchChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      searchBody: _buildSearchResults(context, filteredNotebooks, controller),
      actions: [
        IconButton(
          icon: Icon(Icons.add, color: theme.iconTheme.color),
          onPressed: () => _showAddNotebookDialog(context),
        ),
      ],
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
        itemCount: filteredNotebooks.length,
        itemBuilder: (context, index) {
          final notebook = filteredNotebooks[index];
          return Dismissible(
            key: Key(notebook.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              final bool? result = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('nodes_deleteNotebook'.tr),
                      content: Text(
                        'nodes_deleteNotebookConfirmation'.tr
                            .replaceAll('{notebook.title}', notebook.title),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('nodes_cancel'.tr),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('nodes_delete'.tr),
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
                  '${notebook.nodes.length} ${'nodes_nodes'.tr}',
                ),
                selected: notebook.id == controller.selectedNotebook?.id,
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showNotebookActions(context, notebook),
                ),
                onTap: () {
                  controller.selectNotebook(notebook);
                  NavigationHelper.push(
                    context,
                    ChangeNotifierProvider<NodesController>.value(
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

  Widget _buildSearchResults(
    BuildContext context,
    List<Notebook> notebooks,
    NodesController controller,
  ) {
    if (_searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    if (notebooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'nodes_noResultsFound'.tr,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notebooks.length,
      itemBuilder: (context, index) {
        final notebook = notebooks[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 4.0,
          ),
          child: ListTile(
            leading: Icon(notebook.icon, color: notebook.color),
            title: Text(
              notebook.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${notebook.nodes.length} ${'nodes_nodes'.tr}',
            ),
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
        );
      },
    );
  }

  void _showAddNotebookDialog(BuildContext context) {

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
              title: Text('nodes_addNotebook'.tr),
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
                    decoration: InputDecoration(labelText: 'nodes_notebookTitle'.tr),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('nodes_cancel'.tr),
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
                  child: Text('nodes_save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNotebookActions(BuildContext parentContext, Notebook notebook) {

    SmoothBottomSheet.show(
      context: parentContext,
      builder:
          (BuildContext context) => Wrap(
            children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text('nodes_editNotebook'.tr),
                  onTap: () {
                    Navigator.pop(context); // 关闭 BottomSheet
                    _showEditNotebookDialog(parentContext, notebook);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: Text('nodes_deleteNotebook'.tr),
                  onTap: () {
                    Navigator.pop(context); // 关闭 BottomSheet
                    _showDeleteNotebookDialog(parentContext, notebook);
                  },
                ),
            ],
          ),
    );
  }

  void _showEditNotebookDialog(BuildContext context, Notebook notebook) {

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
              title: Text('nodes_editNotebook'.tr),
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
                    decoration: InputDecoration(labelText: 'nodes_notebookTitle'.tr),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('nodes_cancel'.tr),
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
                  child: Text('nodes_save'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteNotebookDialog(BuildContext context, Notebook notebook) {

    final nodesController = Provider.of<NodesController>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('nodes_deleteNotebook'.tr),
            content: Text(
              'Are you sure you want to delete "${notebook.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('nodes_cancel'.tr),
              ),
              TextButton(
                onPressed: () {
                  nodesController.deleteNotebook(notebook.id);
                  Navigator.pop(context);
                },
                child: Text('nodes_deleteNode'.tr),
              ),
            ],
          ),
    );
  }
}
