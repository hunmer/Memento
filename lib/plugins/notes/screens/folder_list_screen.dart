import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Memento/core/navigation/navigation_helper.dart';
import 'package:Memento/plugins/notes/controllers/notes_controller.dart';
import 'package:Memento/plugins/notes/models/folder.dart';
import 'package:Memento/plugins/notes/models/note.dart';
import 'package:Memento/plugins/notes/widgets/folder_item.dart';
import 'package:Memento/plugins/notes/widgets/note_item.dart';
import 'note_edit_screen.dart';
import 'search_screen.dart';

class FolderListScreen extends StatefulWidget {
  final NotesController controller;

  const FolderListScreen({super.key, required this.controller});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  String currentFolderId = 'root';
  List<Folder> folders = [];
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentFolder();
  }

  void _loadCurrentFolder() {
    setState(() {
      folders = widget.controller.getFolderChildren(currentFolderId);
      notes = widget.controller.getFolderNotes(currentFolderId);
    });
  }

  void _navigateToFolder(Folder folder) {
    setState(() {
      currentFolderId = folder.id;
      _loadCurrentFolder();
    });
  }

  void _navigateBack() {
    final currentFolder = widget.controller.getFolder(currentFolderId);
    if (currentFolder?.parentId != null) {
      setState(() {
        currentFolderId = currentFolder!.parentId!;
        _loadCurrentFolder();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFolder = widget.controller.getFolder(currentFolderId);

    return Scaffold(
      appBar: AppBar(
        leading:
            currentFolder?.parentId != null
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                )
                : null,
        title: Text(currentFolder?.name ?? 'Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              NavigationHelper.push(context, SearchScreen(controller: widget.controller),
              );
            },
          ),
        ],
      ),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          // Implement reordering logic here
        },
        children: [
          ...folders.map(
            (folder) => FolderItem(
              key: ValueKey(folder.id),
              folder: folder,
              onTap: () => _navigateToFolder(folder),
            ),
          ),
          ...notes.map(
            (note) => NoteItem(
              key: ValueKey(note.id),
              note: note,
              onTap: () {
                NavigationHelper.push(context, NoteEditScreen(
                          note: note,
                          onSave: (title, content) {
                            final updatedNote = note.copyWith(
                              title: title,
                              content: content,
                        updatedAt: DateTime.now(),
                      );
                            widget.controller.updateNote(updatedNote);
                          },
                  ),
                ).then((_) => _loadCurrentFolder());
              }
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('notes_createNew'.tr),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.folder),
                        title: Text('notes_newFolder'.tr),
                        onTap: () {
                          Navigator.pop(context);
                          // Show folder creation dialog
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.note),
                        title: Text('notes_newNote'.tr),
                        onTap: () {
                          Navigator.pop(context);
                          NavigationHelper.push(context, NoteEditScreen(
                                    onSave: (title, content) {
                                      widget.controller.createNote(
                                        title,
                                        content,
                                        currentFolderId,
                                      );
                                    },),
                          ).then((_) => _loadCurrentFolder());
                        },
                      ),
                    ],
                  ),
                ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
